@minLength(3)
param nameSuffix string
param federatedCredentials federatedCredential[]
param tags object

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
    tags: tags
  }
}

output name string = userAssignedIdentity.outputs.name
output clientId string = userAssignedIdentity.outputs.clientId
output principalId string = userAssignedIdentity.outputs.principalId
