"""
Description generation API endpoint.
"""
import os
import logging
from typing import List
from openai import AzureOpenAI, OpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

logger = logging.getLogger(__name__)

# Define the system prompt
SYSTEM_PROMPT = (
    "You are a helpful assistant that generates product descriptions "
    "using a witty and engaging tone, but make sure to not include any "
    "of the tags or the product name in the description."
)

# Define the user prompt template
USER_PROMPT_TEMPLATE = (
    "Generate a product description for the product '{name}' "
    "with the following tags: '{tags}'."
)

class DescriptionRequest(BaseModel):
    """Request model for the description generation endpoint."""
    name: str
    tags: List[str]

# Create router with prefix
description = APIRouter(
    prefix="/generate",
    tags=["generation"]
)

def _create_completion(client, model, prompt, system_prompt=SYSTEM_PROMPT):
    """Create a chat completion using the provided client and model"""
    return client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt},
        ],
        temperature=0,
    )

def _handle_local_llm(user_prompt):
    """Handle local LLM completion"""
    logger.info("Using local LLM")

    local_llm_endpoint = os.environ.get("LOCAL_LLM_ENDPOINT")
    if not local_llm_endpoint:
        raise ValueError("LOCAL_LLM_ENDPOINT must be provided")

    client = OpenAI(
        api_key="EMPTY",
        base_url=local_llm_endpoint,
    )

    models = client.models.list()
    model = models.data[0].id

    response = _create_completion(client, model, user_prompt)
    return response.choices[0].message.content

def _handle_openai(user_prompt):
    """Handle OpenAI completion"""
    api_key = os.environ.get("OPENAI_API_KEY")
    org_id = os.environ.get("OPENAI_ORG_ID")

    if not api_key or not org_id:
        raise ValueError("OPENAI_API_KEY and OPENAI_ORG_ID must be provided")

    logger.info("Using OpenAI")

    client = OpenAI(
        api_key=api_key,
        organization=org_id,
    )
    response = _create_completion(client, "gpt-3.5-turbo", user_prompt)
    return response.choices[0].message.content

def _handle_azure_openai(user_prompt, use_azure_ad):
    """Handle Azure OpenAI completion"""
    deployment = os.environ.get("AZURE_OPENAI_DEPLOYMENT_NAME")
    endpoint = os.environ.get("AZURE_OPENAI_ENDPOINT")

    logger.info("Using Azure OpenAI: %s at %s", deployment, endpoint)

    if not deployment or not endpoint:
        raise ValueError(
            "AZURE_OPENAI_DEPLOYMENT_NAME and AZURE_OPENAI_ENDPOINT must be provided"
        )

    api_version = os.environ.get("AZURE_OPENAI_API_VERSION", "2024-02-15-preview")

    if use_azure_ad:
        logger.info("Using Microsoft Entra authentication")
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
        logger.info("Using API key authentication")

        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY must be provided")

        client = AzureOpenAI(
            api_version=api_version,
            azure_endpoint=endpoint,
            api_key=api_key,
        )

    response = _create_completion(client, deployment, user_prompt)
    return response.choices[0].message.content

@description.post("/description", operation_id="generate_description")
async def generate_description(request: DescriptionRequest):
    """
    Generate a product description based on the product name and tags
    """
    try:
        # Format the user prompt with the product name and tags
        user_prompt = USER_PROMPT_TEMPLATE.format(
            name=request.name,
            tags=", ".join(request.tags)
        )

        env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), ".env")
        if os.path.exists(env_path):
            logger.info("Loading environment from: %s", env_path)
            load_dotenv(dotenv_path=env_path, override=True)

        use_local_llm = os.environ.get("USE_LOCAL_LLM", "False").lower() == "true"
        use_azure = os.environ.get("USE_AZURE_OPENAI", "False").lower() == "true"
        use_azure_ad = os.environ.get("USE_AZURE_AD", "False").lower() == "true"

        if use_local_llm:
            description_text = _handle_local_llm(user_prompt)
        elif not use_azure:
            description_text = _handle_openai(user_prompt)
        else:
            description_text = _handle_azure_openai(user_prompt, use_azure_ad)

        return {"description": description_text}
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error generating description: {str(e)}"
        ) from e
