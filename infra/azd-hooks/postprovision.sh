#!/bin/bash

services=("ai-service" "makeline-service" "order-service" "product-service" "store-admin" "store-front" "virtual-customer" "virtual-worker")

if [ -n "$BUILD_CONTAINERS" ] && [ "$BUILD_CONTAINERS" == "true" ]; then
  echo "Build container images"
  for service in "${services[@]}"; do
    echo "Building aks-store-demo/${service}:latest"
    az acr build --registry ${registry_name} --image aks-store-demo/${service}:latest ./src/${service}/
  done
else
  echo "Import container images"
  for service in "${services[@]}"; do
    echo "Importing aks-store-demo/${service}:latest"
    az acr import --name ${registry_name} --source ghcr.io/azure-samples/aks-store-demo/${service}:latest --image aks-store-demo/${service}:latest
  done
fi