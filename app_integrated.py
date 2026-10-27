import json
from PIL import Image, ImageFilter

from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, HttpUrl, Field, model_validator
from pathlib import Path
import os
from io import BytesIO
from PIL import Image
from diffusers import StableDiffusionInpaintPipeline

from ultralytics import YOLO

# Keep the original backend untouched. Import SAM2 while inside its repository
# directory to avoid the repository-name shadowing guard on some setups.
PROJECT_DIR = Path(__file__).resolve().parent
BASE_DIR = PROJECT_DIR / "backend"
_original_import_cwd = Path.cwd()
try:
    os.chdir(BASE_DIR / "sam2")
    from sam2.build_sam import build_sam2
    from sam2.sam2_image_predictor import SAM2ImagePredictor
finally:
    os.chdir(_original_import_cwd)

import base64
import cv2
import numpy as np
import requests
from dotenv import load_dotenv
import torch


load_dotenv(dotenv_path=BASE_DIR / ".env")
API_KEY = os.getenv("SERPAPI_KEY")


app = FastAPI(title="NestCraft Object Detection API")

# Keep this permissive for local development. Restrict origins before deployment.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

YOLO_MODEL_PATH = str(BASE_DIR / "yolo26n-seg.pt")
SAM_CHECKPOINT = BASE_DIR / "checkpoints" / "sam2.1_hiera_base_plus.pt"
SAM_CONFIG = "configs/sam2.1/sam2.1_hiera_b+.yaml"

yolo = None
sam_predictor = None
inpaint_pipe = None

# Prototype stores one analyzed image in memory at a time.
active_project_id = None
active_image = None


class AnalyzeRequest(BaseModel):
    projectId: str
    imageUrl: HttpUrl

class ProductRequest(BaseModel):
    object_type: str
    color: str = ""
    budget: int = 50000



class SelectRequest(BaseModel):
    projectId: str

    # Optional rectangle selection
    x1: float | None = Field(default=None, ge=0)
    y1: float | None = Field(default=None, ge=0)
    x2: float | None = Field(default=None, ge=0)
    y2: float | None = Field(default=None, ge=0)

    # Legacy single-positive-point selection
    x: float | None = Field(default=None, ge=0)
    y: float | None = Field(default=None, ge=0)

    # New multiple-point selection:
    # label 1 = object; label 0 = background
    pointCoords: list[list[float]] | None = None
    pointLabels: list[int] | None = None

    @model_validator(mode="after")
    def validate_selection(self):
        box_values = (self.x1, self.y1, self.x2, self.y2)

        if all(v is not None for v in box_values):
            if self.x2 <= self.x1 or self.y2 <= self.y1:
                raise ValueError("Box must have positive width and height.")

        elif any(v is not None for v in box_values):
            raise ValueError(
                "Send all four box coordinates: x1, y1, x2, y2."
            )

        elif self.pointCoords is not None or self.pointLabels is not None:
            if not self.pointCoords or not self.pointLabels:
                raise ValueError(
                    "Send both pointCoords and pointLabels."
                )

            if len(self.pointCoords) != len(self.pointLabels):
                raise ValueError(
                    "Each point must have one corresponding label."
                )

            if any(len(point) != 2 for point in self.pointCoords):
                raise ValueError(
                    "Each point must contain x and y coordinates."
                )

            if any(label not in (0, 1) for label in self.pointLabels):
                raise ValueError("Point labels must be 0 or 1.")

        elif self.x is None or self.y is None:
            raise ValueError(
                "Send box coordinates or point coordinates."
            )

        return self


@app.on_event("startup")
def load_models():
    global yolo, sam_predictor, inpaint_pipe

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print("Loading models on:", device, flush=True)

    # Load YOLO from the existing backend folder.
    yolo = YOLO(YOLO_MODEL_PATH)
    print("YOLO loaded successfully.", flush=True)

    # SAM2's repository has a guard against starting from its parent folder.
    # Temporarily use the SAM2 repository directory only while building the model.
    previous_cwd = Path.cwd()
    try:
        os.chdir(BASE_DIR / "sam2")
        sam_model = build_sam2(
            SAM_CONFIG,
            str(SAM_CHECKPOINT),
            device=device,
        )
    finally:
        os.chdir(previous_cwd)
    sam_predictor = SAM2ImagePredictor(sam_model)
    print("SAM2 loaded successfully.", flush=True)

    # Load Stable Diffusion Inpainting. This can use substantial RAM on CPU.
    print("Loading Stable Diffusion Inpainting...", flush=True)
    inpaint_pipe = StableDiffusionInpaintPipeline.from_pretrained(
        "stable-diffusion-v1-5/stable-diffusion-inpainting",
        torch_dtype=torch.float32,
        safety_checker=None,
    )
    inpaint_pipe.to(device)
    inpaint_pipe.enable_attention_slicing()
    print("Stable Diffusion Inpainting loaded successfully.", flush=True)
    print("All NestCraft models loaded successfully.", flush=True)


