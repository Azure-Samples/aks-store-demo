#!/usr/bin/env pwsh

echo "Retrieving cluster credentials"
az aks get-credentials --resource-group $env:AZURE_RESOURCEGROUP_NAME --name $env:AZURE_AKS_CLUSTER_NAME --overwrite-existing

$makelineUseSqlApi = "false"
if ($env:AZURE_DATABASE_API -eq "cosmosdbsql") {
  $makelineUseSqlApi = "true"
}

echo "Deploy Helm chart"
helm upgrade aks-store-demo ./charts/aks-store-demo `
  --install `
  --set aiService.create=true `
  --set aiService.modelDeploymentName=$env:AZURE_OPENAI_MODEL_NAME `
  --set aiService.openAiEndpoint=$env:AZURE_OPENAI_ENDPOINT `
  --set aiService.managedIdentityClientId=$env:AZURE_IDENTITY_CLIENT_ID `
  --set aiService.image.repository=$env:AZURE_REGISTRY_URI/aks-store-demo/ai-service `
  --set orderService.useAzureServiceBus=true `
  --set orderService.queueHost=$env:AZURE_SERVICE_BUS_HOST `
  --set orderService.queuePort=5671 `
  --set orderService.queueUsername=$env:AZURE_SERVICE_BUS_SENDER_NAME `
  --set orderService.queuePassword=$(az keyvault secret show --name $env:AZURE_SERVICE_BUS_SENDER_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query value -o tsv) `
  --set orderService.queueTransport=tls `
  --set orderService.image.repository=$env:AZURE_REGISTRY_URI/aks-store-demo/order-service `
  --set makelineService.useAzureCosmosDB=true `
  --set makelineService.orderQueueUri=$env:AZURE_SERVICE_BUS_URI `
  --set makelineService.orderQueueUsername=$env:AZURE_SERVICE_BUS_LISTENER_NAME `
  --set makelineService.orderQueuePassword=$(az keyvault secret show --name $env:AZURE_SERVICE_BUS_LISTENER_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query value -o tsv) `
  --set makelineService.orderDBUri=$env:AZURE_COSMOS_DATABASE_URI `
  --set makelineService.orderDBUsername=$env:AZURE_COSMOS_DATABASE_NAME `
  --set makelineService.orderDBPassword=$(az keyvault secret show --name $env:AZURE_COSMOS_DATABASE_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query value -o tsv) `
  --set makelineService.image.repository=$env:AZURE_REGISTRY_URI/aks-store-demo/makeline-service `
  --set productService.image.repository=$env:AZURE_REGISTRY_URI/aks-store-demo/product-service `
  --set storeAdmin.image.repository=$env:AZURE_REGISTRY_URI/aks-store-demo/store-admin `
  --set storeFront.image.repository=$env:AZURE_REGISTRY_URI/aks-store-demo/store-front `
  --set virtualCustomer.image.repository=$env:AZURE_REGISTRY_URI/aks-store-demo/virtual-customer `
  --set virtualWorker.image.repository=$env:AZURE_REGISTRY_URI/aks-store-demo/virtual-worker `
  --set makelineService.useSqlApi=$makelineUseSqlApi
