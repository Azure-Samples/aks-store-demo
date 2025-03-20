@minLength(3)
param nameSuffix string
param federatedCredentials federatedCredential[]

type federatedCredential = {
  audiences: string[]
  issuer: string
  partialSubject: string
}

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'userAssignedIdentityDeployment'
  params: {
    name: 'mi-${nameSuffix}'
    federatedIdentityCredentials: [
      for fc in federatedCredentials: {
        name: 'mi-${nameSuffix}-fc'
        audiences: fc.audiences
        issuer: fc.issuer
        subject: '${fc.partialSubject}:mi-${nameSuffix}'
      }
    ]
  }
}

var cognitiveServicesOpenAIUserRoleDefinitionId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
resource cognitiveServicesOpenAIUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, cognitiveServicesOpenAIUserRoleDefinitionId)
  properties: {
    principalId: userAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesOpenAIUserRoleDefinitionId)
  }
}

var azureServiceBusDataOwnerRoleDefinitionId = '090c5cfd-751d-490a-894a-3ce6f1109419'
resource azureServiceBusDataOwnerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, azureServiceBusDataOwnerRoleDefinitionId)
  properties: {
    principalId: userAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureServiceBusDataOwnerRoleDefinitionId)
  }
}

var documentDBAccountContributorRoleDefinitionId = '5bd9cd88-fe45-4216-938b-f97437e15450'
resource documentDBAccountContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, documentDBAccountContributorRoleDefinitionId)
  properties: {
    principalId: userAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId(
      'Microsoft.Authorization/roleDefinitions',
      documentDBAccountContributorRoleDefinitionId
    )
  }
}

output name string = userAssignedIdentity.outputs.name
output clientId string = userAssignedIdentity.outputs.clientId
output principalId string = userAssignedIdentity.outputs.principalId
