@minLength(3)
param nameSuffix string
param vmSku string
param deployAcr bool
param monitoringWorkspaceResourceId string
param currentUserObjectId string

// https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/container-registry/registry
module registry 'br/public:avm/res/container-registry/registry:0.9.1' = if (deployAcr) {
  name: 'registryDeployment'
  params: {
    name: 'acr${nameSuffix}'
  }
}

// https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/container-service/managed-cluster
module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.8.3' = {
  name: 'managedClusterDeployment'
  params: {
    name: 'aks-${nameSuffix}'
    primaryAgentPoolProfiles: [
      {
        mode: 'System'
        name: 'system'
        vmSize: vmSku
        count: 3
        maxSurge: '10%'
      }
    ]
    aadProfile: {
      aadProfileEnableAzureRBAC: true
      aadProfileManaged: true
    }
    managedIdentities: {
      systemAssigned: true
    }
    networkPlugin: 'azure'
    networkPluginMode: 'overlay'
    networkPolicy: 'cilium'
    networkDataplane: 'cilium'
    autoNodeOsUpgradeProfileUpgradeChannel: 'SecurityPatch'
    enableOidcIssuerProfile: true
    enableWorkloadIdentity: true
    enableKeyvaultSecretsProvider: true
    enableAzureMonitorProfileMetrics: true
    enableContainerInsights: monitoringWorkspaceResourceId != '' ? true : false
    monitoringWorkspaceResourceId: monitoringWorkspaceResourceId
  }
}

var clusterAdminRoleDefinitionId = 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
resource clusterAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, currentUserObjectId, clusterAdminRoleDefinitionId)
  properties: {
    principalId: currentUserObjectId
    principalType: 'User'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', clusterAdminRoleDefinitionId)
  }
}

var acrPullRoleDefinitionId = 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, acrPullRoleDefinitionId)
  properties: {
    principalId: managedCluster.outputs.?kubeletIdentityObjectId!
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleDefinitionId)
  }
}

output id string = managedCluster.outputs.resourceId
output name string = managedCluster.outputs.name
output oidcIssuerUrl string = managedCluster.outputs.?oidcIssuerUrl!
output registryName string = registry.outputs.resourceId
output registryLoginServer string = registry.outputs.loginServer
