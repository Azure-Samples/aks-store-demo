output "AZURE_RESOURCENAME_SUFFIX" {
  value = local.name
}

output "AZURE_RESOURCE_GROUP" {
  value = azurerm_resource_group.example.name
}

output "AZURE_AKS_CLUSTER_NAME" {
  value = azurerm_kubernetes_cluster.example.name
}

output "AZURE_AKS_NAMESPACE" {
  value = var.k8s_namespace
}

output "AZURE_AKS_CLUSTER_ID" {
  value = azurerm_kubernetes_cluster.example.id
}

output "AZURE_AKS_CLUSTER_NODE_RESOURCEGROUP_NAME" {
  value = azurerm_kubernetes_cluster.example.node_resource_group
}

output "AZURE_AKS_OIDC_ISSUER_URL" {
  value = azurerm_kubernetes_cluster.example.oidc_issuer_url
}

output "AZURE_OPENAI_MODEL_NAME" {
  value = local.deploy_azure_openai ? var.openai_model_name : ""
}

output "AZURE_OPENAI_ENDPOINT" {
  value = local.deploy_azure_openai ? azurerm_cognitive_account.example[0].endpoint : ""
}

output "AZURE_OPENAI_DALL_E_MODEL_NAME" {
  value = local.deploy_azure_openai_dalle_model ? var.openai_dalle_model_name : ""
}

output "AZURE_OPENAI_DALL_E_ENDPOINT" {
  value = local.deploy_azure_openai_dalle_model ? azurerm_cognitive_account.example[0].endpoint : ""
}

output "AZURE_OPENAI_KEY" {
  value     = local.deploy_azure_openai && !local.deploy_azure_workload_identity ? azurerm_key_vault_secret.openai_key[0].name : ""
  sensitive = true
}

output "AZURE_IDENTITY_NAME" {
  value = local.deploy_azure_workload_identity ? azurerm_user_assigned_identity.example[0].name : ""
}

output "AZURE_IDENTITY_CLIENT_ID" {
  value = local.deploy_azure_workload_identity ? azurerm_user_assigned_identity.example[0].client_id : ""
}

output "AZURE_SERVICE_BUS_HOST" {
  value = local.deploy_azure_servicebus ? "${azurerm_servicebus_namespace.example[0].name}.servicebus.windows.net" : ""
}

output "AZURE_SERVICE_BUS_URI" {
  value     = local.deploy_azure_servicebus ? "amqps://${azurerm_servicebus_namespace.example[0].name}.servicebus.windows.net" : ""
  sensitive = true
}

output "AZURE_SERVICE_BUS_LISTENER_NAME" {
  value = local.deploy_azure_servicebus && !local.deploy_azure_workload_identity ? azurerm_servicebus_namespace_authorization_rule.example[0].name : ""
}

output "AZURE_SERVICE_BUS_LISTENER_KEY" {
  value     = local.deploy_azure_servicebus && !local.deploy_azure_workload_identity ? azurerm_key_vault_secret.listener_key[0].name : ""
  sensitive = true
}

output "AZURE_SERVICE_BUS_SENDER_NAME" {
  value = local.deploy_azure_servicebus && !local.deploy_azure_workload_identity ? azurerm_servicebus_queue_authorization_rule.example[0].name : ""
}

output "AZURE_SERVICE_BUS_SENDER_KEY" {
  value     = local.deploy_azure_servicebus && !local.deploy_azure_workload_identity ? azurerm_key_vault_secret.sender_key[0].name : ""
  sensitive = true
}

output "AZURE_COSMOS_DATABASE_NAME" {
  value = local.deploy_azure_cosmosdb ? azurerm_cosmosdb_account.example[0].name : ""
}

output "AZURE_COSMOS_DATABASE_URI" {
  value = local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "MongoDB" ? "mongodb://${azurerm_cosmosdb_account.example[0].name}.mongo.cosmos.azure.com:10255/?retryWrites=false" : local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "GlobalDocumentDB" ? "https://${azurerm_cosmosdb_account.example[0].name}.documents.azure.com:443/" : ""
}

output "AZURE_DATABASE_API" {
  value = local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "MongoDB" ? "mongodb" : local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "GlobalDocumentDB" ? "cosmosdbsql" : ""
}

output "AZURE_COSMOS_DATABASE_KEY" {
  value     = local.deploy_azure_cosmosdb && !local.deploy_azure_workload_identity ? azurerm_key_vault_secret.cosmosdb_key[0].name : ""
  sensitive = true
}

output "AZURE_KEY_VAULT_NAME" {
  value = !local.deploy_azure_workload_identity ? azurerm_key_vault.example[0].name : ""
}

output "AZURE_REGISTRY_NAME" {
  value = local.deploy_azure_container_registry ? azurerm_container_registry.example[0].name : ""
}

output "AZURE_REGISTRY_URI" {
  value = local.deploy_azure_container_registry ? azurerm_container_registry.example[0].login_server : "ghcr.io/azure-samples"
}

output "AZURE_TENANT_ID" {
  value = data.azurerm_client_config.current.tenant_id
}
