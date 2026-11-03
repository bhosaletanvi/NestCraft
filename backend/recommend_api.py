
import os
import requests

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

load_dotenv()

API_KEY = os.getenv("SERPAPI_KEY")

app = FastAPI(title="NestCraft Shopping API")


class ProductRequest(BaseModel):
    object_type: str
    color: str = ""
    budget: int = 50000


@app.get("/")
def home():
    return {"message": "NestCraft Shopping API is running"}


@app.post("/recommend")
def recommend(data: ProductRequest):

    if not API_KEY:
        raise HTTPException(
            status_code=500,
            detail="SERPAPI_KEY is missing"
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
                "api_key": API_KEY
            },
            timeout=60
        )

        response.raise_for_status()
        result = response.json()

    except requests.RequestException as error:
        raise HTTPException(
            status_code=502,
            detail=f"Shopping search failed: {error}"
        )

    if result.get("error"):
        raise HTTPException(
            status_code=502,
            detail=result["error"]
        )

    products = []

    for item in result.get("shopping_results", []):

        raw_price = item.get("price", "")

        if isinstance(raw_price, (int, float)):
            price_value = float(raw_price)
        else:
            digits = "".join(
                ch for ch in str(raw_price)
                if ch.isdigit() or ch == "."
            )

            try:
                price_value = float(digits) if digits else None
            except ValueError:
                price_value = None

        if price_value is None or price_value > data.budget:
            continue

        products.append({
            "name": item.get("title", "Product"),
            "price": raw_price,
            "store": item.get("source", "Online store"),
            "imageUrl": item.get("thumbnail", ""),
            "productUrl": item.get("product_link", "")
        })

    return {
        "query": query,
        "budget": data.budget,
        "count": len(products),
        "products": products
    }