@app.get("/")
def home():
    return {"message": "NestCraft Python API is running"}


def encode_png(image_array: np.ndarray) -> str:
    """Encode a NumPy image array as a Base64 PNG string."""
    success, buffer = cv2.imencode(".png", image_array)
    if not success:
        raise ValueError("Could not encode image as PNG.")
    return base64.b64encode(buffer.tobytes()).decode("utf-8")


@app.post("/analyze")
def analyze_image(request: AnalyzeRequest):
    global active_project_id, active_image

    try:
        response = requests.get(str(request.imageUrl), timeout=60)
        response.raise_for_status()

        image = Image.open(BytesIO(response.content)).convert("RGB")
        image_array = np.array(image)
        image_height, image_width = image_array.shape[:2]

        # Set the source image for SAM2. Box prompts are applied in original-image pixels.
        sam_predictor.set_image(image_array)

        results = yolo.predict(
    image_array,
    imgsz=1280,
    conf=0.25,
    iou=0.60,
    retina_masks=True,
    verbose=False
)
        objects = []

        for result in results:
            if result.boxes is None:
                continue

            for index, box in enumerate(result.boxes):
                class_id = int(box.cls[0].item())
                confidence = float(box.conf[0].item())
                x1, y1, x2, y2 = [float(v) for v in box.xyxy[0].tolist()]

                x1i = max(0, min(image_width, int(np.floor(x1))))
                y1i = max(0, min(image_height, int(np.floor(y1))))
                x2i = max(0, min(image_width, int(np.ceil(x2))))
                y2i = max(0, min(image_height, int(np.ceil(y2))))

                if x2i <= x1i or y2i <= y1i:
                    continue

                object_image_base64 = None
                mask_image_base64 = None
                polygon_points = []

                if result.masks is not None and index < len(result.masks.data):
                    mask = result.masks.data[index].cpu().numpy()

                    if mask.shape != (image_height, image_width):
                        mask = cv2.resize(
                            mask.astype(np.float32),
                            (image_width, image_height),
                            interpolation=cv2.INTER_NEAREST,
                        )

                    binary_mask = mask > 0.5

                    rgba_image = np.zeros(
                        (image_height, image_width, 4), dtype=np.uint8
                    )
                    rgba_image[:, :, :3] = image_array
                    rgba_image[:, :, 3] = binary_mask.astype(np.uint8) * 255

                   
                    object_crop = rgba_image[y1i:y2i, x1i:x2i].copy()

                    # Save the mask at the original room-image dimensions.
                    mask_full = binary_mask.astype(np.uint8) * 255

                    object_image_base64 = encode_png(object_crop)
                    mask_image_base64 = encode_png(mask_full)

                    if index < len(result.masks.xy):
                        polygon = np.asarray(
                            result.masks.xy[index], dtype=np.float32
                        )
                        if len(polygon) >= 3:
                            contour = polygon.reshape(-1, 1, 2)
                            simplified = cv2.approxPolyDP(contour, 1.0, True)
                            polygon_points = [
                                [
                                    round(float(point[0][0]), 2),
                                    round(float(point[0][1]), 2),
                                ]
                                for point in simplified
                            ]

                objects.append(
                    {
                        "index": len(objects),
                        "type": result.names[class_id],
                        "confidence": round(confidence, 4),
                        "x": round(x1, 2),
                        "y": round(y1, 2),
                        "width": round(x2 - x1, 2),
                        "height": round(y2 - y1, 2),
                        "segmentation": polygon_points,
                        "objectImageBase64": object_image_base64,
                        "maskImageBase64": mask_image_base64,
                    }
                )

        active_project_id = request.projectId
        active_image = image_array

        return {
            "message": "YOLO image analysis completed",
            "projectId": request.projectId,
            "width": image_width,
            "height": image_height,
            "objectCount": len(objects),
            "objects": objects,
        }

    except requests.RequestException as error:
        raise HTTPException(
            status_code=400,
            detail=f"Could not download room image: {error}",
        )
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"Image analysis failed: {error}",
        )


