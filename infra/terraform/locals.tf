locals {
  name                          = "${random_pet.example.id}${random_integer.example.result}"
  location                      = var.location
  default_cosmosdb_account_kind = "MongoDB"
  cosmosdb_account_kind         = var.cosmosdb_account_kind != "" ? var.cosmosdb_account_kind : local.default_cosmosdb_account_kind
  deploy_acr                    = var.deploy_acr == "true" ? true : false
}