@minLength(3)
param nameSuffix string
param currentUserObjectId string
param currentIpAddress string
param servicePrincipalId string
param tags object

// https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/service-bus/namespace
module serviceBusNamespace 'br/public:avm/res/service-bus/namespace:0.13.2' = {
  name: 'namespaceDeployment'
  params: {
    name: 'sb-${nameSuffix}'
    disableLocalAuth: true
    skuObject: {
      name: 'Standard'
    }
    queues: [
      {
        name: 'orders'
      }
    ]
    // networkRuleSets: {
    //   ipRules: [
    //     {
    //       action: 'Allow'
    //       ipMask: '0.0.0.0'
    //     }
    //     {
    //       action: 'Allow'
    //       ipMask: currentIpAddress
    //     }
    //   ]
    //   trustedServiceAccessEnabled: true
    // }
    roleAssignments: [
      {
        principalId: currentUserObjectId
        roleDefinitionIdOrName: 'Azure Service Bus Data Owner'
        principalType: 'User'
      }
      {
        principalId: servicePrincipalId
        roleDefinitionIdOrName: 'Azure Service Bus Data Owner'
        principalType: 'ServicePrincipal'
      }
    ]
    tags: tags
  }
}

output name string = serviceBusNamespace.outputs.name
