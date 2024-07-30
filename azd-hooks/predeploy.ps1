#!/usr/bin/env pwsh

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
"@ | Out-File -Append custom-values.yaml
}

###########################################################
# Add base images
###########################################################
@"
namespace: ${env:AZURE_AKS_NAMESPACE}
productService:
  image:
    repository: ${env:AZURE_REGISTRY_URI}/aks-store-demo/product-service
storeAdmin:
  image:
    repository: ${env:AZURE_REGISTRY_URI}/aks-store-demo/store-admin
storeFront:
  image:
    repository: ${env:AZURE_REGISTRY_URI}/aks-store-demo/store-front
virtualCustomer:
  image:
    repository: ${env:AZURE_REGISTRY_URI}/aks-store-demo/virtual-customer
virtualWorker:
  image:
    repository: ${env:AZURE_REGISTRY_URI}/aks-store-demo/virtual-worker
"@ | Out-File -Append custom-values.yaml

###########################################################
# Add ai-service if Azure OpenAI endpoint is provided
###########################################################

if ($env:AZURE_OPENAI_ENDPOINT) {
@"
aiService:
  image:
      repository: ${env:AZURE_REGISTRY_URI}/aks-store-demo/ai-service
  create: true
  modelDeploymentName: ${env:AZURE_OPENAI_MODEL_NAME}
  openAiEndpoint: ${env:AZURE_OPENAI_ENDPOINT}
  useAzureOpenAi: if ($env:AZURE_OPENAI_ENDPOINT) { 'true' }
"@ | Out-File -Path custom-values.yaml -Append -Encoding utf8

  # If Azure identity does not exist, use the Azure OpenAI API key
  if (($env:AZURE_IDENTITY_CLIENT_ID -eq $null) -and ($env:AZURE_IDENTITY_NAME -eq $null)) {
    $openAiKey = az keyvault secret show --name $env:AZURE_OPENAI_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query value -o tsv
    @"
  openAiKey: $openAiKey
"@ | Out-File -Path custom-values.yaml -Append -Encoding utf8
  }
}

###########################################################
# Add order-service
###########################################################
@"
orderService:
  image:
    repository: ${env:AZURE_REGISTRY_URI}/aks-store-demo/order-service
"@ | Out-File -Path custom-values.yaml -Append -Encoding utf8

# Add Azure Service Bus to order-service if provided
if ($env:AZURE_SERVICE_BUS_HOST) {
@"
  queueHost: ${env:AZURE_SERVICE_BUS_HOST}
"@ | Out-File -Append custom-values.yaml

  # If Azure identity does not exists, use the Azure Service Bus credentials
  if (-not $env:AZURE_IDENTITY_CLIENT_ID -and -not $env:AZURE_IDENTITY_NAME) {
    $queuePassword = az keyvault secret show --name $env:AZURE_SERVICE_BUS_SENDER_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query value -o tsv
    @"
  queuePort: "5671"
  queueTransport: "tls"
  queueUsername: ${env:AZURE_SERVICE_BUS_SENDER_NAME}
  queuePassword: $queuePassword
"@ | Out-File -Path custom-values.yaml -Append -Encoding utf8
  }
}

###########################################################
# Add makeline-service
###########################################################
@"
makelineService:
  image:
    repository: ${env:AZURE_REGISTRY_URI}/aks-store-demo/makeline-service
"@ | Out-File -Path custom-values.yaml -Append -Encoding utf8

# Add Azure Service Bus to makeline-service if provided
if ($env:AZURE_SERVICE_BUS_URI) {
  # If Azure identity exists just set the Azure Service Bus Hostname
  if ($env:AZURE_IDENTITY_CLIENT_ID -and $env:AZURE_IDENTITY_NAME) {
    @"
    orderQueueHost: $($env:AZURE_SERVICE_BUS_HOST)
"@ | Out-File -Path custom-values.yaml -Append -Encoding utf8
  } else {
  $orderQueuePassword = az keyvault secret show --name $env:AZURE_SERVICE_BUS_LISTENER_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query value -o tsv
@"
  orderQueueUri: ${env:AZURE_SERVICE_BUS_URI}
  orderQueueUsername: ${env:AZURE_SERVICE_BUS_LISTENER_NAME}
  orderQueuePassword: $orderQueuePassword
"@ | Out-File -Path custom-values.yaml -Append -Encoding utf8
  }
}

# Add Azure Cosmos DB to makeline-service if provided
if ($env:AZURE_COSMOS_DATABASE_URI) {
  $orderDBPassword = az keyvault secret show --name $env:AZURE_COSMOS_DATABASE_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query value -o tsv
@"
  orderDBApi: ${env:AZURE_DATABASE_API}
  orderDBUri: ${env:AZURE_COSMOS_DATABASE_URI}
"@ | Out-File -Path custom-values.yaml -Append -Encoding utf8

# If Azure identity does not exists, use the Azure Cosmos DB credentials
  if (-not $env:AZURE_IDENTITY_CLIENT_ID -and -not $env:AZURE_IDENTITY_NAME) {
    $orderDBPassword = az keyvault secret show --name $env:AZURE_COSMOS_DATABASE_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query value -o tsv
    @"
  orderDBUsername: ${env:AZURE_COSMOS_DATABASE_NAME}
  orderDBPassword: $orderDBPassword
"@ | Out-File -Path custom-values.yaml -Append -Encoding utf8
  }
}

###########################################################
# Do not deploy RabbitMQ when using Azure Service Bus
###########################################################
if ($env:AZURE_SERVICE_BUS_HOST) {
  @"
useRabbitMQ: false
"@ | Out-File -Path custom-values.yaml -Append -Encoding utf8
}

###########################################################
# Do not deploy MongoDB when using Azure Cosmos DB
###########################################################
if ($env:AZURE_COSMOS_DATABASE_URI) {
  @"
useMongoDB: false
"@ | Out-File -Path custom-values.yaml -Append -Encoding utf8
}