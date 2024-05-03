resource "azurerm_user_assigned_identity" "example" {
  count               = local.deploy_azure_workload_identity ? 1 : 0
  location            = var.location
  name                = "mid-${local.name}"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_federated_identity_credential" "example" {
  count               = local.deploy_azure_openai && local.deploy_azure_workload_identity ? 1 : 0
  name                = azurerm_user_assigned_identity.example[0].name
  resource_group_name = azurerm_resource_group.example.name
  parent_id           = azurerm_user_assigned_identity.example[0].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.example.oidc_issuer_url
  subject             = "system:serviceaccount:${var.k8s_namespace}:${azurerm_user_assigned_identity.example[0].name}"
}

resource "azurerm_role_assignment" "aoai_mid" {
  count                = local.deploy_azure_openai && local.deploy_azure_workload_identity ? 1 : 0
  principal_id         = azurerm_user_assigned_identity.example[0].principal_id
  role_definition_name = "Cognitive Services OpenAI User"
  scope                = azurerm_cognitive_account.example[0].id
}

resource "azurerm_role_assignment" "servicebus_mid" {
  count                = local.deploy_azure_servicebus && local.deploy_azure_workload_identity ? 1 : 0
  principal_id         = azurerm_user_assigned_identity.example[0].principal_id
  role_definition_name = "Azure Service Bus Data Owner"
  scope                = azurerm_servicebus_namespace.example[0].id
}

resource "azurerm_cosmosdb_sql_role_definition" "cosmosdb" {
  count               = local.deploy_azure_cosmosdb && local.deploy_azure_workload_identity ? 1 : 0
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_cosmosdb_account.example[0].name
  name                = "CosmosDBDataContributor - ${azurerm_user_assigned_identity.example[0].name}"
  type                = "CustomRole"
  assignable_scopes   = [azurerm_cosmosdb_account.example[0].id]

  permissions {
    data_actions = [
      "Microsoft.DocumentDB/databaseAccounts/readMetadata",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*",
    ]
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb_mid" {
  count               = local.deploy_azure_cosmosdb && local.deploy_azure_workload_identity ? 1 : 0
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_cosmosdb_account.example[0].name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.cosmosdb[0].id
  scope               = azurerm_cosmosdb_account.example[0].id
  principal_id        = azurerm_user_assigned_identity.example[0].principal_id
}
