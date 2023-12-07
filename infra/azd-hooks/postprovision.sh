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
