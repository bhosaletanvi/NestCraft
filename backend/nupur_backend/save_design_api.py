
import os
import uuid
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, auth
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from supabase import create_client

BASE_DIR = Path(__file__).resolve().parent

# Load existing Supabase configuration.
load_dotenv(BASE_DIR / "supabase_config.txt")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise RuntimeError(
        "SUPABASE_URL or SUPABASE_KEY is missing in supabase_config.txt"
    )

# Initialize Firebase Admin without changing app.py.
firebase_key_path = BASE_DIR / "firebase-service-account.json"

if not firebase_key_path.exists():
    raise RuntimeError(
        "firebase-service-account.json was not found in the project folder."
    )

if not firebase_admin._apps:
    credential = credentials.Certificate(str(firebase_key_path))
    firebase_admin.initialize_app(credential)

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

app = FastAPI(title="NestCraft Save Design API")

# Local Flutter web development origins.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:5000",
        "http://localhost:5173",
        "http://localhost:8000",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:8000",
    ],
    allow_credentials=False,
    allow_methods=["POST", "GET", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)


@app.get("/")
def home():
    return {"message": "NestCraft Save Design API is running"}


@app.post("/save-design")
async def save_design(
    image: UploadFile = File(...),
    authorization: str | None = Header(default=None),
):
    # Require a Firebase ID token.
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Firebase authentication token is required.",
        )

    token = authorization.split(" ", 1)[1].strip()

    try:
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token["uid"]
    except Exception:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired Firebase token.",
        )

    # Accept only common image formats.
    allowed_types = {
        "image/jpeg": "jpg",
        "image/png": "png",
        "image/webp": "webp",
    }

    content_type = (image.content_type or "").lower()

    if content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail="Only JPEG, PNG, and WebP images are supported.",
        )

    image_bytes = await image.read()

    if not image_bytes:
        raise HTTPException(status_code=400, detail="The image is empty.")

    if len(image_bytes) > 10 * 1024 * 1024:
        raise HTTPException(
            status_code=413,
            detail="Image size must be 10 MB or less.",
        )

    extension = allowed_types[content_type]
    filename = f"{uuid.uuid4().hex}.{extension}"
    storage_path = f"designs/{uid}/{filename}"

    try:
        supabase.storage.from_("room-images").upload(
            path=storage_path,
            file=image_bytes,
            file_options={
                "content-type": content_type,
                "upsert": "false",
            },
        )
    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Could not save the image to Supabase Storage.",
        )

    return {
        "message": "Design saved successfully.",
        "path": storage_path,
    }
