#!/usr/bin/env sh

azd config set alpha.aks.helm on
azd config set alpha.aks.kustomize on

echo "Ensuring providers/features are registered and Azure CLI extensions are installed"

az provider register --namespace "Microsoft.ContainerService"
while [ "$(az provider show --namespace "Microsoft.ContainerService" --query "registrationState" -o tsv)" != "Registered" ]; do
  echo "Waiting for Microsoft.ContainerService provider registration..."
  sleep 3
done

az provider register --namespace "Microsoft.KeyVault"
while [ "$(az provider show --namespace "Microsoft.KeyVault" --query "registrationState" -o tsv)" != "Registered" ]; do
  echo "Waiting for Microsoft.KeyVault provider registration..."
  sleep 3
done

az provider register --namespace "Microsoft.CognitiveServices"
while [ "$(az provider show --namespace "Microsoft.CognitiveServices" --query "registrationState" -o tsv)" != "Registered" ]; do
  echo "Waiting for Microsoft.CognitiveServices provider registration..."
  sleep 3
done

az provider register --namespace "Microsoft.ServiceBus"
while [ "$(az provider show --namespace "Microsoft.ServiceBus" --query "registrationState" -o tsv)" != "Registered" ]; do
  echo "Waiting for Microsoft.ServiceBus provider registration..."
  sleep 3
done

az provider register --namespace "Microsoft.DocumentDB"
while [ "$(az provider show --namespace "Microsoft.DocumentDB" --query "registrationState" -o tsv)" != "Registered" ]; do
  echo "Waiting for Microsoft.DocumentDB provider registration..."
  sleep 3
done

az provider register --namespace "Microsoft.OperationalInsights"
while [ "$(az provider show --namespace "Microsoft.OperationalInsights" --query "registrationState" -o tsv)" != "Registered" ]; do
  echo "Waiting for Microsoft.OperationalInsights provider registration..."
  sleep 3
done

az provider register --namespace "Microsoft.AlertsManagement"
while [ "$(az provider show --namespace "Microsoft.AlertsManagement" --query "registrationState" -o tsv)" != "Registered" ]; do
  echo "Waiting for Microsoft.AlertsManagement provider registration..."
  sleep 3
done

echo "Ensuring preview features are registered"
az feature register --namespace "Microsoft.ContainerService" --name "AzureMonitorMetricsControlPlanePreview"
while [ "$(az feature show --namespace "Microsoft.ContainerService" --name "AzureMonitorMetricsControlPlanePreview" --query "properties.state" -o tsv)" != "Registered" ]; do
  echo "Waiting for AzureMonitorMetricsControlPlanePreview feature registration..."
  sleep 3
done

# propagate the feature registrations
az provider register -n Microsoft.ContainerService

# add azure cli extensions
az extension add --upgrade --name aks-preview
az extension add --upgrade --name amg

# if BUILD_CONTAINERS is set to true, always set DEPLOY_AZURE_CONTAINER_REGISTRY to true
if [ "$BUILD_CONTAINERS" = "true" ]; then
  azd env set DEPLOY_AZURE_CONTAINER_REGISTRY true
fi
