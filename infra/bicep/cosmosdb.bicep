@minLength(3)
param nameSuffix string
param accountKind string
param identityPrincipalId string

// https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/document-db/database-account
module databaseAccount 'br/public:avm/res/document-db/database-account:0.11.3' = {
  name: 'databaseAccountDeployment'
  params: {
    name: 'db-${nameSuffix}'
    minimumTlsVersion: 'Tls12'
    networkRestrictions: {
      networkAclBypass: 'AzureServices'
    }
    capabilitiesToAdd: [
      'EnableMongo'
    ]
    serverVersion: '4.2'
    mongodbDatabases: accountKind == 'MongoDB'
      ? [
          {
            name: 'orderdb'
            throughput: 400
            collections: [
              {
                name: 'orders'
                throughput: 400
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
  }
}

output id string = databaseAccount.outputs.resourceId
output name string = databaseAccount.outputs.name
