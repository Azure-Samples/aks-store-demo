#!/usr/bin/env pwsh

##########################################################
# Ensure Helm and Kustomize support is enabled  
##########################################################
azd config set alpha.aks.helm on
azd config set alpha.aks.kustomize on

##########################################################
# Check kubelogin and install if not exists
##########################################################
if (-not (Get-Command kubelogin -ErrorAction SilentlyContinue)) {
  az aks install-cli
}

###########################################################
# Create the custom-values.yaml file
###########################################################
@"
namespace: ${env:AZURE_AKS_NAMESPACE}
"@ | Out-File -FilePath custom-values.yaml -Encoding utf8

###########################################################
# Add Azure Managed Identity and set to use AzureAD auth 
###########################################################
if (![string]::IsNullOrEmpty($env:AZURE_IDENTITY_CLIENT_ID) -and ![string]::IsNullOrEmpty($env:AZURE_IDENTITY_NAME)) {
@"
useAzureAd: true
managedIdentityName: $($env:AZURE_IDENTITY_NAME)
managedIdentityClientId: $($env:AZURE_IDENTITY_CLIENT_ID)
"@ | Out-File -FilePath custom-values.yaml -Append -Encoding utf8
}

###########################################################
# Add base images
###########################################################
@"
productService:
  image:
    repository: ${env:SOURCE_REGISTRY}/aks-store-demo/product-service
storeAdmin:
  image:
    repository: ${env:SOURCE_REGISTRY}/aks-store-demo/store-admin
storeFront:
  image:
    repository: ${env:SOURCE_REGISTRY}/aks-store-demo/store-front
virtualCustomer:
  image:
    repository: ${env:SOURCE_REGISTRY}/aks-store-demo/virtual-customer
virtualWorker:
  image:
    repository: ${env:SOURCE_REGISTRY}/aks-store-demo/virtual-worker
"@ | Out-File -FilePath custom-values.yaml -Append -Encoding utf8

###########################################################
# Add ai-service if Azure OpenAI endpoint is provided
###########################################################
if ($env:AZURE_OPENAI_ENDPOINT) {
@"
aiService:
  image:
      repository: ${env:SOURCE_REGISTRY}/aks-store-demo/ai-service
  create: true
  modelDeploymentName: ${env:AZURE_OPENAI_MODEL_NAME}
  openAiEndpoint: ${env:AZURE_OPENAI_ENDPOINT}
  useAzureOpenAi: true
"@ | Out-File -FilePath custom-values.yaml -Append -Encoding utf8

  # If DALL-E model endpoint and name exist
  if ($env:AZURE_OPENAI_DALL_E_ENDPOINT -and $env:AZURE_OPENAI_DALL_E_MODEL_NAME) {
@"
  openAiDalleEndpoint: ${env:AZURE_OPENAI_DALL_E_ENDPOINT}
  openAiDalleModelName: ${env:AZURE_OPENAI_DALL_E_MODEL_NAME}
"@ | Out-File -FilePath custom-values.yaml -Append -Encoding utf8
  }
}

###########################################################
# Add order-service
###########################################################
@"
orderService:
  image:
    repository: ${env:SOURCE_REGISTRY}/aks-store-demo/order-service
"@ | Out-File -FilePath custom-values.yaml -Append -Encoding utf8

# Add Azure Service Bus to order-service if provided
if ($env:AZURE_SERVICE_BUS_HOST) {
@"
  queueHost: ${env:AZURE_SERVICE_BUS_HOST}
"@ | Out-File -FilePath custom-values.yaml -Append -Encoding utf8
}

###########################################################
# Add makeline-service
###########################################################
@"
makelineService:
  image:
    repository: ${env:SOURCE_REGISTRY}/aks-store-demo/makeline-service
"@ | Out-File -FilePath custom-values.yaml -Append -Encoding utf8

# Add Azure Service Bus to makeline-service if provided
# (Parity with bash: check HOST presence and write HOST value)
if ($env:AZURE_SERVICE_BUS_HOST) {
@"
  orderQueueHost: ${env:AZURE_SERVICE_BUS_HOST}
"@ | Out-File -FilePath custom-values.yaml -Append -Encoding utf8
}

# Add Azure Cosmos DB to makeline-service if provided
if ($env:AZURE_COSMOS_DATABASE_URI) {
@"
  orderDBApi: ${env:AZURE_DATABASE_API}
  orderDBUri: ${env:AZURE_COSMOS_DATABASE_URI}
"@ | Out-File -FilePath custom-values.yaml -Append -Encoding utf8
}

###########################################################
# Do not deploy RabbitMQ when using Azure Service Bus
###########################################################
if ($env:AZURE_SERVICE_BUS_HOST) {
@"
useRabbitMQ: false
"@ | Out-File -FilePath custom-values.yaml -Append -Encoding utf8
}

###########################################################
# Do not deploy MongoDB when using Azure Cosmos DB
###########################################################
if ($env:AZURE_COSMOS_DATABASE_URI) {
@"
useMongoDB: false
"@ | Out-File -FilePath custom-values.yaml -Append -Encoding utf8
}