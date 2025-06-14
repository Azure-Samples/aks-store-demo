// https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/
module "aoai" {
  count                 = local.deploy_azure_openai ? 1 : 0
  source                = "Azure/avm-res-cognitiveservices-account/azurerm"
  version               = "0.6.0"
  name                  = "openai-${local.name}"
  custom_subdomain_name = "openai-${local.name}"
  resource_group_name   = azurerm_resource_group.example.name
  location              = var.azure_openai_location
  kind                  = "OpenAI"
  sku_name              = "S0"
  local_auth_enabled    = false

  cognitive_deployments = merge(
    {
      "chat_completion" = {
        name = var.chat_completion_model_name
        model = {
          format  = "OpenAI"
          name    = var.chat_completion_model_name
          version = var.chat_completion_model_version
        }
        scale = {
          type     = var.chat_completion_model_type
          capacity = var.chat_completion_model_capacity
        }
      }
    },
    local.deploy_image_generation_model ? {
      "image_generation" = {
        name = var.image_generation_model_name
        model = {
          format  = "OpenAI"
          name    = var.image_generation_model_name
          version = var.image_generation_model_version
        }
        scale = {
          type     = var.image_generation_model_type
          capacity = var.image_generation_model_capacity
        }
      }
    } : {}
  )
}

module "aoai-role" {
  count   = local.deploy_azure_openai ? 1 : 0
  source  = "Azure/avm-res-authorization-roleassignment/azurerm"
  version = "0.2.0"
  # users_by_object_id = {
  #   current_user = data.azurerm_client_config.current.object_id
  # }
  groups_by_object_id = {
    "demo_group" = azuread_group.example.object_id
  }
  role_definitions = {
    cognitive_services_openai_user_role = {
      name = "Cognitive Services OpenAI User"
    }
  }
  role_assignments_for_scopes = {
    cognitive_services_role_assignments = {
      scope = module.aoai[0].resource_id
      role_assignments = {
        role_assignment_1 = {
          role_definition = "cognitive_services_openai_user_role"
          any_principals  = ["demo_group"]
        }
      }
    }
  }
}