@app.post("/select")
def select_object(request: SelectRequest):
    if active_image is None or active_project_id != request.projectId:
        raise HTTPException(
            status_code=409,
            detail="Analyze this project image before selecting an object.",
        )

    height, width = active_image.shape[:2]

    try:
        # Box-selection mode: SAM2 is prompted with the rectangle drawn by the user.
        if request.x1 is not None:
            x1 = int(round(request.x1))
            y1 = int(round(request.y1))
            x2 = int(round(request.x2))
            y2 = int(round(request.y2))

            if x1 < 0 or y1 < 0 or x2 > width or y2 > height:
                raise HTTPException(
                    status_code=422,
                    detail=f"Box must be within image bounds ({width}x{height}).",
                )
            if x2 <= x1 or y2 <= y1:
                raise HTTPException(
                    status_code=422,
                    detail="Draw a box with positive width and height.",
                )

            box_prompt = np.array([x1, y1, x2, y2], dtype=np.float32)
            masks, scores, _ = sam_predictor.predict(
                box=box_prompt,
                multimask_output=False,
            )
            mask = np.asarray(masks[0]).astype(bool)
            score = float(scores[0])
            selection_method = "SAM2 box prompt"
        
        elif request.pointCoords is not None:
            point_coords = np.asarray(
                request.pointCoords, dtype=np.float32
            )
            point_labels = np.asarray(
                request.pointLabels, dtype=np.int32
            )

            if (
                np.any(point_coords[:, 0] >= width)
                or np.any(point_coords[:, 1] >= height)
            ):
                raise HTTPException(
                    status_code=422,
                    detail="Points must be within image bounds.",
                )

            masks, scores, _ = sam_predictor.predict(
                point_coords=point_coords,
                point_labels=point_labels,
                multimask_output=False,
            )

            best_index = int(np.argmax(scores))
            mask = np.asarray(masks[best_index]).astype(bool)
            score = float(scores[best_index])
            selection_method = "SAM2 positive/negative points"

        else:
            # Keep support for older Flutter requests.
            px = int(round(request.x))
            py = int(round(request.y))

            if px >= width or py >= height:
                raise HTTPException(
                    status_code=422,
                    detail="Coordinates must be within image bounds.",
                )

            point_coords = np.array([[px, py]], dtype=np.float32)
            point_labels = np.array([1], dtype=np.int32)

            masks, scores, _ = sam_predictor.predict(
                point_coords=point_coords,
                point_labels=point_labels,
                multimask_output=True,
            )

            best_index = int(np.argmax(scores))
            mask = np.asarray(masks[best_index]).astype(bool)
            score = float(scores[best_index])
            selection_method = "SAM2 point prompt (legacy)"

        if mask.shape != (height, width):
            mask = cv2.resize(
                mask.astype(np.uint8),
                (width, height),
                interpolation=cv2.INTER_NEAREST,
            ).astype(bool)

        ys, xs = np.where(mask)
        if len(xs) == 0 or len(ys) == 0:
            raise HTTPException(
                status_code=422,
                detail="SAM2 did not produce a usable mask. Try a tighter box.",
            )

        # Tight bounding box around the returned mask.
        object_x1 = int(xs.min())
        object_x2 = int(xs.max()) + 1
        object_y1 = int(ys.min())
        object_y2 = int(ys.max()) + 1

        contours, _ = cv2.findContours(
            mask.astype(np.uint8),
            cv2.RETR_EXTERNAL,
            cv2.CHAIN_APPROX_SIMPLE,
        )
        polygons = []
        for contour in contours:
            if cv2.contourArea(contour) < 10:
                continue
            simplified = cv2.approxPolyDP(contour, 2.0, True)
            polygon = [
                [int(point[0][0]), int(point[0][1])]
                for point in simplified
            ]
            if len(polygon) >= 3:
                polygons.append(polygon)

        mask_uint8 = mask.astype(np.uint8) * 255

        # Full-image transparent overlay: Flutter displays it over the full room image.
        green_overlay = np.zeros((height, width, 4), dtype=np.uint8)
        green_overlay[:, :, 1] = 255
        green_overlay[:, :, 3] = mask.astype(np.uint8) * 130
        green_overlay_base64 = encode_png(green_overlay)


        active_rgb = cv2.cvtColor(active_image, cv2.COLOR_BGR2RGB)

        rgba_image = np.zeros((height, width, 4), dtype=np.uint8)
        rgba_image[:, :, :3] = active_image
        rgba_image[:, :, 3] = mask_uint8
        object_crop = rgba_image[
            object_y1:object_y2, object_x1:object_x2
        ]
        mask_crop = mask_uint8[object_y1:object_y2, object_x1:object_x2]

        object_image_base64 = encode_png(object_crop)
        mask_image_base64 = encode_png(mask_crop)

        return {
            "message": "Object selected successfully",
            "projectId": request.projectId,
            "width": width,
            "height": height,
            "x": request.x,
            "y": request.y,
            "x1": object_x1,
            "y1": object_y1,
            "x2": object_x2,
            "y2": object_y2,
            "objectWidth": object_x2 - object_x1,
            "objectHeight": object_y2 - object_y1,
            "score": round(score, 4),
            "selectionMethod": selection_method,
            "polygons": polygons,
            "objectImageBase64": object_image_base64,
            "maskImageBase64": mask_image_base64,
            "greenOverlayBase64": green_overlay_base64,
        }

    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"SAM2 selection failed: {error}",
        )

