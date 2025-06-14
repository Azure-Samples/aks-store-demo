"""
Image generation API endpoint using Azure OpenAI DALL-E.
"""
import os
import json
import logging
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel

logger = logging.getLogger(__name__)

# Define the user prompt template
USER_PROMPT_TEMPLATE = (
    "Generate a cute photo realistic image of a product in its packaging "
    "in front of a plain background for a product called '{name}' with "
    "a description '{description}' to be sold in an online pet supply store"
)

class ImageRequest(BaseModel):
    """Request model for the image generation endpoint."""
    name: str
    description: str

# Create router with prefix
image = APIRouter(
    prefix="/generate",
    tags=["generation"]
)

def _handle_azure_openai(user_prompt, use_azure_ad):
    endpoint = os.environ.get("AZURE_OPENAI_DALLE_ENDPOINT") \
                or os.environ.get("AZURE_OPENAI_ENDPOINT")
    if not endpoint:
        raise ValueError(
            "AZURE_OPENAI_DALLE_ENDPOINT or AZURE_OPENAI_ENDPOINT must be provided"
        )

    model_deployment_name = os.environ.get("AZURE_OPENAI_DALLE_DEPLOYMENT_NAME")
    if not os.environ.get("AZURE_OPENAI_DALLE_DEPLOYMENT_NAME"):
        raise ValueError("AZURE_OPENAI_DALLE_DEPLOYMENT_NAME must be provided")

    api_version = os.environ.get("AZURE_OPENAI_API_VERSION")
    if not api_version:
        raise ValueError("AZURE_OPENAI_API_VERSION must be provided")

    if use_azure_ad:
        token_provider = get_bearer_token_provider(
            DefaultAzureCredential(),
            "https://cognitiveservices.azure.com/.default"
        )
        client = AzureOpenAI(
            api_version=api_version,
            azure_endpoint=endpoint,
            azure_ad_token_provider=token_provider,
        )
    else:
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY must be provided")

        client = AzureOpenAI(
            api_version=api_version,
            azure_endpoint=endpoint,
            api_key=api_key,
        )

    response = client.images.generate(
        model=model_deployment_name,
        prompt=user_prompt,
        n=1
    )

    json_response = json.loads(response.model_dump_json())
    return json_response["data"][0]["url"]

@image.post("/image", operation_id="generate_image")
async def generate_image(request: ImageRequest):
    """
    Generate a product image based on the product name and description
    """
    try:
        # Format the user prompt with the product name and tags
        user_prompt = USER_PROMPT_TEMPLATE.format(
            name=request.name,
            description=request.description
        )

        env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env")
        if os.path.exists(env_path):
            logger.info("Loading environment from: %s", env_path)
            load_dotenv(dotenv_path=env_path, override=True)

        use_azure_ad = os.environ.get("USE_AZURE_AD", "False").lower() == "true"

        image_url = _handle_azure_openai(user_prompt, use_azure_ad)

        return JSONResponse(
            content={"image": image_url},
            status_code=status.HTTP_200_OK
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error generating image: {str(e)}"
        ) from e
