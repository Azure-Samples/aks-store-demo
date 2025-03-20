@minLength(3)
param nameSuffix string
param location string
param chatCompletionModelName string
param chatCompletionModelVersion string
param chatCompletionModelCapacity int
param deployImageGenerationModel bool
param imageGenerationModelName string
param imageGenerationModelVersion string
param imageGenerationModelCapacity int
param currentUserObjectId string

var baseDeployment = [
  {
    model: {
      name: chatCompletionModelName
      format: 'OpenAI'
      version: chatCompletionModelVersion
    }
    sku: {
      name: 'Standard'
      capacity: chatCompletionModelCapacity
    }
  }
]

var dalle3Deployment = [
  {
    model: {
      name: imageGenerationModelName
      format: 'OpenAI'
      version: imageGenerationModelVersion
    }
    sku: {
      name: 'Standard'
      capacity: imageGenerationModelCapacity
    }
  }
]

// https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/cognitive-services/account
module account 'br/public:avm/res/cognitive-services/account:0.10.1' = {
  name: 'accountDeployment'
  params: {
    name: 'aoai-${nameSuffix}'
    customSubDomainName: 'aoai-${nameSuffix}'
    location: location
    kind: 'OpenAI'
    sku: 'S0'
    deployments: deployImageGenerationModel ? concat(baseDeployment, dalle3Deployment) : baseDeployment
  }
}

var cognitiveServicesOpenAIUserRoleDefinitionId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
resource cognitiveServicesOpenAIUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, currentUserObjectId, cognitiveServicesOpenAIUserRoleDefinitionId)
  properties: {
    principalId: currentUserObjectId
    principalType: 'User'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesOpenAIUserRoleDefinitionId)
  }
}

output endpoint string = account.outputs.endpoint