@app.post("/recommend")
def recommend(data: ProductRequest):
    if not API_KEY:
        raise HTTPException(
            status_code=500,
            detail="SERPAPI_KEY is missing",
        )

    query = f"{data.color} {data.object_type}".strip()

    try:
        response = requests.get(
            "https://serpapi.com/search.json",
            params={
                "engine": "google_shopping",
                "q": query,
                "gl": "in",
                "hl": "en",
                "api_key": API_KEY,
            },
            timeout=60,
        )

        # Log provider errors for debugging.
        if response.status_code != 200:
            print("SerpApi HTTP status:", response.status_code)
            print("SerpApi response:", response.text[:1000])

            raise HTTPException(
                status_code=502,
                detail="Shopping provider returned an error",
            )

        result = response.json()

        print("SerpApi result keys:", result.keys())
        print("SerpApi error:", result.get("error"))
        print(
            "Shopping results count:",
            len(result.get("shopping_results", [])),
        )

        if result.get("error"):
            print("SerpApi reported an error:", result["error"])

    except requests.RequestException as e:
        print("Shopping request error:", str(e))
        raise HTTPException(
            status_code=502,
            detail="Shopping search request failed",
        ) from e

    products = []

    for item in result.get("shopping_results", []):
        raw_price = item.get("price", "")

        # Convert a price like "₹17,267" into a number.
        if isinstance(raw_price, (int, float)):
            price_value = float(raw_price)
        else:
            price_text = str(raw_price)
            digits = "".join(
                ch for ch in price_text
                if ch.isdigit() or ch == "."
            )

            try:
                price_value = float(digits) if digits else None
            except ValueError:
                price_value = None

        # Keep only products with a known price within budget.
        if price_value is None or price_value > data.budget:
            continue

        products.append({
            "name": item.get("title", "Product"),
            "price": raw_price,
            "store": item.get("source", "Online store"),
            "imageUrl": item.get("thumbnail", ""),
            "productUrl": item.get("product_link", ""),
        })

    return {
        "query": query,
        "budget": data.budget,
        "count": len(products),
        "products": products,
    }


@app.get("/health")
def health():
    return {
        "status": "ok",
        "yolo_loaded": yolo is not None,
        "sam2_loaded": sam_predictor is not None,
        "redesign_model_loaded": inpaint_pipe is not None,
        "device": "cuda" if torch.cuda.is_available() else "cpu",
    }


@app.post("/redesign")
async def redesign_room(
    image: UploadFile = File(...),
    room_type: str = Form(...),
    existing_objects: str = Form(""),
    prompt: str = Form(...),
):
    if inpaint_pipe is None:
        raise HTTPException(
            status_code=503,
            detail="Redesign model is not loaded."
        )

    try:
        # 1. Keep the original image unchanged for the final output.
        contents = await image.read()
        original_full = Image.open(
            BytesIO(contents)
        ).convert("RGB")

        original_width, original_height = original_full.size

        # Work on a smaller copy for CPU-based generation.
        original = original_full.copy()
        original.thumbnail((512, 512))

        width, height = original.size
        scale_x = width / original_width
        scale_y = height / original_height

        # 2. Read existing furniture metadata from Flutter.
        try:
            objects = json.loads(existing_objects or "[]")
            if not isinstance(objects, list):
                objects = []
        except json.JSONDecodeError:
            raise HTTPException(
                status_code=422,
                detail="existing_objects must be a valid JSON list."
            )

        # 3. Start with a protected image.
        # Only the lower part of the image is a candidate for new furniture.
        # This is a conservative starting point, not automatic floor detection.
        editable = np.full((height, width), 255, dtype=np.uint8)


        # Protect existing objects using their polygons and bounding boxes.
        protected = np.zeros((height, width), dtype=np.uint8)

        for obj in objects:
            if not isinstance(obj, dict):
                continue

            polygon = obj.get("polygons", obj.get("segmentation", []))

            if polygon:
                points = []

                for point in polygon:
                    if isinstance(point, dict):
                        px = point.get("x")
                        py = point.get("y")
                    elif isinstance(point, (list, tuple)) and len(point) >= 2:
                        px, py = point[0], point[1]
                    else:
                        continue

                    if px is None or py is None:
                        continue

                    points.append([
                        int(float(px) * scale_x),
                        int(float(py) * scale_y)
                    ])

                if len(points) >= 3:
                    cv2.fillPoly(
                        protected,
                        [np.array(points, dtype=np.int32)],
                        255
                    )
                    continue

            # Fall back to a bounding box if no usable polygon exists.
            try:
                x = float(obj.get("x", 0)) * scale_x
                y = float(obj.get("y", 0)) * scale_y
                w = float(obj.get("width", 0)) * scale_x
                h = float(obj.get("height", 0)) * scale_y

                if w > 0 and h > 0:
                    cv2.rectangle(
                        protected,
                        (int(x), int(y)),
                        (int(x + w), int(y + h)),
                        255,
                        thickness=-1
                    )
            except (TypeError, ValueError):
                continue

       # Expand protected furniture masks to protect their edges.
        kernel = np.ones((11, 11), dtype=np.uint8)
        protected = cv2.dilate(protected, kernel, iterations=1)

