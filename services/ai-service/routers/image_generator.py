from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from openai import AzureOpenAI
from fastapi import APIRouter, Request, status
from fastapi.responses import Response, JSONResponse
from typing import Any, List, Dict
import json
import os

# Define the image API router
image: APIRouter = APIRouter(prefix="/generate", tags=["generate"])

# Define the Product class
class Product:
    def __init__(self, product: Dict[str, List]) -> None:
        self.name: str = product["name"]
        self.description: List[str] = product["description"]

# Define the post_image endpoint
@image.post("/image", summary="Get image for a product", operation_id="getImage")
async def post_image(request: Request) -> JSONResponse:
    try:
        # Parse the request body and create a Product object
        body: dict = await request.json()
        product: Product = Product(body)
        name: str = product.name
        description: List = product.description

        print("Calling OpenAI")
        
        api_version = os.environ.get("AZURE_OPENAI_API_VERSION")
        endpoint = os.environ.get("AZURE_OPENAI_DALLE_ENDPOINT") or os.environ.get("AZURE_OPENAI_ENDPOINT")
        model_deployment_name = os.environ.get("AZURE_OPENAI_DALLE_DEPLOYMENT_NAME")
        
        token_provider = get_bearer_token_provider(DefaultAzureCredential(), "https://cognitiveservices.azure.com/.default")
        
        client = AzureOpenAI(
            api_version=api_version,
            azure_endpoint=endpoint,
            azure_ad_token_provider=token_provider,
        )

        result = client.images.generate(
            model=model_deployment_name,
            prompt="Generate a cute photo realistic image of a product in its packaging in front of a plain background for a product called <"+ name + "> with a description <" + description + "> to be sold in an online pet supply store",
            n=1
        )

        json_response = json.loads(result.model_dump_json())
        print(json_response)

        # Return the image as a JSON response
        return JSONResponse(content={"image": json_response["data"][0]["url"]}, status_code=status.HTTP_200_OK)
    except Exception as e:
        # Return an error message as a JSON response
        return JSONResponse(content={"error": str(e)}, status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)