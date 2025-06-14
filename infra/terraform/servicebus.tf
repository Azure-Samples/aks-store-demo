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

module "avm-res-authorization-roleassignment-sb" {
  count   = local.deploy_azure_servicebus ? 1 : 0
  source  = "Azure/avm-res-authorization-roleassignment/azurerm"
  version = "0.2.0"
  # users_by_object_id = {
  #   current_user = data.azurerm_client_config.current.object_id
  # }
  groups_by_object_id = {
    demo_group = azuread_group.example.object_id
  }
  role_definitions = {
    service_bus_data_owner_role = {
      name = "Azure Service Bus Data Owner"
    }
  }
  role_assignments_for_scopes = {
    service_bus_role_assignments = {
      scope = module.sb[0].resource_id
      role_assignments = {
        role_assignment_1 = {
          role_definition = "service_bus_data_owner_role"
          any_principals  = ["demo_group"]
        }
      }
    }
  }
}
