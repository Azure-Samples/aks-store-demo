targetScope = 'subscription'

@description('value of the current user for rbac assignments')
param currentUserObjectId string

@minLength(1)
@description('value of azure location to deploy resources')
param location string

@minLength(3)
@maxLength(10)
@description('value of environment name which will be used to prefix resources')
param appEnvironment string

@description('value of azure kubernetes node pool vm size')
param aksNodePoolVMSize string = 'Standard_DS2_v2'

@description('value of the kubernetes namespace')
param k8sNamespace string = 'pets'

@description('value to determine if observability tools should be deployed')
param deployObservabilityTools bool = true

@description('value to determine if azure container registry should be deployed')
param deployAzureContainerRegistry bool = true

@description('value to determine if azure servicebus should be deployed')
param deployAzureServiceBus bool = true

@description('value to determine if azure cosmosdb should be deployed')
param deployAzureCosmosDB bool = true

@allowed(['GlobalDocumentDB', 'MongoDB'])
@description('value of azure cosmosdb account kind')
param cosmosDBAccountKind string = 'GlobalDocumentDB'

@description('value to determine if azure openai should be deployed')
param deployAzureOpenAI bool = true

@description('value of azure location for azure openai resources. defaults to location but you can override it')
param azureOpenAILocation string = location

@description('value of azure openai model name')
param chatCompletionModelName string = 'gpt-4o-mini'

@description('value of azure openai model version')
param chatCompletionModelVersion string = '2024-07-18'

@description('value of azure openai model capacity')
param chatCompletionModelCapacity int = 8

@description('value to determine if azure openai dall-e model should be deployed')
param deployImageGenerationModel bool = false

@description('value of azure openai dall-e model name')
param imageGenerationModelName string = 'dall-e-3'

@description('value of azure openai dall-e model version')
param imageGenerationModelVersion string = '3.0'

@description('value of azure openai dall-e model capacity')
param imageGenerationModelCapacity int = 1

@description('value of the current IP address for network access')
param currentIpAddress string

@description('value of source registry to use for image imports')
param sourceRegistry string = 'ghcr.io/azure-samples'

@description('value of tags to apply to resources')
param tags object = {
  environment: 'development'
}

// generate a unique string based on the resource group id
// this is used to ensure that each resource name is unique
var name = '${appEnvironment}${take(uniqueString(subscription().id, appEnvironment), 4)}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${name}'
  location: location
  tags: tags
}

module observability 'observability.bicep' = if (deployObservabilityTools) {
  scope: rg
  name: 'observabilityDeployment'
  params: {
    nameSuffix: name
    currentUserObjectId: currentUserObjectId
    tags: tags
  }
}

module aks 'kubernetes.bicep' = {
  scope: rg
  name: 'aksDeployment'
  params: {
    location: location
    nameSuffix: name
    vmSku: aksNodePoolVMSize
    deployAcr: deployAzureContainerRegistry
    logsWorkspaceResourceId: deployObservabilityTools ? observability.outputs.logsWorkspaceResourceId : ''
    metricsWorkspaceResourceId: deployObservabilityTools ? observability.outputs.metricsWorkspaceResourceId : ''
    currentUserObjectId: currentUserObjectId
    currentIpAddress: currentIpAddress
    configureMonitorSettings: deployObservabilityTools
    tags: tags
  }
}

module workloadidentity 'workloadidentity.bicep' = if (deployAzureCosmosDB || deployAzureServiceBus || deployAzureOpenAI) {
  scope: rg
  name: 'workloadIdentityDeployment'
  params: {
    nameSuffix: name
    federatedCredentials: [
      {
        name: 'ai-service'
        audiences: ['api://AzureADTokenExchange']
        issuer: aks.outputs.oidcIssuerUrl
        subject: 'system:serviceaccount:${k8sNamespace}:ai-service'
      }
      {
        name: 'order-service'
        audiences: ['api://AzureADTokenExchange']
        issuer: aks.outputs.oidcIssuerUrl
        subject: 'system:serviceaccount:${k8sNamespace}:order-service'
      }
      {
        name: 'makeline-service'
        audiences: ['api://AzureADTokenExchange']
        issuer: aks.outputs.oidcIssuerUrl
        subject: 'system:serviceaccount:${k8sNamespace}:makeline-service'
      }
    ]
    tags: tags
  }
}

