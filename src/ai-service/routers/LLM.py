from azure.identity import DefaultAzureCredential
import semantic_kernel as sk
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion, OpenAIChatCompletion
from dotenv import load_dotenv
import os


def get_llm():
    """ Function to initialize the LLM so that it can be used in the app """
    # Set the useLocalLLM and useAzureOpenAI variables based on environment variables
    useLocalLLM: bool = False
    useAzureOpenAI: bool = False
    kernel = False
    endpoint: str = ''
    
    if os.environ.get("USE_LOCAL_LLM"):
        useLocalLLM = os.environ.get("USE_LOCAL_LLM").lower() == "true"

    if os.environ.get("USE_AZURE_OPENAI"):
        useAzureOpenAI = os.environ.get("USE_AZURE_OPENAI").lower() == "true"

    # if useLocalLLM and useAzureOpenAI are both set to true, raise an exception
    if useLocalLLM and useAzureOpenAI:
        raise Exception("USE_LOCAL_LLM and USE_AZURE_OPENAI environment variables cannot both be set to true")

    # if useLocalLLM or useAzureOpenAI are set to true, get the endpoint from the environment variables
    if useLocalLLM or useAzureOpenAI:
        endpoint = os.environ.get("AI_ENDPOINT") or os.environ.get("AZURE_OPENAI_ENDPOINT")
        
        if isinstance(endpoint, str) == False or endpoint == "":
            raise Exception("AI_ENDPOINT or AZURE_OPENAI_ENDPOINT environment variable must be set when USE_LOCAL_LLM or USE_AZURE_OPENAI is set to true")

    # if not using local LLM, set up the semantic kernel
    if useLocalLLM:
        print("Using Local LLM")
    else:
        print("Using OpenAI and setting up Semantic Kernel")
        # Load environment variables from .env file
        load_dotenv()

        # Initialize the semantic kernel
        kernel: sk.Kernel = sk.Kernel()

        kernel = sk.Kernel()
            
        # Get the Azure OpenAI deployment name, API key, and endpoint or OpenAI org id from environment variables
        api_key: str = os.environ.get("OPENAI_API_KEY")
        useAzureAD: str = os.environ.get("USE_AZURE_AD")

        if (isinstance(api_key, str) == False or api_key == "") and (isinstance(useAzureAD, str) == False or useAzureAD == ""):
            raise Exception("OPENAI_API_KEY environment variable must be set")

        if not useAzureOpenAI:
            org_id = os.environ.get("OPENAI_ORG_ID")
            if isinstance(org_id, str) == False or org_id == "":
                raise Exception("OPENAI_ORG_ID environment variable must be set when USE_AZURE_OPENAI is set to False")
            # Add the OpenAI text completion service to the kernel
            kernel.add_chat_service("dv", OpenAIChatCompletion("gpt-3.5-turbo", api_key, org_id))

        else:
            deployment: str = os.environ.get("AZURE_OPENAI_DEPLOYMENT_NAME")
            # Add the Azure OpenAI text completion service to the kernel
            if isinstance(useAzureAD, str) == True and useAzureAD.lower() == "true":
                print("Authenticating to Azure OpenAI with Azure AD Workload Identity")
                credential = DefaultAzureCredential()
                access_token = credential.get_token("https://cognitiveservices.azure.com/.default")
                kernel.add_chat_service("dv", AzureChatCompletion(deployment_name=deployment, endpoint=endpoint, ad_token=access_token.token))
            else:
                print("Authenticating to Azure OpenAI with OpenAI API key")
                kernel.add_chat_service("dv", AzureChatCompletion(deployment_name=deployment, endpoint=endpoint, api_key=api_key))
    return kernel, useLocalLLM, endpoint
