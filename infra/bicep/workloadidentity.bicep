@minLength(3)
param nameSuffix string
param federatedCredentials federatedCredential[]
param tags object

type federatedCredential = {
  name: string
  audiences: string[]
  issuer: string
  subject: string
}

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'userAssignedIdentityDeployment'
  params: {
    name: 'mi-${nameSuffix}'
    federatedIdentityCredentials: [
      for fc in federatedCredentials: {
        name: fc.name
        audiences: fc.audiences
        issuer: fc.issuer
        subject: fc.subject
      }
    ]
    tags: tags
  }
}

output name string = userAssignedIdentity.outputs.name
output clientId string = userAssignedIdentity.outputs.clientId
output principalId string = userAssignedIdentity.outputs.principalId
