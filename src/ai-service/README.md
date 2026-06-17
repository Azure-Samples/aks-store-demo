# ai-service

This is a FastAPI app that provides an API for interacting with OpenAI models using [Semantic Kernel SDK](https://github.com/microsoft/semantic-kernel). It is meant to be used in conjunction with the [store-admin](../store-admin) app.

## Running the app locally

The app does not rely on any other services other than OpenAI or Azure OpenAI endpoints, so you can run it locally without any other services running.

### Prerequisites

- [Python3](https://www.python.org/downloads/)
- [pip](https://pip.pypa.io/en/stable/installation/)
- [OpenAI API Key](https://beta.openai.com/docs/developer-quickstart/your-api-keys)
- [Azure OpenAI API Key](https://azure.microsoft.com/products/cognitive-services/openai-service/)

### Running the app

To run the app, clone the repo, open a terminal, and navigate to the `ai-service` directory. Then run the following commands:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip3 install -r requirements.txt

export USE_AZURE_OPENAI=True # set to False if you are not using Azure OpenAI
export USE_AZURE_AD=False # set to True if you are using Azure OpenAI with Azure AD authentication
export AZURE_OPENAI_API_VERSION=2024-12-01-preview # set to the version of the Azure OpenAI API you are using https://learn.microsoft.com/azure/ai-services/openai/reference#rest-api-versioning
export AZURE_OPENAI_DEPLOYMENT_NAME=gpt-5.4-mini # required if using Azure OpenAI
export AZURE_OPENAI_ENDPOINT=https://<your-resource>.cognitiveservices.azure.com/ # required if using Azure OpenAI
export AZURE_OPENAI_API_KEY=<your-azure-openai-key> # required if using key auth; not required with USE_AZURE_AD=True

export AZURE_OPENAI_IMAGE_API_VERSION=2025-04-01-preview # required if using Azure OpenAI image models such as gpt-image-2
export AZURE_OPENAI_IMAGE_ENDPOINT=https://<your-resource>.cognitiveservices.azure.com/ # optional override; defaults to AZURE_OPENAI_ENDPOINT
export AZURE_OPENAI_IMAGE_DEPLOYMENT_NAME=gpt-image-2 # required if using Azure OpenAI image generation

export OPENAI_API_KEY=<your-openai-key> # required if using OpenAI; optional fallback when using Azure OpenAI key auth
export OPENAI_ORG_ID= # required if using OpenAI
export USE_LOCAL_LLM=False # set to True if you are using a local KAITO LLM model
export LOCAL_LLM_ENDPOINT= # optional if using a local KAITO LLM model (ex: http://<A_REACHABLE_IP>/v1)
export LOCAL_LLM_MODEL= # optional if using a local KAITO LLM model (ex: phi-4-mini)
export TEMPERATURE=0.7 # optional (default 1.0), set the temperature for the generated descriptions

uvicorn main:app --host 127.0.0.1 --port 5001
```

When the app is running, you should see output similar to the following:

```text
INFO:     Started server process [134031]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:5001 (Press CTRL+C to quit)
```

Using the [`test-ai-service.http`](./test-ai-service.http) file in the root of the repo, you can test the API. However, you will need to use VS Code and have the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension installed.
