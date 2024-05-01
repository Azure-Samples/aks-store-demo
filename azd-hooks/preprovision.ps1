#!/usr/bin/env pwsh

Write-Host "Ensuring Azure CLI extensions and dependencies are installed"

az provider register --namespace "Microsoft.ContainerService"
while ((az provider show --namespace "Microsoft.ContainerService" --query "registrationState" -o tsv) -ne "Registered") {
  Write-Host "Waiting for Microsoft.ContainerService provider registration..."
  Start-Sleep -Seconds 3
}

az feature register --namespace "Microsoft.ContainerService" --name "NetworkObservabilityPreview"
while ((az feature show --namespace "Microsoft.ContainerService" --name "NetworkObservabilityPreview" --query "properties.state" -o tsv) -ne "Registered") {
  Write-Host "Waiting for NetworkObservabilityPreview feature registration..."
  Start-Sleep -Seconds 3
}

az feature register --namespace "Microsoft.ContainerService" --name "NodeOsUpgradeChannelPreview"
while ((az feature show --namespace "Microsoft.ContainerService" --name "NodeOsUpgradeChannelPreview" --query "properties.state" -o tsv) -ne "Registered") {
  Write-Host "Waiting for NodeOsUpgradeChannelPreview feature registration..."
  Start-Sleep -Seconds 3
}

az feature register --namespace "Microsoft.ContainerService" --name "AzureMonitorMetricsControlPlanePreview" 
while ((az feature show --namespace "Microsoft.ContainerService" --name "AzureMonitorMetricsControlPlanePreview" --query "properties.state" -o tsv) -ne "Registered") {
  Write-Host "Waiting for AzureMonitorMetricsControlPlanePreview feature registration..."
  Start-Sleep -Seconds 3
}

# propagate the feature registrations
az provider register -n Microsoft.ContainerService

# add azure cli extensions
az extension add --upgrade --name aks-preview
az extension add --upgrade --name amg