# Never allow the model to repaint protected furniture.
        editable[protected > 0] = 0

# Make sure there is enough area available for redesign.
        if np.count_nonzero(editable) < int(width * height * 0.02):
            raise HTTPException(
               status_code=422,
              detail=(
              "Not enough editable area remains. "
              "Check the existing furniture masks."
              )
         )

# White = regenerate; black = preserve.
        mask = Image.fromarray(editable, mode="L")

        full_prompt = (
    "Photorealistic redesign of the exact input living room photograph. "
    f"Room type: {room_type}. "
    f"Interior design style: {prompt}. "

    "PRESERVE all existing furniture exactly as it is. "
    "Keep the original white sofa, plant, and floor lamp in their "
    "exact positions, shapes, sizes, and colors. "

    "ADD TWO clearly visible new objects in the editable areas: "

    "1. WALL ART: Place two or three elegant framed artwork pieces "
    "on the large empty blue wall above the sofa. "
    "Use coordinated artwork, realistic frames, and proper perspective. "

    "2. AREA RUG: Add a large, beautiful area rug on the visible floor "
    "in front of and beneath the sofa's front legs. "
    "Use a coordinated pattern and realistic fabric texture. "
    "The rug must be clearly visible on the floor. "

    "These two new objects are mandatory. Do not merely recolor the wall "
    "or floor. Make the changes visibly different from the original image. "

    "Preserve the original windows, doors, ceiling, architecture, "
    "camera angle, room dimensions, and lighting direction. "
    "Do not move, remove, replace, or duplicate existing furniture. "
    "Photorealistic interior photography, realistic shadows and scale."
)

        negative_prompt = (
    "different room, changed room layout, changed camera angle, "
    "warped walls, distorted windows, distorted doors, "
    "moved sofa, replaced sofa, removed plant, moved floor lamp, "
    "duplicated furniture, deformed objects, floating objects, "
    "unrealistic shadows, unrealistic perspective, blurry details, "
    "text, watermark, illustration, cartoon, CGI appearance"
)
        print("Starting addition-only redesign...", flush=True)

        # 5. Generate only within the allowed mask.
        with torch.inference_mode():
                generated = inpaint_pipe(
    prompt=full_prompt,
    negative_prompt=negative_prompt,
    image=original,
    mask_image=mask,
    num_inference_steps=30,
    guidance_scale=8.0,
    strength=1.0,
).images[0].convert("RGB")


        # 6. Composite only the permitted area onto the original.
        # All pixels outside this mask come from the original image.
        generated = generated.resize(
            (original_width, original_height),
            Image.Resampling.LANCZOS
        )

        final_mask = Image.fromarray(
            cv2.resize(
                editable,
                (original_width, original_height),
                interpolation=cv2.INTER_NEAREST
            ),
            mode="L"
        )

        # Soften only the edit boundary to reduce harsh seams.
        final_mask = final_mask.filter(
            ImageFilter.GaussianBlur(radius=3)
        )

        final_image = Image.composite(
            generated,
            original_full,
            final_mask
        )

        buffer = BytesIO()
        final_image.save(buffer, format="PNG")
        buffer.seek(0)

        print("Addition-only redesign completed.", flush=True)

        return StreamingResponse(
            buffer,
            media_type="image/png"
        )

    except HTTPException:
        raise
    except Exception as error:
        print("Redesign error:", repr(error), flush=True)
        raise HTTPException(
            status_code=500,
            detail=f"Room redesign failed: {error}"
        )
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)