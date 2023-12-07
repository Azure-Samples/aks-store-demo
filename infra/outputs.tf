output "rg_name" {
  value = azurerm_resource_group.example.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.example.name
}

output "ai_model_name" {
  value = var.openai_model_name
}

output "ai_endpoint" {
  value = azurerm_cognitive_account.example.endpoint
}

output "ai_key" {
  value     = azurerm_cognitive_account.example.primary_access_key
  sensitive = true
}

output "ai_managed_identity_client_id" {
  value = azurerm_user_assigned_identity.example.client_id
}

output "sb_namespace_host" {
  value = "${azurerm_servicebus_namespace.example.name}.servicebus.windows.net"
}

output "sb_namespace_uri" {
  value     = "amqps://${azurerm_servicebus_namespace.example.name}.servicebus.windows.net"
  sensitive = true
}

output "sb_listener_username" {
  value = azurerm_servicebus_namespace_authorization_rule.example.name
}

output "sb_listener_key" {
  value     = azurerm_servicebus_namespace_authorization_rule.example.primary_key
  sensitive = true
}

output "sb_sender_username" {
  value = azurerm_servicebus_queue_authorization_rule.example.name
}

output "sb_sender_key" {
  value     = azurerm_servicebus_queue_authorization_rule.example.primary_key
  sensitive = true
}

output "db_account_name" {
  value = azurerm_cosmosdb_account.example.name
}

output "db_api" {
  value = var.cosmosdb_account_kind == "MongoDB" ? "mongodb" : "cosmosdbsql"
}

output "db_uri" {
  value = var.cosmosdb_account_kind == "MongoDB" ? "mongodb://${azurerm_cosmosdb_account.example.name}.mongo.cosmos.azure.com:10255/?retryWrites=false" : "https://${azurerm_cosmosdb_account.example.name}.documents.azure.com:443/"
}

output "db_key" {
  value     = azurerm_cosmosdb_account.example.primary_key
  sensitive = true
}

output "k8s_namespace" {
  value = var.k8s_namespace
}

output "registry_name" {
  value = azurerm_container_registry.example.name
}

output "registry_uri" {
  value = azurerm_container_registry.example.login_server
}