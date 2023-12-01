#!/bin/bash

echo "Build container images"
az acr build --registry ${registry_name} --image aks-store-demo/ai-service:latest ./src/ai-service/
az acr build --registry ${registry_name} --image aks-store-demo/makeline-service:latest ./src/makeline-service/
az acr build --registry ${registry_name} --image aks-store-demo/order-service:latest ./src/order-service/
az acr build --registry ${registry_name} --image aks-store-demo/product-service:latest ./src/product-service/
az acr build --registry ${registry_name} --image aks-store-demo/store-admin:latest ./src/store-admin/
az acr build --registry ${registry_name} --image aks-store-demo/store-front:latest ./src/store-front/
az acr build --registry ${registry_name} --image aks-store-demo/virtual-customer:latest ./src/virtual-customer/
az acr build --registry ${registry_name} --image aks-store-demo/virtual-worker:latest ./src/virtual-worker/

echo "Retrieving cluster credentials"
az aks get-credentials --resource-group ${rg_name} --name ${aks_name}

echo "Deploy Helm chart"
helm upgrade aks-store-demo ./charts/aks-store-demo \
  --install \
  --set aiService.create=true \
  --set aiService.modelDeploymentName=${ai_model_name} \
  --set aiService.openAiEndpoint=${ai_endpoint} \
  --set aiService.managedIdentityClientId=${ai_managed_identity_client_id} \
  --set aiService.image.repository=${registry_uri}/aks-store-demo/ai-service \
  --set orderService.useAzureServiceBus=true \
  --set orderService.queueHost=${sb_namespace_host} \
  --set orderService.queuePort=5671 \
  --set orderService.queueUsername=${sb_sender_username} \
  --set orderService.queuePassword=${sb_sender_key} \
  --set orderService.queueTransport=tls \
  --set orderService.image.repository=${registry_uri}/aks-store-demo/order-service \
  --set makelineService.useAzureCosmosDB=true \
  --set makelineService.orderQueueUri=${sb_namespace_uri} \
  --set makelineService.orderQueueUsername=${sb_listener_username} \
  --set makelineService.orderQueuePassword=${sb_listener_key} \
  --set makelineService.orderDBUri=${db_uri} \
  --set makelineService.orderDBUsername=${db_account_name} \
  --set makelineService.orderDBPassword=${db_key} \
  --set makelineService.image.repository=${registry_uri}/aks-store-demo/makeline-service \
  --set productService.image.repository=${registry_uri}/aks-store-demo/product-service \
  --set storeAdmin.image.repository=${registry_uri}/aks-store-demo/store-admin \
  --set storeFront.image.repository=${registry_uri}/aks-store-demo/store-front \
  --set virtualCustomer.image.repository=${registry_uri}/aks-store-demo/virtual-customer \
  --set virtualWorker.image.repository=${registry_uri}/aks-store-demo/virtual-worker
