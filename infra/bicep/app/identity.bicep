param name string
param location string
param tags object = {}
param principalId string
param AZURE_AKS_NAMESPACE string
param clusterName string

// identity for the openai
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

// federated credential for the openai
resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: name
  parent: identity
  properties: {
    audiences: ['api://AzureADTokenExchange']
    issuer: aks.properties.oidcIssuerProfile.issuerURL
    subject: 'system:serviceaccount:${AZURE_AKS_NAMESPACE}:ai-service-account'
  }
}

// role definition for the openai
var openAiUserRole = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

// role assignment for the openai
module roleAssignment '../core/security/role.bicep' = {
  name: 'roleAssignment'
  params: {
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: openAiUserRole
  }
}

module roleAssignmentForMe '../core/security/role.bicep' = {
  name: 'roleAssignmentForMe'
  params: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: openAiUserRole
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-03-02-preview' existing = {
  name: clusterName
}

output principalId string = identity.properties.principalId
output clientId string = identity.properties.clientId
