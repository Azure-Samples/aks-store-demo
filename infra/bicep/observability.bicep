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

resource grafanaDashboard 'Microsoft.Dashboard/grafana@2023-09-01' = {
  name: 'grafana-${nameSuffix}'
  location: location
  sku: {
    name: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    grafanaMajorVersion: '11'
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: [
        {
          azureMonitorWorkspaceResourceId: metricsWorkspace.id
        }
      ]
    }
  }
  tags: tags
}

resource grafanaAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, currentUserObjectId, 'Grafana Admin')
  scope: grafanaDashboard
  properties: {
    principalId: currentUserObjectId
    principalType: 'User'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '22926164-76b3-42b3-bc55-97df8dab3e41')
  }
}

output logsWorkspaceResourceId string = logWorkspace.id
output metricsWorkspaceResourceId string = metricsWorkspace.id
