targetScope = 'subscription'

@description('value of the current user for rbac assignments')
param currentUserObjectId string

@minLength(1)
@description('value of azure location to deploy resources')
param location string

@minLength(5)
@maxLength(25)
@description('value of azure resource group name suffix')
param resourceGroupNameSuffix string

@description('value of azure kubernetes node pool vm size')
param aksNodePoolVMSize string = 'Standard_DS2_v2'

@description('value of the kubernetes namespace')
param k8sNamespace string = 'pets'

@description('value to determine if observability tools should be deployed')
param deployObservabilityTools bool = false

@description('value to determine if azure container registry should be deployed')
param deployAzureContainerRegistry bool = false

@description('value to determine if azure servicebus should be deployed')
param deployAzureServiceBus bool = false

@description('value to determine if azure cosmosdb should be deployed')
param deployAzureCosmosDB bool = false

@description('value of azure cosmosdb account kind')
param cosmosDBAccountKind string = 'GlobalDocumentDB'

@description('value to determine if azure openai should be deployed')
param deployAzureOpenAI bool = false

@description('value of azure location for azure openai resources')
param azureOpenAILocation string

@description('value of azure openai model name')
param chatCompletionModelName string = 'gpt-35-turbo'

@description('value of azure openai model version')
param chatCompletionModelVersion string = '0125'

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

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${resourceGroupNameSuffix}'
  location: location
}

// generate a unique string based on the resource group id
// this is used to ensure that each resource name is unique
var resource_name_suffix = uniqueString(rg.id)

module observability 'observability.bicep' = if (deployObservabilityTools) {
  scope: rg
  name: 'observabilityDeployment'
  params: {
    name: resource_name_suffix
  }
}

module aks 'kubernetes.bicep' = {
  scope: rg
  name: 'aksDeployment'
  params: {
    nameSuffix: resource_name_suffix
    vmSku: aksNodePoolVMSize
    deployAcr: deployAzureContainerRegistry
    monitoringWorkspaceResourceId: deployObservabilityTools ? observability.outputs.logWorkspaceResourceId : ''
    currentUserObjectId: currentUserObjectId
  }
}

module servicebus 'servicebus.bicep' = if (deployAzureServiceBus) {
  scope: rg
  name: 'servicebusDeployment'
  params: {
    nameSuffix: resource_name_suffix
    currentUserObjectId: currentUserObjectId
  }
}

module cosmosdb 'cosmosdb.bicep' = if (deployAzureCosmosDB) {
  scope: rg
  name: 'cosmosdbDeployment'
  params: {
    nameSuffix: resource_name_suffix
    accountKind: cosmosDBAccountKind
    identityPrincipalId: workloadidentity.outputs.principalId
  }
}

module openai 'openai.bicep' = if (deployAzureOpenAI) {
  scope: rg
  name: 'openaiDeployment'
  params: {
    nameSuffix: resource_name_suffix
    location: azureOpenAILocation
    chatCompletionModelName: chatCompletionModelName
    chatCompletionModelVersion: chatCompletionModelVersion
    chatCompletionModelCapacity: chatCompletionModelCapacity
    deployImageGenerationModel: deployImageGenerationModel
    imageGenerationModelName: imageGenerationModelName
    imageGenerationModelVersion: imageGenerationModelVersion
    imageGenerationModelCapacity: imageGenerationModelCapacity
    currentUserObjectId: currentUserObjectId
  }
}

module workloadidentity 'workloadidentity.bicep' = {
  scope: rg
  name: 'workloadIdentityDeployment'
  params: {
    nameSuffix: resource_name_suffix
    federatedCredentials: [
      {
        audiences: ['api://AzureADTokenExchange']
        issuer: aks.outputs.oidcIssuerUrl
        partialSubject: 'system:serviceaccount:${k8sNamespace}'
      }
    ]
  }
}

output AZURE_RESOURCENAME_SUFFIX string = resource_name_suffix
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_AKS_CLUSTER_NAME string = aks.outputs.name
output AZURE_AKS_NAMESPACE string = k8sNamespace
output AZURE_AKS_CLUSTER_ID string = aks.outputs.id
output AZURE_AKS_OIDC_ISSUER_URL string = aks.outputs.oidcIssuerUrl
output AZURE_OPENAI_ENDPOINT string = openai.outputs.endpoint
output AZURE_OPENAI_MODEL_NAME string = chatCompletionModelName
output AZURE_OPENAI_DALL_E_MODEL_NAME string = imageGenerationModelName
output AZURE_OPENAI_DALL_E_ENDPOINT string = deployImageGenerationModel ? openai.outputs.endpoint : ''
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
  ? 'https://management.azure.com${cosmosdb.outputs.id}/listConnectionStrings?api-version=2021-04-15'
  : ''
output AZURE_DATABASE_API string = cosmosDBAccountKind == 'MongoDB' ? 'mongodb' : 'cosmosdbsql'
output AZURE_REGISTRY_NAME string = deployAzureContainerRegistry ? aks.outputs.registryName : ''
output AZURE_REGISTRY_URI string = deployAzureContainerRegistry
  ? aks.outputs.registryLoginServer
  : 'ghcr.io/azure-samples'
output AZURE_TENANT_ID string = tenant().tenantId
