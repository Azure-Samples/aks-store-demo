@minLength(3)
param nameSuffix string
param accountKind string
param identityPrincipalId string
param currentIpAddress string
param servicePrincipalId string
param tags object

// https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/document-db/database-account
module databaseAccount 'br/public:avm/res/document-db/database-account:0.11.3' = {
  name: 'databaseAccountDeployment'
  params: {
    name: 'db-${nameSuffix}'
    minimumTlsVersion: 'Tls12'
    serverVersion: '4.2'
    capabilitiesToAdd: accountKind == 'MongoDB'
      ? [
          'EnableMongo'
        ]
      : []
    mongodbDatabases: accountKind == 'MongoDB'
      ? [
          {
            name: 'orderdb'
            throughput: 400
            collections: [
              {
                name: 'orders'
                throughput: 400
                indexes: [
                  {
                    key: {
                      keys: [
                        '_id'
                      ]
                    }
                  }
                ]
                shardKey: {
                  _id: 'Hash'
                }
              }
            ]
          }
        ]
      : []
    sqlDatabases: accountKind == 'GlobalDocumentDB'
      ? [
          {
            name: 'orderdb'
            throughput: 400
            containers: [
              {
                name: 'orders'
                paths: [
                  '/storeId'
                ]
              }
            ]
          }
        ]
      : []
    sqlRoleDefinitions: accountKind == 'GlobalDocumentDB'
      ? [
          {
            name: 'CustomCosmosDBDataContributor'
            roleType: 'CustomRole'
            dataActions: [
              'Microsoft.DocumentDB/databaseAccounts/readMetadata'
              'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
              'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
            ]
          }
        ]
      : []
    sqlRoleAssignmentsPrincipalIds: accountKind == 'GlobalDocumentDB'
      ? [
          identityPrincipalId
        ]
      : []
    // networkRestrictions: {
    //   publicNetworkAccess: 'Enabled'
    //   networkAclBypass: 'AzureServices'
    //   ipRules: [
    //     '0.0.0.0'
    //     currentIpAddress
    //   ]
    // }
    roleAssignments: [
      {
        principalId: servicePrincipalId
        roleDefinitionIdOrName: 'DocumentDB Account Contributor'
        principalType: 'ServicePrincipal'
      }
    ]
    tags: tags
  }
}

output id string = databaseAccount.outputs.resourceId
output name string = databaseAccount.outputs.name
