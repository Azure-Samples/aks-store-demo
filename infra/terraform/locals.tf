locals {
  name                            = "${random_pet.example.id}${random_integer.example.result}"
  location                        = var.location
  default_cosmosdb_account_kind   = var.deploy_azure_workload_identity == "true" ? "GlobalDocumentDB" : "MongoDB"
  cosmosdb_account_kind           = var.cosmosdb_account_kind != "" ? var.cosmosdb_account_kind : local.default_cosmosdb_account_kind
  deploy_azure_container_registry = var.deploy_azure_container_registry == "true" ? true : false
  deploy_azure_workload_identity  = var.deploy_azure_workload_identity == "true" ? true : false
  deploy_azure_openai             = var.deploy_azure_openai == "true" ? true : false
  deploy_azure_servicebus         = var.deploy_azure_servicebus == "true" ? true : false
  deploy_azure_cosmosdb           = var.deploy_azure_cosmosdb == "true" ? true : false
  deploy_observability_tools      = var.deploy_observability_tools == "true" ? true : false
}