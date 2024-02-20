resource "azurerm_cosmosdb_account" "example" {
  count               = local.deploy_azure_cosmosdb ? 1 : 0
  name                = "db-${local.name}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  offer_type          = "Standard"
  kind                = local.cosmosdb_account_kind

  enable_automatic_failover = false

  dynamic "capabilities" {
    for_each = local.cosmosdb_account_kind == "MongoDB" ? ["EnableAggregationPipeline", "mongoEnableDocLevelTTL", "MongoDBv3.4", "EnableMongo"] : ["EnableAggregationPipeline"]
    content {
      name = capabilities.value
    }
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "eastus"
    failover_priority = 1
  }

  geo_location {
    location          = "westus"
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_mongo_database" "example" {
  count               = local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "MongoDB" ? 1 : 0
  name                = "orderdb"
  resource_group_name = azurerm_cosmosdb_account.example[0].resource_group_name
  account_name        = azurerm_cosmosdb_account.example[0].name
  throughput          = 400
}

resource "azurerm_cosmosdb_mongo_collection" "example" {
  count               = local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "MongoDB" ? 1 : 0
  name                = "orders"
  resource_group_name = azurerm_cosmosdb_account.example[0].resource_group_name
  account_name        = azurerm_cosmosdb_account.example[0].name
  database_name       = azurerm_cosmosdb_mongo_database.example[0].name
  throughput          = 400

  index {
    keys = ["_id"]
  }

  lifecycle {
    ignore_changes = [index]
  }
}

resource "azurerm_cosmosdb_sql_database" "example" {
  count               = local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "GlobalDocumentDB" ? 1 : 0
  name                = "orderdb"
  resource_group_name = azurerm_cosmosdb_account.example[0].resource_group_name
  account_name        = azurerm_cosmosdb_account.example[0].name
  throughput          = 400
}

resource "azurerm_cosmosdb_sql_container" "example" {
  count                 = local.deploy_azure_cosmosdb && local.cosmosdb_account_kind == "GlobalDocumentDB" ? 1 : 0
  name                  = "orders"
  resource_group_name   = azurerm_cosmosdb_account.example[0].resource_group_name
  account_name          = azurerm_cosmosdb_account.example[0].name
  database_name         = azurerm_cosmosdb_sql_database.example[0].name
  partition_key_path    = "/storeId"
  partition_key_version = 1
  throughput            = 400
}
