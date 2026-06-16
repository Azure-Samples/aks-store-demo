@description('The basename of the resource.')
param nameSuffix string
@description('The location of the resource.')
param location string = resourceGroup().location
param currentUserObjectId string
param tags object

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'logs-${nameSuffix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
  tags: tags
}

resource metricsWorkspace 'Microsoft.Monitor/accounts@2023-04-03' = {
  name: 'metrics-${nameSuffix}'
  location: location
  tags: tags
}

output logsWorkspaceResourceId string = logWorkspace.id
output metricsWorkspaceResourceId string = metricsWorkspace.id
