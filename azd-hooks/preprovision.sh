#!/bin/bash

if ${AZURE_COSMOSDB_ACCOUNT_KIND} == "MongoDB" && ${DEPLOY_AZURE_WORKLOAD_IDENTITY} == "true"; then
  echo "Azure CosmosDB account kind cannot be MongoDB when deploying Azure Workload Identity"
  exit 1
fi

echo "Ensuring Azure CLI extensions and dependencies are installed"

az provider register --namespace "Microsoft.ContainerService"
while [[ $(az provider show --namespace "Microsoft.ContainerService" --query "registrationState" -o tsv) != "Registered" ]]; do
  echo "Waiting for Microsoft.ContainerService provider registration..."
  sleep 3
done

az feature register --namespace "Microsoft.ContainerService" --name "NetworkObservabilityPreview"
while [[ $(az feature show --namespace "Microsoft.ContainerService" --name "NetworkObservabilityPreview" --query "properties.state" -o tsv) != "Registered" ]]; do
  echo "Waiting for NetworkObservabilityPreview feature registration..."
  sleep 3
done

az feature register --namespace "Microsoft.ContainerService" --name "NodeOsUpgradeChannelPreview"
while [[ $(az feature show --namespace "Microsoft.ContainerService" --name "NodeOsUpgradeChannelPreview" --query "properties.state" -o tsv) != "Registered" ]]; do
  echo "Waiting for NodeOsUpgradeChannelPreview feature registration..."
  sleep 3
done

az feature register --namespace "Microsoft.ContainerService" --name "AzureMonitorMetricsControlPlanePreview"
while [[ $(az feature show --namespace "Microsoft.ContainerService" --name "AzureMonitorMetricsControlPlanePreview" --query "properties.state" -o tsv) != "Registered" ]]; do
  echo "Waiting for AzureMonitorMetricsControlPlanePreview feature registration..."
  sleep 3
done

# propagate the feature registrations
az provider register -n Microsoft.ContainerService

# add azure cli extensions
az extension add --upgrade --name aks-preview
az extension add --upgrade --name amg