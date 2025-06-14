resource "azurerm_user_assigned_identity" "example" {
  count               = local.deploy_azure_openai || local.deploy_azure_servicebus || local.deploy_azure_cosmosdb ? 1 : 0
  location            = var.location
  name                = "mi-${local.name}"
  resource_group_name = azurerm_resource_group.example.name
}


resource "azurerm_federated_identity_credential" "example1" {
  count               = local.deploy_azure_openai ? 1 : 0
  name                = "ai-service"
  resource_group_name = azurerm_resource_group.example.name
  parent_id           = azurerm_user_assigned_identity.example[0].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  subject             = "system:serviceaccount:${var.k8s_namespace}:ai-service"
}

resource "azurerm_federated_identity_credential" "example2" {
  count               = local.deploy_azure_servicebus || local.deploy_azure_cosmosdb ? 1 : 0
  name                = "order-service"
  resource_group_name = azurerm_resource_group.example.name
  parent_id           = azurerm_user_assigned_identity.example[0].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  subject             = "system:serviceaccount:${var.k8s_namespace}:order-service"
}

resource "azurerm_federated_identity_credential" "example3" {
  count               = local.deploy_azure_servicebus || local.deploy_azure_cosmosdb ? 1 : 0
  name                = "makeline-service"
  resource_group_name = azurerm_resource_group.example.name
  parent_id           = azurerm_user_assigned_identity.example[0].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.aks.oidc_issuer_url
  subject             = "system:serviceaccount:${var.k8s_namespace}:makeline-service"
}

resource "azurerm_role_assignment" "aoai_mid" {
  count                = local.deploy_azure_openai ? 1 : 0
  principal_id         = azurerm_user_assigned_identity.example[0].principal_id
  role_definition_name = "Cognitive Services OpenAI User"
  scope                = module.aoai[0].resource_id
}

resource "azurerm_role_assignment" "servicebus_mid" {
  count                = local.deploy_azure_servicebus ? 1 : 0
  principal_id         = azurerm_user_assigned_identity.example[0].principal_id
  role_definition_name = "Azure Service Bus Data Owner"
  scope                = module.sb[0].resource_id
}

resource "azurerm_role_assignment" "cosmosdb_mid" {
  count                = local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "MongoDB" ? 1 : 0
  principal_id         = azurerm_user_assigned_identity.example[0].principal_id
  role_definition_name = "DocumentDB Account Contributor"
  scope                = module.db[0].resource_id
}

resource "azurerm_cosmosdb_sql_role_definition" "cosmosdb" {
  count               = local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "GlobalDocumentDB" ? 1 : 0
  resource_group_name = azurerm_resource_group.example.name
  account_name        = module.db[0].name
  name                = "CosmosDBDataContributor - ${azurerm_user_assigned_identity.example[0].name}"
  type                = "CustomRole"
  assignable_scopes   = [module.db[0].resource_id]

  permissions {
    data_actions = [
      "Microsoft.DocumentDB/databaseAccounts/readMetadata",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*",
    ]
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb_mid" {
  count               = local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "GlobalDocumentDB" ? 1 : 0
  resource_group_name = azurerm_resource_group.example.name
  account_name        = module.db[0].name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.cosmosdb[0].id
  scope               = module.db[0].resource_id
  principal_id        = azurerm_user_assigned_identity.example[0].principal_id
}
