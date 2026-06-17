"""
Image generation API endpoint using Azure OpenAI GPT-image-2.
"""

import logging
import os

from openai import AzureOpenAI, BadRequestError
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

logger = logging.getLogger(__name__)

# Keep the image prompt simple and product-focused to reduce false safety blocks.
USER_PROMPT_TEMPLATE = (
    "Create a clean studio product photo for an online pet supply store. "
    "Show the product named '{name}' using this description: '{description}'. "
    "Use a plain background and retail packaging. No people, animals, or text overlays."
)


class ImageRequest(BaseModel):
    """Request model for the image generation endpoint."""

    name: str
    description: str


# Create router with prefix
image = APIRouter(prefix="/generate", tags=["generation"])


def _handle_azure_openai(user_prompt, use_azure_ad):
    endpoint = os.environ.get("AZURE_OPENAI_IMAGE_ENDPOINT") or os.environ.get(
        "AZURE_OPENAI_ENDPOINT"
    )
    if not endpoint:
        raise ValueError(
            "AZURE_OPENAI_IMAGE_ENDPOINT or AZURE_OPENAI_ENDPOINT must be provided"
        )

    model_deployment_name = os.environ.get("AZURE_OPENAI_IMAGE_DEPLOYMENT_NAME")
    if not model_deployment_name:
        raise ValueError("AZURE_OPENAI_IMAGE_DEPLOYMENT_NAME must be provided")

    api_version = os.environ.get("AZURE_OPENAI_IMAGE_API_VERSION") or os.environ.get(
        "AZURE_OPENAI_API_VERSION", "2025-04-01-preview"
    )

    if use_azure_ad:
        token_provider = get_bearer_token_provider(
            DefaultAzureCredential(), "https://cognitiveservices.azure.com/.default"
        )
        client = AzureOpenAI(
            api_version=api_version,
            azure_endpoint=endpoint,
            azure_ad_token_provider=token_provider,
        )
    else:
        api_key = os.environ.get("OPENAI_API_KEY") or os.environ.get(
            "AZURE_OPENAI_API_KEY"
        )
        if not api_key:
            raise ValueError("OPENAI_API_KEY or AZURE_OPENAI_API_KEY must be provided")

        client = AzureOpenAI(
            api_version=api_version,
            azure_endpoint=endpoint,
            api_key=api_key,
        )

    response = client.images.generate(
        model=model_deployment_name,
        prompt=user_prompt,
        n=1,
        size="1024x1024",
        quality="high",
        output_format="png",
    )

    image_base64 = response.data[0].b64_json
    return f"data:image/png;base64,{image_base64}"


def _extract_bad_request_details(error: BadRequestError) -> tuple[int, str]:
    error_body = getattr(error, "body", None) or {}
    error_info = error_body.get("error", {}) if isinstance(error_body, dict) else {}
    error_code = error_info.get("code")

    if error_code == "moderation_blocked":
        return (
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            "Image request was blocked by Azure OpenAI safety checks. Try a simpler product description.",
        )

    message = error_info.get("message")
    if isinstance(message, str) and message:
        return status.HTTP_400_BAD_REQUEST, message

    return status.HTTP_400_BAD_REQUEST, "Image generation request was rejected"


@image.post("/image", operation_id="generate_image")
async def generate_image(request: ImageRequest):
    """
    Generate a product image based on the product name and description
    """
    try:
        user_prompt = USER_PROMPT_TEMPLATE.format(
            name=request.name, description=request.description
        )

        env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env")
        if os.path.exists(env_path):
            logger.info("Loading environment from: %s", env_path)
            load_dotenv(dotenv_path=env_path, override=True)

        use_azure_ad = os.environ.get("USE_AZURE_AD", "False").lower() == "true"

        image_url = _handle_azure_openai(user_prompt, use_azure_ad)

        return JSONResponse(
            content={"image": image_url}, status_code=status.HTTP_200_OK
        )
    except BadRequestError as error:
        logger.warning("Image generation rejected by Azure OpenAI: %s", error)
        status_code, detail = _extract_bad_request_details(error)
        raise HTTPException(status_code=status_code, detail=detail) from error
    except Exception as error:
        logger.exception("Error generating image")
        raise HTTPException(status_code=500, detail="Error generating image") from error
