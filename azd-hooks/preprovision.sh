#!/bin/bash

echo "Ensuring Azure CLI extensions and dependencies are installed"
az provider register --namespace Microsoft.ContainerService
az feature register --namespace Microsoft.ContainerService --name AKS-KedaPreview
az feature register --namespace Microsoft.ContainerService --name AKS-PrometheusAddonPreview
az feature register --namespace Microsoft.ContainerService --name EnableWorkloadIdentityPreview
az feature register --namespace Microsoft.ContainerService --name NetworkObservabilityPreview
az feature register --namespace "Microsoft.ContainerService" --name "NodeOsUpgradeChannelPreview"
az feature register --namespace "Microsoft.ContainerService" --name "AzureMonitorMetricsControlPlanePreview" 
az extension add --upgrade --name aks-preview
az extension add --upgrade --name amg