module servicebus 'servicebus.bicep' = if (deployAzureServiceBus) {
  scope: rg
  name: 'servicebusDeployment'
  params: {
    nameSuffix: name
    currentUserObjectId: currentUserObjectId
    currentIpAddress: currentIpAddress
    servicePrincipalId: workloadidentity.outputs.principalId
    tags: tags
  }
}

module cosmosdb 'cosmosdb.bicep' = if (deployAzureCosmosDB) {
  scope: rg
  name: 'cosmosdbDeployment'
  params: {
    nameSuffix: name
    accountKind: cosmosDBAccountKind
    identityPrincipalId: workloadidentity.outputs.principalId
    currentIpAddress: currentIpAddress
    servicePrincipalId: workloadidentity.outputs.principalId
    tags: tags
  }
}

var chatCompletionModel = {
  name: chatCompletionModelName
  version: chatCompletionModelVersion
  capacity: chatCompletionModelCapacity
}
var imageGenerationModel = {
  name: imageGenerationModelName
  version: imageGenerationModelVersion
  capacity: imageGenerationModelCapacity
}
var modelDeployments = concat([chatCompletionModel], deployImageGenerationModel ? [imageGenerationModel] : [])
module openai 'openai.bicep' = if (deployAzureOpenAI) {
  scope: rg
  name: 'openaiDeployment'
  params: {
    nameSuffix: name
    location: azureOpenAILocation
    currentUserObjectId: currentUserObjectId
    currentIpAddress: currentIpAddress
    servicePrincipalId: workloadidentity.outputs.principalId
    modelDeployments: modelDeployments
    tags: tags
  }
}

output AZURE_RESOURCENAME_SUFFIX string = name
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_AKS_CLUSTER_NAME string = aks.outputs.name
output AZURE_AKS_NAMESPACE string = k8sNamespace
output AZURE_AKS_CLUSTER_ID string = aks.outputs.id
output AZURE_AKS_OIDC_ISSUER_URL string = aks.outputs.oidcIssuerUrl
output AZURE_OPENAI_ENDPOINT string = deployAzureOpenAI ? openai.outputs.endpoint : ''
output AZURE_OPENAI_MODEL_NAME string = deployAzureOpenAI ? chatCompletionModelName : ''
output AZURE_OPENAI_DALL_E_MODEL_NAME string = deployAzureOpenAI && deployImageGenerationModel
  ? imageGenerationModelName
  : ''
output AZURE_OPENAI_DALL_E_ENDPOINT string = deployAzureOpenAI && deployImageGenerationModel
  ? openai.outputs.endpoint
  : ''
output AZURE_IDENTITY_NAME string = workloadidentity.outputs.name
output AZURE_IDENTITY_CLIENT_ID string = workloadidentity.outputs.clientId
output AZURE_SERVICE_BUS_HOST string = deployAzureServiceBus ? '${servicebus.outputs.name}.servicebus.windows.net' : ''
output AZURE_SERVICE_BUS_URI string = deployAzureServiceBus
  ? 'amqps://${servicebus.outputs.name}.servicebus.windows.net'
  : ''
output AZURE_COSMOS_DATABASE_NAME string = deployAzureCosmosDB ? cosmosdb.outputs.name : ''
output AZURE_COSMOS_DATABASE_URI string = deployAzureCosmosDB && cosmosDBAccountKind == 'MongoDB'
  ? 'mongodb://${cosmosdb.outputs.name}.mongo.cosmos.azure.com:10255/?retryWrites=false'
  : deployAzureCosmosDB && cosmosDBAccountKind == 'GlobalDocumentDB'
      ? 'https://${cosmosdb.outputs.name}.documents.azure.com:443/'
      : ''
output AZURE_COSMOS_DATABASE_LIST_CONNECTIONSTRINGS_URL string = deployAzureCosmosDB
  ? '${environment().resourceManager}${cosmosdb.outputs.id}/listConnectionStrings?api-version=2021-04-15'
  : ''
output AZURE_DATABASE_API string = cosmosDBAccountKind == 'MongoDB' ? 'mongodb' : 'cosmosdbsql'
output AZURE_REGISTRY_NAME string = deployAzureContainerRegistry ? aks.outputs.registryName : ''
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = deployAzureContainerRegistry
  ? aks.outputs.registryLoginServer
  : sourceRegistry 
output AZURE_TENANT_ID string = tenant().tenantId
