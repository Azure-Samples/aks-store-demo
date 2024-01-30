param openAiName string
param cosmosAccountName string

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAiName
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmosAccountName
}

output openAiKey string = account.listKeys().key1
output dbKey string = cosmos.listKeys().primaryMasterKey
