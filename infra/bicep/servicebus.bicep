@minLength(3)
param nameSuffix string
param currentUserObjectId string

// https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/service-bus/namespace
module namespace 'br/public:avm/res/service-bus/namespace:0.13.2' = {
  name: 'namespaceDeployment'
  params: {
    name: 'sb-${nameSuffix}'
    skuObject: {
      name: 'Standard'
    }
    queues: [
      {
        name: 'orders'
      }
    ]
  }
}

var azureServiceBusDataOwnerRoleDefinitionId = '090c5cfd-751d-490a-894a-3ce6f1109419'
resource azureServiceBusDataOwnerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, currentUserObjectId, azureServiceBusDataOwnerRoleDefinitionId)
  properties: {
    principalId: currentUserObjectId
    principalType: 'User'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', azureServiceBusDataOwnerRoleDefinitionId)
  }
}

output name string = namespace.outputs.name
