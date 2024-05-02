resource "azurerm_servicebus_namespace" "example" {
  count               = local.deploy_azure_servicebus ? 1 : 0
  name                = "sb-${local.name}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  local_auth_enabled  = !local.deploy_azure_workload_identity
}

resource "azurerm_servicebus_queue" "example" {
  count        = local.deploy_azure_servicebus ? 1 : 0
  name         = "orders"
  namespace_id = azurerm_servicebus_namespace.example[0].id
}

resource "azurerm_servicebus_namespace_authorization_rule" "example" {
  count        = local.deploy_azure_servicebus && !local.deploy_azure_workload_identity ? 1 : 0
  name         = "listener"
  namespace_id = azurerm_servicebus_namespace.example[0].id

  listen = true
  send   = false
  manage = false
}

resource "azurerm_servicebus_queue_authorization_rule" "example" {
  count    = local.deploy_azure_servicebus && !local.deploy_azure_workload_identity ? 1 : 0
  name     = "sender"
  queue_id = azurerm_servicebus_queue.example[0].id

  listen = false
  send   = true
  manage = false
}

