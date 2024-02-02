output "AZURE_RESOURCEGROUP_NAME" {
  value = azurerm_resource_group.example.name
}

output "AZURE_AKS_CLUSTER_NAME" {
  value = azurerm_kubernetes_cluster.example.name
}

output "AZURE_OPENAI_MODEL_NAME" {
  value = var.openai_model_name
}

output "AZURE_OPENAI_ENDPOINT" {
  value = azurerm_cognitive_account.example.endpoint
}

output "AZURE_IDENTITY_CLIENT_ID" {
  value = azurerm_user_assigned_identity.example.client_id
}

output "AZURE_SERVICE_BUS_HOST" {
  value = "${azurerm_servicebus_namespace.example.name}.servicebus.windows.net"
}

output "AZURE_SERVICE_BUS_URI" {
  value     = "amqps://${azurerm_servicebus_namespace.example.name}.servicebus.windows.net"
  sensitive = true
}

output "AZURE_SERVICE_BUS_LISTENER_NAME" {
  value = azurerm_servicebus_namespace_authorization_rule.example.name
}

output "AZURE_SERVICE_BUS_LISTENER_KEY" {
  value     = azurerm_key_vault_secret.listener_key.name
  sensitive = true
}

output "AZURE_SERVICE_BUS_SENDER_NAME" {
  value = azurerm_servicebus_queue_authorization_rule.example.name
}

output "AZURE_SERVICE_BUS_SENDER_KEY" {
  value     = azurerm_key_vault_secret.sender_key.name
  sensitive = true
}

output "AZURE_COSMOS_DATABASE_NAME" {
  value = azurerm_cosmosdb_account.example.name
}

output "AZURE_COSMOS_DATABASE_URI" {
  value = "mongodb://${azurerm_cosmosdb_account.example.name}.mongo.cosmos.azure.com:10255/?retryWrites=false"
}

output "AZURE_COSMOS_DATABASE_KEY" {
  value     = azurerm_key_vault_secret.cosmosdb_key.name
  sensitive = true
}

output "AZURE_AKS_NAMESPACE" {
  value = var.k8s_namespace
}

output "AZURE_KEY_VAULT_NAME" {
  value = azurerm_key_vault.example.name
}