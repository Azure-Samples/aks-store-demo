from fastapi import APIRouter, Request, status
from fastapi.responses import Response, JSONResponse
import semantic_kernel as sk
from semantic_kernel.connectors.ai.open_ai import AzureTextCompletion
from dotenv import load_dotenv
from typing import Any, List, Dict
import os
import dotenv

# Load environment variables from .env file
load_dotenv()

# Initialize the semantic kernel
kernel: sk.Kernel = sk.Kernel()

# Get the Azure OpenAI deployment name, API key, and endpoint from environment variables
deployment: str = os.environ.get("AZURE_OPENAI_DEPLOYMENT_NAME")
api_key: str = os.environ.get("AZURE_OPENAI_API_KEY")
endpoint: str = os.environ.get("AZURE_OPENAI_ENDPOINT")

# Add the Azure OpenAI text completion service to the kernel
kernel.add_text_completion_service("dv", AzureTextCompletion(deployment, endpoint, api_key))

# Import semantic skills from the "skills" directory
skills_directory: str = "skills"
productFunctions: dict = kernel.import_semantic_skill_from_directory(skills_directory, "ProductSkill")
descriptionFunction: Any = productFunctions["Description"]

# Define the description API router
description: APIRouter = APIRouter(prefix="/generate", tags=["generate"])

# Define the Product class
class Product:
    def __init__(self, product: Dict[str, List]) -> None:
        self.name: str = product["name"]
        self.tags: List[str] = product["tags"]

# Define the post_description endpoint
@description.post("/description", summary="Get description for a product", operation_id="getDescription")
async def post_description(request: Request) -> JSONResponse:
    try:
        # Parse the request body and create a Product object
        body: dict = await request.json()
        product: Product = Product(body)
        name: str = product.name
        tags: List = ",".join(product.tags)

        # Create a new context and invoke the description function
        context: Any = kernel.create_new_context()
        context["name"] = name
        context["tags"] = tags
        result: str = await descriptionFunction.invoke_async(context=context)
        result = str(result).replace("\n", "")

        # Return the description as a JSON response
        return JSONResponse(content={"description": result}, status_code=status.HTTP_200_OK)
    except Exception as e:
        # Return an error message as a JSON response
        return JSONResponse(content={"error": str(e)}, status_code=status.HTTP_400_BAD_REQUEST)