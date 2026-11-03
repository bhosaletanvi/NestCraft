
import os
import tempfile
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from supabase import create_client
from ultralytics import YOLO
import io
import cv2
import numpy as np
from PIL import Image
from fastapi.responses import Response
from fastapi import Form


# Load Supabase configuration
load_dotenv("supabase_config.txt")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise RuntimeError(
        "Supabase URL or key missing in supabase_config.txt"
    )

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
print("Supabase URL:", SUPABASE_URL)

app = FastAPI(title="NestCraft Furniture Detection API")


# Allow requests from Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_methods=["*"],
    allow_headers=["*"],
    
    allow_credentials=False,
   
)


# Load YOLO model
model = YOLO("yolo11n.pt")
seg_model = YOLO("yolo11n-seg.pt")

@app.get("/")
def home():
    return {"message": "NestCraft YOLO API is running!"}


# Furniture detection endpoint
@app.post("/detect")
async def detect_furniture(image: UploadFile = File(...)):

    if (
        not image.content_type
        or not image.content_type.startswith("image/")
    ):
        raise HTTPException(
            status_code=400,
            detail="Please upload an image file.",
        )

    temp_path = None

    try:
        suffix = Path(image.filename or "room.jpg").suffix or ".jpg"

        with tempfile.NamedTemporaryFile(
            suffix=suffix,
            delete=False,
        ) as temp:
            temp_path = Path(temp.name)
            temp.write(await image.read())

        results = model.predict(
            source=str(temp_path),
            conf=0.25,
            verbose=False,
        )

        result = results[0]
        detections = []

        for box in result.boxes:
            class_id = int(box.cls[0].item())
            x1, y1, x2, y2 = box.xyxy[0].tolist()

            detections.append({
                "class_id": class_id,
                "label": model.names[class_id],
                "confidence": round(float(box.conf[0].item()), 3),
                "x1": round(x1, 2),
                "y1": round(y1, 2),
                "x2": round(x2, 2),
                "y2": round(y2, 2),
            })

        return {
            "image_width": int(result.orig_shape[1]),
            "image_height": int(result.orig_shape[0]),
            "detections": detections,
        }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Detection failed: {str(e)}",
        )

    finally:
        if temp_path is not None:
            temp_path.unlink(missing_ok=True)

        await image.close()


# Supabase image upload endpoint
@app.post("/upload")
async def upload_image(image: UploadFile = File(...)):

    if (
        not image.content_type
        or not image.content_type.startswith("image/")
    ):
        raise HTTPException(
            status_code=400,
            detail="Please upload an image file.",
        )

    try:
        image_data = await image.read()

        if not image_data:
            raise HTTPException(
                status_code=400,
                detail="Uploaded image is empty.",
            )

        # Create a unique filename to avoid accidental overwrites
        original_name = Path(image.filename or "room.jpg").name
        extension = Path(original_name).suffix or ".jpg"
        storage_path = f"rooms/{__import__('uuid').uuid4().hex}{extension}"

        upload_result = supabase.storage.from_("room-images").upload(
            path=storage_path,
            file=image_data,
            file_options={
                "content-type": image.content_type or "image/jpeg",
                "upsert": "false",
            },
        )

        print("SUPABASE UPLOAD RESULT:", upload_result)

        return {
            "message": "Image uploaded successfully!",
            "bucket": "room-images",
            "path": storage_path,
            "upload_result": str(upload_result),
        }
    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Image upload failed: {str(e)}",
        )

    finally:
        await image.close()
