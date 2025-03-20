"""
AI Service API Main Module

This module serves as the entry point for the AI service API, providing
endpoints for generative AI capabilities including text description
generation and image generation. It handles application setup, router
configuration, and health status monitoring.
"""
import os
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from routers.description_generator import description
from routers.image_generator import image


app = FastAPI(version=os.environ.get("APP_VERSION", "0.1.0"))
app.include_router(description)
app.include_router(image)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/health", summary="check if server is healthy", operation_id="health")
async def get_health():
    """
    Returns status code 200
    """
    # Initialize the array with "description"
    capabilities = ["description"]

    # Check if the environment variable is set
    if (os.environ.get("AZURE_OPENAI_DALLE_ENDPOINT") or os.environ.get("AZURE_OPENAI_ENDPOINT")) \
       and os.environ.get("AZURE_OPENAI_DALLE_DEPLOYMENT_NAME"):
        capabilities.append("image")

    print("Generative AI capabilities: ", ", ".join(capabilities))
    return JSONResponse(content=
                        {"status": 'ok', "version": app.version, "capabilities": capabilities},
                        status_code=status.HTTP_200_OK)
