resource "azurerm_servicebus_namespace" "example" {
  name                = "sb-${local.name}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
}

resource "azurerm_servicebus_namespace_authorization_rule" "example" {
  name         = "listener"
  namespace_id = azurerm_servicebus_namespace.example.id

  listen = true
  send   = false
  manage = false
}

resource "azurerm_servicebus_queue" "example" {
  name         = "orders"
  namespace_id = azurerm_servicebus_namespace.example.id
}

resource "azurerm_servicebus_queue_authorization_rule" "example" {
  name     = "sender"
  queue_id = azurerm_servicebus_queue.example.id

  listen = false
  send   = true
  manage = false
}

