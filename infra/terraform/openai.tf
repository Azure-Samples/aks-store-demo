resource "azurerm_cognitive_account" "example" {
  count                 = local.deploy_azure_openai ? 1 : 0
  name                  = "aoai-${local.name}"
  location              = var.ai_location
  resource_group_name   = azurerm_resource_group.example.name
  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = "aoai-${local.name}"
  local_auth_enabled    = !local.deploy_azure_workload_identity
}

resource "azurerm_cognitive_deployment" "gpt" {
  count                = local.deploy_azure_openai ? 1 : 0
  name                 = var.openai_model_name
  cognitive_account_id = azurerm_cognitive_account.example[0].id

  model {
    format  = "OpenAI"
    name    = var.openai_model_name
    version = var.openai_model_version
  }

  scale {
    type     = "Standard"
    capacity = var.openai_model_capacity
  }
}

resource "azurerm_cognitive_deployment" "dalle" {
  count                = local.deploy_azure_openai && local.deploy_azure_openai_dalle_model ? 1 : 0
  name                 = var.openai_dalle_model_name
  cognitive_account_id = azurerm_cognitive_account.example[0].id

  model {
    format  = "OpenAI"
    name    = var.openai_dalle_model_name
    version = var.openai_dalle_model_version
  }

  scale {
    type     = "Standard"
    capacity = var.openai_dalle_model_capacity
  }
}

resource "azurerm_role_assignment" "example_aoai_me" {
  count                = local.deploy_azure_openai ? 1 : 0
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Cognitive Services OpenAI User"
  scope                = azurerm_cognitive_account.example[0].id
}