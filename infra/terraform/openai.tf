resource "azurerm_cognitive_account" "example" {
  name                  = "aoai-${local.name}"
  location              = var.ai_location
  resource_group_name   = azurerm_resource_group.example.name
  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = "aoai-${local.name}"
}

resource "azurerm_cognitive_deployment" "example" {
  name                 = var.openai_model_name
  cognitive_account_id = azurerm_cognitive_account.example.id

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

resource "azurerm_user_assigned_identity" "example" {
  location            = var.ai_location
  name                = "aoai-${local.name}"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_federated_identity_credential" "example" {
  name                = "aoai-${local.name}"
  resource_group_name = azurerm_resource_group.example.name
  parent_id           = azurerm_user_assigned_identity.example.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.example.oidc_issuer_url
  subject             = "system:serviceaccount:${var.k8s_namespace}:ai-service-account"
}

resource "azurerm_role_assignment" "example_aoai_me" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Cognitive Services OpenAI User"
  scope                = azurerm_cognitive_account.example.id
}

resource "azurerm_role_assignment" "example_aoai_mi" {
  principal_id         = azurerm_user_assigned_identity.example.principal_id
  role_definition_name = "Cognitive Services OpenAI User"
  scope                = azurerm_cognitive_account.example.id
}