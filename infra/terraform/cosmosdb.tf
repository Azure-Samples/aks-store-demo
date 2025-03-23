// https://github.com/Azure/terraform-azurerm-avm-res-documentdb-databaseaccount/
module "db" {
  count                         = local.deploy_azure_cosmosdb ? 1 : 0
  source                        = "Azure/avm-res-documentdb-databaseaccount/azurerm"
  version                       = "0.7.0"
  name                          = "db-${local.name}"
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  minimal_tls_version           = "Tls12"
  public_network_access_enabled = true
  # network_acl_bypass_for_azure_services = true
  # ip_range_filter = [
  #   "0.0.0.0",
  #   "${chomp(data.http.current_ip.response_body)}/32"
  # ]

  capabilities = local.cosmosdb_account_kind == "MongoDB" ? [
    {
      name = "EnableAggregationPipeline"
    },
    {
      name = "EnableMongo"
    }
    ] : [
    {
      name = "EnableAggregationPipeline"
    }
  ]

  mongo_server_version = local.cosmosdb_account_kind == "MongoDB" ? "4.2" : null
  mongo_databases = local.cosmosdb_account_kind == "MongoDB" ? {
    database_with_collections = {
      name       = "orderdb"
      throughput = 400
      collections = {
        orders_collection = {
          name       = "orders"
          throughput = 400
          # index = {
          #   keys = ["_id"]
          # }
        }
      }
    }
  } : null

  sql_databases = local.cosmosdb_account_kind == "GlobalDocumentDB" ? {
    database_with_containers = {
      name       = "orderdb"
      throughput = 400
      containers = {
        orders_container = {
          name                = "orders"
          partition_key_paths = ["/storeId"]
        }
      }
    }
  } : null
}
