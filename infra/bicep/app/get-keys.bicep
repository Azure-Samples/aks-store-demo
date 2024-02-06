param openAiName string
param openAiKeyName string = 'AZURE-OPENAI-KEY'
param cosmosAccountName string
param cosmosKeyName string = 'AZURE-COSMOS-KEY'
param keyVaultName string

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAiName
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmosAccountName
}

// create key vault secrets
module openAiKey '../core/security/keyvault-secret.bicep' = {
  name: 'openAiKey'
  params: {
    name: openAiKeyName
    keyVaultName: keyVaultName
    secretValue: account.listKeys().key1
  }
}

module cosmosKey '../core/security/keyvault-secret.bicep' = {
  name: 'cosmosKey'
  params: {
    name: cosmosKeyName
    keyVaultName: keyVaultName
    secretValue: cosmos.listKeys().primaryMasterKey
  }
}

output openAiKey string = openAiKeyName
output cosmosKey string = cosmosKeyName
