#!/usr/bin/env pwsh

Write-Host "Ensuring providers/features are registered and Azure CLI extensions are installed"

az provider register --namespace "Microsoft.ContainerService"
while ((az provider show --namespace "Microsoft.ContainerService" --query "registrationState" -o tsv) -ne "Registered") {
  Write-Host "Waiting for Microsoft.ContainerService provider registration..."
  Start-Sleep -Seconds 3
}

az provider register --namespace "Microsoft.KeyVault"
while ((az provider show --namespace "Microsoft.KeyVault" --query "registrationState" -o tsv) -ne "Registered") {
  Write-Host "Waiting for Microsoft.KeyVault provider registration..."
  Start-Sleep -Seconds 3
}

az provider register --namespace "Microsoft.CognitiveServices"
while ((az provider show --namespace "Microsoft.CognitiveServices" --query "registrationState" -o tsv) -ne "Registered") {
  Write-Host "Waiting for Microsoft.CognitiveServices provider registration..."
  Start-Sleep -Seconds 3
}

az provider register --namespace "Microsoft.ServiceBus"
while ((az provider show --namespace "Microsoft.ServiceBus" --query "registrationState" -o tsv) -ne "Registered") {
  Write-Host "Waiting for Microsoft.ServiceBus provider registration..."
  Start-Sleep -Seconds 3
}

az provider register --namespace "Microsoft.DocumentDB"
while ((az provider show --namespace "Microsoft.DocumentDB" --query "registrationState" -o tsv) -ne "Registered") {
  Write-Host "Waiting for Microsoft.DocumentDB provider registration..."
  Start-Sleep -Seconds 3
}

az provider register --namespace "Microsoft.OperationalInsights"
while ((az provider show --namespace "Microsoft.OperationalInsights" --query "registrationState" -o tsv) -ne "Registered") {
  Write-Host "Waiting for Microsoft.OperationalInsights provider registration..."
  Start-Sleep -Seconds 3
}

az provider register --namespace "Microsoft.AlertsManagement"
while ((az provider show --namespace "Microsoft.AlertsManagement" --query "registrationState" -o tsv) -ne "Registered") {
  Write-Host "Waiting for Microsoft.AlertsManagement provider registration..."
  Start-Sleep -Seconds 3
}

Write-Host "Ensuring preview features are registered"
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