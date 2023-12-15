from typing import Any, List, Dict
from fastapi import APIRouter, Request, status
from fastapi.responses import Response, JSONResponse
import requests
import json
from routers.LLM import get_llm 

# initialize the model that would be used for the app
kernel, useLocalLLM, endpoint = get_llm()
if not useLocalLLM:
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

        if useLocalLLM:
            print("Calling local LLM")
            
            prompt = f"Describe this pet store product using joyful, playful, and enticing language.\nProduct name: {name}\ntags: {tags}\ndescription:\""
            temperature = 0.5
            top_p = 0.0

            url = endpoint
            payload = {
                "prompt": prompt,
                "temperature": temperature,
                "top_p": top_p
            }
            headers = {"Content-Type": "application/json"}
            response = requests.request("POST", url, headers=headers, json=payload)
            
            # convert response.text to json
            result = json.loads(response.text)
            result = result["Result"]
            result = result.split("description:")[1]
            
            # remove all double quotes
            if "\"" in result:
                result = result.replace("\"", "")

            # # if first character is a double quote, remove it
            # if result[0] == "\"":
            #     result = result[1:]
            # # if last character is a double quote, remove it
            # if result[-1] == "\"":
            #     result = result[:-1]
            
            print(result)
        else:
            print("Calling OpenAI")
            # Create a new context and invoke the description function
            context: Any = kernel.create_new_context()
            context["name"] = name
            context["tags"] = tags
            result: str = await descriptionFunction.invoke_async(context=context)
            if "error" in str(result).lower():
                return Response(content=str(result), status_code=status.HTTP_401_UNAUTHORIZED)
            print(result)
            result = str(result).replace("\n", "")

        # Return the description as a JSON response
        return JSONResponse(content={"description": result}, status_code=status.HTTP_200_OK)
    except Exception as e:
        # Return an error message as a JSON response
        return JSONResponse(content={"error": str(e)}, status_code=status.HTTP_400_BAD_REQUEST)