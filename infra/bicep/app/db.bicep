@allowed([
  'MongoDB'
  'GlobalDocumentDB'
])
param kind string
param resourceToken string
param location string
param keyVaultName string
param tags object = {}
param cosmosDatabaseName string = 'orderdb'

@description('The collections to create in the database')
param collections array = [
  {
    id: 'orders'
    name: 'orders'
    shardKey: 'Hash'
    indexKey: '_id'
    throughput: 400
  }
]

// the application database
module cosmosMongo '../core/database/cosmos/mongo/cosmos-mongo-db.bicep' = if(kind == 'MongoDB') {
  name: 'cosmos-mongo'
  params: {
    accountName: 'cosmos-${resourceToken}'
    databaseName: cosmosDatabaseName
    location: location
    collections: collections
    tags: tags
    keyVaultName: keyVaultName
  }
}

module cosmosSql '../core/database/cosmos/sql/cosmos-sql-db.bicep' = if(kind == 'GlobalDocumentDB') {
  name: 'cosmos-sql'
  params: {
    accountName: 'cosmos-${resourceToken}'
    databaseName: cosmosDatabaseName
    location: location
    containers: [
      {
        name: 'orders'
        id: 'orders'
        partitionKey: '/storeId'
      }
    ]
    tags: tags
    keyVaultName: keyVaultName
  }
}

output name string = 'cosmos-${resourceToken}'
output endpoint string = kind == 'MongoDB' ? 'mongodb://cosmos-${resourceToken}.mongo.cosmos.azure.com:10255/?retryWrites=false' : 'https://cosmos-${resourceToken}.documents.azure.com:443/'
