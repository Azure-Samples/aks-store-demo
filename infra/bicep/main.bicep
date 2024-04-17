targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param k8s_namespace string = 'pets'
param resourceGroupName string = ''
param openAiServiceName string = ''
param openAiModelName string = 'gpt-35-turbo'
param identityName string = ''
param kubernetesName string = ''
param keyVaultName string = ''
param servicebusName string = ''
param logAnalyticsName string = ''
param monitorAccountName string = ''
param containerRegistryName string = ''

@description('Deploy an Azure Container Registry or not')
param deployAcr bool = false

@allowed([
  'MongoDB'
  'GlobalDocumentDB'
])
param cosmosdbAccountKind string = 'MongoDB'

@description('Id of the user or app to assign application roles')
param principalId string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// the node pool base configuration
var nodePoolBase = {
  name: 'system'
  count: 3
  vmSize: 'Standard_D4s_v4'
}

// the openai deployments to create
var openAiDeployment = [
  {
    name: openAiModelName
    sku: {
      name: 'Standard'
      capacity: 30
    }
    model: {
      format: 'OpenAI'
      name: openAiModelName
      version: '0613'
    }
  }
]

// organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// create the openai resources
module openAi './core/ai/cognitiveservices.bicep' = {
  name: 'openai'
  scope: rg
  params: {
    name: !empty(openAiServiceName) ? openAiServiceName : '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: location
    tags: tags
    deployments: openAiDeployment
  }
}

// create the identity and assign roles
module identity './app/identity.bicep' = {
  name: 'identity'
  scope: rg
  params: {
    name: !empty(identityName) ? identityName : '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
    AZURE_AKS_NAMESPACE: k8s_namespace
    clusterName: kubernetes.outputs.clusterName
  }
}

// create the kunbernetes cluster
module kubernetes './app/aks-managed-cluster.bicep' = {
  name: 'kubernetes'
  scope: rg
  params: {
    name: !empty(kubernetesName) ? kubernetesName : '${abbrs.containerServiceManagedClusters}${resourceToken}'
    location: location
    tags: tags
    networkPlugin: 'kubenet'
    systemPoolConfig: union(
      { name: 'npsystem', mode: 'System' },
      nodePoolBase
    )
    dnsPrefix: !empty(kubernetesName) ? kubernetesName : '${abbrs.containerServiceManagedClusters}${resourceToken}'
  }
}

// store secrets in a keyvault
module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

// create the cosmosdb
module cosmos './app/db.bicep' = {
  name: 'cosmos'
  scope: rg
  params: {
    resourceToken: resourceToken
    location: location
    tags: tags
    kind: cosmosdbAccountKind
    keyVaultName: keyVault.outputs.name
  }
}


// create the service bus
module serviceBus './app/servicebus.bicep' = {
  name: 'servicebus'
  scope: rg
  params: {
    name: !empty(servicebusName) ? servicebusName : '${abbrs.serviceBusNamespaces}${resourceToken}'
    location: location
    tags: tags
    keyVaultName: keyVault.outputs.name
  }
}

// get keys from the openAi and cosmosdb
module getKeys './app/get-keys.bicep' = {
  name: 'get-keys'
  scope: rg
  params:{
    keyVaultName: keyVault.outputs.name
    openAiName: openAi.outputs.name
    cosmosAccountName: cosmos.outputs.name
  }
}

// create the monitor workspace
module monitor './app/monitor.bicep' = {
  name: 'monitor'
  scope: rg
  params: {
    name: !empty(monitorAccountName) ? monitorAccountName : 'amon-${resourceToken}'
    location: location
    tags: tags
  }
}

// create the log analytics workspace
module logAnalytics './core/monitor/loganalytics.bicep' = {
  name: 'log-analytics'
  scope: rg
  params: {
    name: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    location: location
    tags: tags
  }
}

// create observability
module observability './app/observability.bicep' = {
  name: 'observability'
  scope: rg
  params: {
    name: 'amg-${resourceToken}'
    principalId: principalId
    clusterId: kubernetes.outputs.clusterId
    clusterName: kubernetes.outputs.clusterName
    logAnalyticsName: logAnalytics.outputs.name
    logAnalyticsId: logAnalytics.outputs.id
    monitorName: monitor.outputs.name
    monitorId: monitor.outputs.id
    location: location
    tags: tags
  }
}

// create the container if the deployAcr is true
module containerRegistry './core/host/container-registry.bicep' = if(deployAcr) {
  name: 'container-registry'
  scope: rg
  params: {
    name: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'Premium'
    }
  }
}

// acr pull role assignment
module acrPullRoleAssignment './core/security/registry-access.bicep' = if(deployAcr) {
  name: 'acr-pull-role-assignment'
  scope: rg
  params: {
    containerRegistryName: deployAcr ? containerRegistry.outputs.name : ''
    principalId: kubernetes.outputs.clusterIdentity.objectId
  }
}

// outputs data
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_AKS_CLUSTER_NAME string = kubernetes.outputs.clusterName
output AZURE_OPENAI_MODEL_NAME string = openAiModelName
output AZURE_OPENAI_ENDPOINT string = openAi.outputs.endpoint
output AZURE_IDENTITY_CLIENT_ID string = identity.outputs.clientId
output AZURE_SERVICE_BUS_HOST string = '${serviceBus.outputs.serviceBusNamespaceName}.servicebus.windows.net'
output AZURE_SERVICE_BUS_URI string = 'amqps://${serviceBus.outputs.serviceBusNamespaceName}.servicebus.windows.net'
output AZURE_SERVICE_BUS_LISTENER_NAME string = serviceBus.outputs.serviceBusListenerName
output AZURE_SERVICE_BUS_LISTENER_KEY string = serviceBus.outputs.serviceBusListenerKey
output AZURE_SERVICE_BUS_SENDER_NAME string = serviceBus.outputs.serviceBusSenderName
output AZURE_SERVICE_BUS_SENDER_KEY string = serviceBus.outputs.serviceBusSenderKey
output AZURE_COSMOS_DATABASE_NAME string = cosmos.outputs.name
output AZURE_COSMOS_DATABASE_URI string = cosmos.outputs.endpoint
output AZURE_COSMOS_DATABASE_KEY string = getKeys.outputs.cosmosKey
output AZURE_AKS_NAMESPACE string = k8s_namespace
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output AZURE_DATABASE_API string = cosmosdbAccountKind == 'MongoDB' ? 'mongodb': 'cosmosdbsql'
output AZURE_REGISTRY_NAME string = deployAcr ? containerRegistry.outputs.name : ''
output AZURE_REGISTRY_URI string = deployAcr ? containerRegistry.outputs.loginServer : 'ghcr.io/azure-samples'
