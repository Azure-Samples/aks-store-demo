// https://github.com/Azure/terraform-azurerm-avm-res-cognitiveservices-account/
module "aoai" {
  count                 = local.deploy_azure_openai ? 1 : 0
  source                = "Azure/avm-res-cognitiveservices-account/azurerm"
  version               = "0.10.0"
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

resource "azurerm_role_assignment" "openai_user" {
  count                = local.deploy_azure_openai ? 1 : 0
  scope                = module.aoai[0].resource_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = data.azurerm_client_config.current.object_id
}
