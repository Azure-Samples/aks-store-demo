locals {
  name                            = "${random_pet.example.id}${random_integer.example.result}"
  location                        = var.location
  aks_node_pool_vm_size           = var.aks_node_pool_vm_size != "" ? var.aks_node_pool_vm_size : "Standard_DS2_v2"
  deploy_azure_cosmosdb           = var.deploy_azure_cosmosdb == "true" ? true : false
  default_cosmosdb_account_kind   = var.deploy_azure_workload_identity == "true" ? "GlobalDocumentDB" : "MongoDB"
  cosmosdb_failover_location      = var.deploy_azure_cosmosdb == "true" ? var.cosmosdb_failover_location : var.location
  cosmosdb_account_kind           = var.cosmosdb_account_kind != "" ? var.cosmosdb_account_kind : local.default_cosmosdb_account_kind
  deploy_azure_container_registry = var.deploy_azure_container_registry == "true" ? true : false
  deploy_azure_workload_identity  = var.deploy_azure_workload_identity == "true" ? true : false
  deploy_azure_openai             = var.deploy_azure_openai == "true" ? true : false
  ai_location                     = var.ai_location == "" ? var.location : var.ai_location
  deploy_azure_openai_dalle_model = var.deploy_azure_openai_dalle_model == "true" ? true : false
  deploy_azure_servicebus         = var.deploy_azure_servicebus == "true" ? true : false
  deploy_observability_tools      = var.deploy_observability_tools == "true" ? true : false
}