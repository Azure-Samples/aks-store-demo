#!/bin/bash

echo "Retrieving cluster credentials"
az aks get-credentials --resource-group ${rg_name} --name ${aks_name}

# echo "Deploy the manifests"
# kubectl apply -f manifests/

echo "Deploy Helm chart"
helm upgrade aks-store-demo ./charts/aks-store-demo \
  --install \
  --set aiService.create=true \
  --set aiService.modelDeploymentName=${ai_model_name} \
  --set aiService.openAiEndpoint=${ai_endpoint} \
  --set aiService.managedIdentityClientId=${ai_managed_identity_client_id} \
  --set orderService.useAzureServiceBus=true \
  --set orderService.queueHost=${sb_namespace_host} \
  --set orderService.queuePort=5671 \
  --set orderService.queueUsername=${sb_sender_username} \
  --set orderService.queuePassword=${sb_sender_key} \
  --set orderService.queueTransport=tls \
  --set makelineService.useAzureCosmosDB=true \
  --set makelineService.orderQueueUri=${sb_namespace_uri} \
  --set makelineService.orderQueueUsername=${sb_listener_username} \
  --set makelineService.orderQueuePassword=${sb_listener_key} \
  --set makelineService.orderDBUri=${db_uri} \
  --set makelineService.orderDBUsername=${db_account_name} \
  --set makelineService.orderDBPassword=${db_key} \
  