@app.post("/segment")
async def segment_furniture(
    image: UploadFile = File(...),
    x1: float = Form(...),
    y1: float = Form(...),
    x2: float = Form(...),
    y2: float = Form(...),
    class_id: int = Form(-1),
):
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail="Please upload an image file.",
        )

    try:
        image_bytes = await image.read()

        if not image_bytes:
            raise HTTPException(
                status_code=400,
                detail="Uploaded image is empty.",
            )

        pil_image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        original = np.array(pil_image)
        height, width = original.shape[:2]

        results = seg_model.predict(
            source=original,
            conf=0.25,
            verbose=False,
        )
        result = results[0]

        if result.masks is None or result.boxes is None or len(result.boxes) == 0:
            raise HTTPException(
                status_code=404,
                detail="No segmentable furniture found in the image.",
            )

        target_box = np.array([x1, y1, x2, y2], dtype=float)
        best_index = -1
        best_score = 0.0

        for i, box in enumerate(result.boxes):
            predicted_class = int(box.cls[0].item())

            if class_id >= 0 and predicted_class != class_id:
                continue

            predicted_box = box.xyxy[0].cpu().numpy()

            ix1 = max(target_box[0], predicted_box[0])
            iy1 = max(target_box[1], predicted_box[1])
            ix2 = min(target_box[2], predicted_box[2])
            iy2 = min(target_box[3], predicted_box[3])

            intersection = max(0, ix2 - ix1) * max(0, iy2 - iy1)

            target_area = max(0, target_box[2] - target_box[0]) * max(
                0, target_box[3] - target_box[1]
            )
            predicted_area = max(0, predicted_box[2] - predicted_box[0]) * max(
                0, predicted_box[3] - predicted_box[1]
            )

            union = target_area + predicted_area - intersection
            score = intersection / union if union > 0 else 0.0

            if score > best_score:
                best_score = score
                best_index = i

        if best_index < 0 or best_score < 0.1:
            raise HTTPException(
                status_code=404,
                detail="Could not match the selected furniture.",
            )

        mask = result.masks.data[best_index].cpu().numpy()
        mask = cv2.resize(
            mask.astype(np.float32),
            (width, height),
            interpolation=cv2.INTER_LINEAR,
        )
        mask = (mask > 0.5).astype(np.uint8) * 255

        contours, _ = cv2.findContours(
            mask,
            cv2.RETR_EXTERNAL,
            cv2.CHAIN_APPROX_SIMPLE,
        )

        if not contours:
            raise HTTPException(
                status_code=404,
                detail="Furniture mask is empty.",
            )

        largest_contour = max(contours, key=cv2.contourArea)
        clean_mask = np.zeros_like(mask)
        cv2.drawContours(
            clean_mask,
            [largest_contour],
            -1,
            255,
            thickness=cv2.FILLED,
        )

        x, y, crop_width, crop_height = cv2.boundingRect(largest_contour)

        rgba = cv2.cvtColor(original, cv2.COLOR_RGB2RGBA)
        rgba[:, :, 3] = clean_mask

        cutout = Image.fromarray(rgba).crop(
            (x, y, x + crop_width, y + crop_height)
        )

        output = io.BytesIO()
        cutout.save(output, format="PNG")

        return Response(
            content=output.getvalue(),
            media_type="image/png",
            headers={
                "X-Cutout-X": str(x),
                "X-Cutout-Y": str(y),
                "X-Cutout-Width": str(crop_width),
                "X-Cutout-Height": str(crop_height),
            },
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Segmentation failed: {str(e)}",
        )
    finally:
        await image.close()

@app.post("/remove-furniture")
async def remove_furniture(
    image: UploadFile = File(...),
    x1: int = Form(...),
    y1: int = Form(...),
    x2: int = Form(...),
    y2: int = Form(...),
    class_id: int = Form(-1),
):
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail="Please upload an image file.",
        )

    try:
        image_bytes = await image.read()

        if not image_bytes:
            raise HTTPException(
                status_code=400,
                detail="Uploaded image is empty.",
            )

        pil_image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        original = np.array(pil_image)
        height, width = original.shape[:2]

        x1 = max(0, min(x1, width - 1))
        y1 = max(0, min(y1, height - 1))
        x2 = max(0, min(x2, width))
        y2 = max(0, min(y2, height))

        if x2 <= x1 or y2 <= y1:
            raise HTTPException(
                status_code=400,
                detail="Invalid furniture coordinates.",
            )

        # Detect segmentable furniture in the room photo.
        results = seg_model.predict(
            source=original,
            conf=0.25,
            verbose=False,
        )
        result = results[0]

        if result.masks is None or result.boxes is None:
            raise HTTPException(
                status_code=404,
                detail="No segmentable furniture found.",
            )

        # Match the selected rectangle to the best overlapping detection.
        target_box = np.array([x1, y1, x2, y2], dtype=float)
        best_index = -1
        best_score = 0.0

        for i, box in enumerate(result.boxes):
            predicted_class = int(box.cls[0].item())

            if class_id >= 0 and predicted_class != class_id:
                continue

            predicted_box = box.xyxy[0].cpu().numpy()

            ix1 = max(target_box[0], predicted_box[0])
            iy1 = max(target_box[1], predicted_box[1])
            ix2 = min(target_box[2], predicted_box[2])
            iy2 = min(target_box[3], predicted_box[3])

            intersection = max(0, ix2 - ix1) * max(0, iy2 - iy1)

            target_area = (x2 - x1) * (y2 - y1)
            predicted_area = max(0, predicted_box[2] - predicted_box[0]) * max(
                0, predicted_box[3] - predicted_box[1]
            )

            union = target_area + predicted_area - intersection
            score = intersection / union if union > 0 else 0.0

            if score > best_score:
                best_score = score
                best_index = i

        if best_index < 0 or best_score < 0.1:
            raise HTTPException(
                status_code=404,
                detail="Could not match selected furniture.",
            )

        # Convert the selected YOLO mask to the original image dimensions.
        mask = result.masks.data[best_index].cpu().numpy()
        mask = cv2.resize(
            mask.astype(np.float32),
            (width, height),
            interpolation=cv2.INTER_LINEAR,
        )
        mask = (mask > 0.5).astype(np.uint8) * 255

        # Slightly expand the mask to cover furniture edges.
        kernel = np.ones((7, 7), dtype=np.uint8)
        mask = cv2.dilate(mask, kernel, iterations=1)

        # Fill the furniture-shaped area with OpenCV inpainting.
        bgr_image = cv2.cvtColor(original, cv2.COLOR_RGB2BGR)
        result_image = cv2.inpaint(
            bgr_image,
            mask,
            5,
            cv2.INPAINT_TELEA,
        )

        result_image = cv2.cvtColor(result_image, cv2.COLOR_BGR2RGB)
        output_image = Image.fromarray(result_image)

        output = io.BytesIO()
        output_image.save(output, format="PNG")

        return Response(
            content=output.getvalue(),
            media_type="image/png",
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Furniture removal failed: {str(e)}",
        )
    finally:
        await image.close()

