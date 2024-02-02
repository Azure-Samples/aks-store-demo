#!/bin/bash

echo "Retrieving cluster credentials"
az aks get-credentials --resource-group ${AZURE_RESOURCEGROUP_NAME} --name ${AZURE_AKS_CLUSTER_NAME}

# echo "Deploy the manifests"
# kubectl apply -f manifests/

echo "Deploy Helm chart"
helm upgrade aks-store-demo ./charts/aks-store-demo \
  --install \
  --set aiService.create=true \
  --set aiService.modelDeploymentName=${AZURE_OPENAI_MODEL_NAME} \
  --set aiService.openAiEndpoint=${AZURE_OPENAI_ENDPOINT} \
  --set aiService.managedIdentityClientId=${AZURE_IDENTITY_CLIENT_ID} \
  --set orderService.useAzureServiceBus=true \
  --set orderService.queueHost=${AZURE_SERVICE_BUS_HOST} \
  --set orderService.queuePort=5671 \
  --set orderService.queueUsername=${AZURE_SERVICE_BUS_SENDER_NAME} \
  --set orderService.queuePassword=$(az keyvault secret show --name ${AZURE_SERVICE_BUS_SENDER_KEY} --vault-name ${AZURE_KEY_VAULT_NAME} --query value -o tsv) \
  --set orderService.queueTransport=tls \
  --set makelineService.useAzureCosmosDB=true \
  --set makelineService.orderQueueUri=${AZURE_SERVICE_BUS_URI} \
  --set makelineService.orderQueueUsername=${AZURE_SERVICE_BUS_LISTENER_NAME} \
  --set makelineService.orderQueuePassword=$(az keyvault secret show --name ${AZURE_SERVICE_BUS_LISTENER_KEY} --vault-name ${AZURE_KEY_VAULT_NAME} --query value -o tsv) \
  --set makelineService.orderDBUri=${AZURE_COSMOS_DATABASE_URI} \
  --set makelineService.orderDBUsername=${AZURE_COSMOS_DATABASE_NAME} \
  --set makelineService.orderDBPassword=$(az keyvault secret show --name ${AZURE_COSMOS_DATABASE_KEY} --vault-name ${AZURE_KEY_VAULT_NAME} --query value -o tsv) \
  