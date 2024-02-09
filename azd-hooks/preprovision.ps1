#!/usr/bin/env pwsh

echo "Ensuring Azure CLI extensions and dependencies are installed"
az provider register --namespace Microsoft.ContainerService
az feature register --namespace Microsoft.ContainerService --name AKS-KedaPreview
az feature register --namespace Microsoft.ContainerService --name AKS-PrometheusAddonPreview
az feature register --namespace Microsoft.ContainerService --name EnableWorkloadIdentityPreview
az feature register --namespace Microsoft.ContainerService --name NetworkObservabilityPreview
az extension add --upgrade --name aks-preview
az extension add --upgrade --name amg