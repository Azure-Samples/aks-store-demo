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
param k8s_namespace string = 'default'
param resourceGroupName string = ''
param openAiServiceName string = ''
param openAiModelName string = 'gpt-35-turbo'
param identityName string = ''
param kubernetesName string = ''
param keyVaultName string = ''
param cosmosAccountName string = ''
param cosmosDatabaseName string = 'orderdb'
param servicebusName string = ''

@description('Id of the user or app to assign application roles')
param principalId string = ''

@description('The collections to create in the database')
param collections array = [
  {
    id: 'orders'
    name: 'orders'
    shardKey: 'Hash'
    indexKey: '_id'
    throughput: 400
  }
]

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
      capacity: 60
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
    k8s_namespace: k8s_namespace
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

// the application database
module cosmos './core/database/cosmos/mongo/cosmos-mongo-db.bicep' = {
  name: 'cosmos-mongo'
  scope: rg
  params: {
    accountName: !empty(cosmosAccountName) ? cosmosAccountName : '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
    databaseName: cosmosDatabaseName
    location: location
    collections: collections
    tags: tags
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
  }
}

// get keys from the openAi and cosmosdb
module getKeys './app/get-keys.bicep' = {
  name: 'get-keys'
  scope: rg
  params:{
    openAiName: openAi.outputs.name
    cosmosAccountName: !empty(cosmosAccountName) ? cosmosAccountName : '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
  }
  dependsOn: [
    cosmos
  ]
}

// outputs data
output rg_name string = rg.name
output aks_name string = kubernetes.outputs.clusterName
output ai_model_name string = openAiModelName
output ai_endpoint string = openAi.outputs.endpoint
output ai_key string = getKeys.outputs.openAiKey
output ai_managed_identity_client_id string = identity.outputs.clientId
output sb_namespace_host string = '${serviceBus.outputs.serviceBusNamespaceName}.servicebus.windows.net'
output sb_namespace_uri string = 'amqps://${serviceBus.outputs.serviceBusNamespaceName}.servicebus.windows.net'
output sb_listener_username string = serviceBus.outputs.serviceBusListenerName
output sb_listener_key string = serviceBus.outputs.serviceBusListenerKey
output sb_sender_username string = serviceBus.outputs.serviceBusSenderName
output sb_sender_key string = serviceBus.outputs.serviceBusSenderKey
output db_account_name string = !empty(cosmosAccountName) ? cosmosAccountName : '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
output db_uri string = 'mongodb://${!empty(cosmosAccountName) ? cosmosAccountName : '${abbrs.documentDBDatabaseAccounts}${resourceToken}'}.mongo.cosmos.azure.com:10255/?retryWrites=false'
output db_key string = getKeys.outputs.dbKey
output k8s_namespace string = k8s_namespace
