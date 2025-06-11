#!/bin/bash

services=("ai-service" "makeline-service" "order-service" "product-service" "store-admin" "store-front" "virtual-customer" "virtual-worker")

if [ "$DEPLOY_AZURE_CONTAINER_REGISTRY" == "true" ] && [ "$BUILD_CONTAINERS" == "true" ]; then
  echo "Build container images"
  for service in "${services[@]}"; do
    echo "Building aks-store-demo/${service}:latest"
    az acr build --registry ${AZURE_REGISTRY_NAME} --image aks-store-demo/${service}:latest ./src/${service}/
  done
elif [ "$DEPLOY_AZURE_CONTAINER_REGISTRY" == "true" ] && ([ -z "$BUILD_CONTAINERS" ] || [ "$BUILD_CONTAINERS" == "false" ]); then
  echo "Import container images"
  # Default SOURCE_REGISTRY if empty or unset
  if [ -z "${SOURCE_REGISTRY}" ]; then
    SOURCE_REGISTRY="ghcr.io/azure-samples"
  fi

  for service in "${services[@]}"; do
    echo "Importing aks-store-demo/${service}:latest"
    az acr import \
      --name "${AZURE_REGISTRY_NAME}" \
      --source "${SOURCE_REGISTRY}/aks-store-demo/${service}:latest" \
      --image "aks-store-demo/${service}:latest"
  done
else 
  echo "No BUILD_CONTAINERS variable set, skipping container build/import"
fi
