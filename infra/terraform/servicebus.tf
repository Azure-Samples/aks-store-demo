// https://github.com/Azure/terraform-azurerm-avm-res-servicebus-namespace/
module "sb" {
  count               = local.deploy_azure_servicebus ? 1 : 0
  source              = "Azure/avm-res-servicebus-namespace/azurerm"
  version             = "0.4.0"
  name                = "sb-${local.name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"
  local_auth_enabled  = false

  queues = {
    orders = {}
  }

  # network_rule_config = {
  #   cidr_or_ip_rules = ["${chomp(data.http.current_ip.response_body)}/32"]
  # }
}

resource "azurerm_role_assignment" "service_bus_data_owner" {
  count                = local.deploy_azure_servicebus ? 1 : 0
  scope                = module.sb[0].resource_id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}
