
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, HttpUrl
from PIL import Image
from io import BytesIO
from ultralytics import YOLO
from pathlib import Path
import numpy as np
import requests
import torch

app = FastAPI(title="NestCraft Object Detection API")

BASE_DIR = Path(__file__).resolve().parent
YOLO_MODEL_PATH = "yolo26n-seg.pt"

# Load YOLO once when the API starts.
yolo = None


class AnalyzeRequest(BaseModel):
    projectId: str
    imageUrl: HttpUrl


@app.on_event("startup")
def load_yolo_model():
    global yolo

    try:
        yolo = YOLO(YOLO_MODEL_PATH)
        print("YOLO segmentation model loaded successfully.")
        print("Device:", "cuda" if torch.cuda.is_available() else "cpu")
    except Exception as error:
        print("Failed to load YOLO model:", error)
        raise RuntimeError(f"Could not load YOLO model: {error}")


@app.get("/")
def home():
    return {
        "message": "NestCraft Python API is running"
    }


@app.post("/analyze")
def analyze_image(request: AnalyzeRequest):
    if yolo is None:
        raise HTTPException(
            status_code=503,
            detail="YOLO model is not loaded."
        )

    try:
        # Download the uploaded room image from Supabase.
        response = requests.get(
            str(request.imageUrl),
            timeout=60
        )
        response.raise_for_status()

        image = Image.open(
            BytesIO(response.content)
        ).convert("RGB")

        image_array = np.array(image)

        # Run YOLO segmentation.
        results = yolo.predict(
            source=image_array,
            conf=0.25,
            retina_masks=True,
            verbose=False,
            device="cpu"
        )

        detected_objects = []

        for result in results:
            if result.boxes is None:
                continue

            for index, box in enumerate(result.boxes):
                class_id = int(box.cls[0].item())
                confidence = float(box.conf[0].item())

                x1, y1, x2, y2 = [
                    round(float(value), 2)
                    for value in box.xyxy[0].tolist()
                ]

                # Return bounding boxes and detection information.
                # Segmentation masks will be exposed in a later step.
                detected_objects.append({
                    "index": index,
                    "type": result.names[class_id],
                    "confidence": round(confidence, 4),
                    "x": x1,
                    "y": y1,
                    "width": round(x2 - x1, 2),
                    "height": round(y2 - y1, 2)
                })

        return {
            "message": "YOLO analysis completed",
            "projectId": request.projectId,
            "width": image.width,
            "height": image.height,
            "objectCount": len(detected_objects),
            "objects": detected_objects
        }

    except requests.RequestException as error:
        raise HTTPException(
            status_code=400,
            detail=f"Could not download room image: {error}"
        )
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"Image analysis failed: {error}"
        )