@app.post("/replace-furniture")
async def replace_furniture(
    image: UploadFile = File(...),
    furniture_image: UploadFile = File(...),
    x1: int = Form(...),
    y1: int = Form(...),
    x2: int = Form(...),
    y2: int = Form(...),
    class_id: int = Form(-1),
):
    try:
        # Validate both uploaded images
        if (
            not image.content_type
            or not image.content_type.startswith("image/")
            or not furniture_image.content_type
            or not furniture_image.content_type.startswith("image/")
        ):
            raise HTTPException(
                status_code=400,
                detail="Both files must be images.",
            )

        room_bytes = await image.read()
        furniture_bytes = await furniture_image.read()

        if not room_bytes or not furniture_bytes:
            raise HTTPException(
                status_code=400,
                detail="Room or furniture image is empty.",
            )

        # Load original room photo
        room_pil = Image.open(
            io.BytesIO(room_bytes)
        ).convert("RGB")

        original = np.array(room_pil)
        height, width = original.shape[:2]

        # Validate coordinates
        x1 = max(0, min(x1, width - 1))
        y1 = max(0, min(y1, height - 1))
        x2 = max(0, min(x2, width))
        y2 = max(0, min(y2, height))

        if x2 <= x1 or y2 <= y1:
            raise HTTPException(
                status_code=400,
                detail="Invalid furniture coordinates.",
            )

        # Run YOLO segmentation
        results = seg_model.predict(
            source=original,
            conf=0.25,
            verbose=False,
        )

        result = results[0]

        if result.masks is None or result.boxes is None:
            raise HTTPException(
                status_code=404,
                detail="No segmentable furniture found.",
            )

        target = np.array(
            [x1, y1, x2, y2],
            dtype=float,
        )

        best_index = -1
        best_score = 0.0

        # Match selected furniture with YOLO detection
        for i, box in enumerate(result.boxes):
            predicted_class = int(box.cls[0].item())

            if class_id >= 0 and predicted_class != class_id:
                continue

            predicted = box.xyxy[0].cpu().numpy()

            ix1 = max(target[0], predicted[0])
            iy1 = max(target[1], predicted[1])
            ix2 = min(target[2], predicted[2])
            iy2 = min(target[3], predicted[3])

            intersection = (
                max(0, ix2 - ix1)
                * max(0, iy2 - iy1)
            )

            target_area = (x2 - x1) * (y2 - y1)

            predicted_area = (
                max(0, predicted[2] - predicted[0])
                * max(0, predicted[3] - predicted[1])
            )

            union = target_area + predicted_area - intersection
            score = intersection / union if union > 0 else 0.0

            if score > best_score:
                best_score = score
                best_index = i

        if best_index < 0 or best_score < 0.1:
            raise HTTPException(
                status_code=404,
                detail="Could not match the selected furniture.",
            )

        # Build mask for the original furniture
        mask = result.masks.data[best_index].cpu().numpy()

        mask = cv2.resize(
            mask.astype(np.float32),
            (width, height),
            interpolation=cv2.INTER_LINEAR,
        )

        mask = (mask > 0.5).astype(np.uint8) * 255

        # Expand mask slightly around the furniture edges
        kernel = np.ones((7, 7), dtype=np.uint8)
        mask = cv2.dilate(mask, kernel, iterations=1)

        # Remove original furniture with inpainting
        bgr = cv2.cvtColor(original, cv2.COLOR_RGB2BGR)

        cleaned_bgr = cv2.inpaint(
            bgr,
            mask,
            5,
            cv2.INPAINT_TELEA,
        )

        cleaned_rgb = cv2.cvtColor(
            cleaned_bgr,
            cv2.COLOR_BGR2RGB,
        )

        # Load replacement image
        # Transparent-background PNG is recommended
        new_furniture = Image.open(
            io.BytesIO(furniture_bytes)
        ).convert("RGBA")

        # Fit replacement to selected rectangle
        target_width = x2 - x1
        target_height = y2 - y1

        new_furniture = new_furniture.resize(
            (target_width, target_height),
            Image.Resampling.LANCZOS,
        )

        # Composite replacement onto cleaned room
        background = Image.fromarray(
            cleaned_rgb
        ).convert("RGBA")

        background.alpha_composite(
            new_furniture,
            dest=(x1, y1),
        )

        # Return final image as PNG
        output = io.BytesIO()

        background.convert("RGB").save(
            output,
            format="PNG",
        )

        return Response(
            content=output.getvalue(),
            media_type="image/png",
            headers={"Cache-Control": "no-store"},
        )

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Furniture replacement failed: {str(e)}",
        )

    finally:
        await image.close()
        await furniture_image.close()

