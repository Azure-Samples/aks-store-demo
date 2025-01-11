from typing import Any, List, Dict
from fastapi import APIRouter, Request, status
from fastapi.responses import Response, JSONResponse
import requests
import json
import os
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

            temperature = 1.0
            top_p = 1
            max_length = 200
            repetition_penalty = 1.0
            length_penalty = 1.0

            # if url ends with v1/chat/completions then use openai 
            if endpoint.endswith("v1/chat/completions"):
                model_name = os.getenv("MODEL_NAME")
                if not model_name:
                    raise ValueError("MODEL_NAME environment variable is not set or is empty")
                
                prompt = f"Describe this pet store product using joyful, playful, and enticing language.\nProduct name: {name}\ntags: {tags}\""
                payload = {
                    "model": model_name,
                    "messages": [
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ],
                    "temperature": temperature,
                    "top_p": top_p,
                    # "max_tokens": max_length,
                    "length_penalty": length_penalty,
                    "repetition_penalty": repetition_penalty
                }

                headers = {"Content-Type": "application/json"}
                response = requests.request("POST", endpoint, headers=headers, json=payload)            
                
                # convert response.text to json
                result = json.loads(response.content)
                result = result["choices"][0]["message"]["content"]
            else:
                prompt = f"<|user|>Describe this pet store product using joyful, playful, and enticing language.\nProduct name: {name}\ntags: {tags}<|end|><|assistant|>\""
                
                payload = {
                    "prompt": prompt,
                    "return_full_text": "false",
                    "clean_up_tokenization_spaces": "true",
                    "generate_kwargs": {
                        "temperature": temperature,
                        "max_length": max_length,
                        "repetition_penalty": repetition_penalty,
                        "top_p": top_p
                    }
                }
                
                headers = {"Content-Type": "application/json"}
                response = requests.request("POST", endpoint, headers=headers, json=payload)            
                
                # convert response.text to json
                result = json.loads(response.content)
                result = result["Result"]
            
            # remove all double quotes
            if "\"" in result:
                result = result.replace("\"", "")

            # remove all leading and trailing whitespace
            result = result.strip()

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