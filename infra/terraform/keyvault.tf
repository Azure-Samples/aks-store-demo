resource "azurerm_key_vault" "example" {
  count                       = !local.deploy_azure_workload_identity ? 1 : 0
  name                        = "akv-${local.name}"
  location                    = azurerm_resource_group.example.location
  resource_group_name         = azurerm_resource_group.example.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  enable_rbac_authorization   = var.kv_rbac_enabled
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules = [
      "${data.http.ifconfig.response_body}/32"
    ]
  }

  dynamic "access_policy" {
    for_each = var.kv_rbac_enabled ? [] : [1]
    content {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = data.azurerm_client_config.current.object_id

      certificate_permissions = [
        "Backup",
        "Create",
        "Delete",
        "DeleteIssuers",
        "Get",
        "GetIssuers",
        "Import",
        "List",
        "ListIssuers",
        "ManageContacts",
        "ManageIssuers",
        "Purge",
        "Recover",
        "Restore",
        "SetIssuers",
        "Update"
      ]

      key_permissions = [
        "Backup",
        "Create",
        "Decrypt",
        "Delete",
        "Encrypt",
        "Get",
        "Import",
        "List",
        "Purge",
        "Recover",
        "Restore",
        "Sign",
        "UnwrapKey",
        "Update",
        "Verify",
        "WrapKey",
        "Release",
        "Rotate",
        "GetRotationPolicy",
        "SetRotationPolicy"
      ]

      secret_permissions = [
        "Backup",
        "Delete",
        "Get",
        "List",
        "Purge",
        "Recover",
        "Restore",
        "Set"
      ]

      storage_permissions = [
        "Backup",
        "Delete",
        "DeleteSAS",
        "Get",
        "GetSAS",
        "List",
        "ListSAS",
        "Purge",
        "Recover",
        "RegenerateKey",
        "Restore",
        "Set",
        "SetSAS",
        "Update"
      ]
    }
  }
}

resource "azurerm_role_assignment" "example_akv_rbac" {
  count                = var.kv_rbac_enabled && !local.deploy_azure_workload_identity ? 1 : 0
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.example[0].id
}

resource "azurerm_key_vault_secret" "openai_key" {
  count        = local.deploy_azure_openai && !local.deploy_azure_workload_identity ? 1 : 0
  name         = "AZURE-OPENAI-KEY"
  value        = azurerm_cognitive_account.example[0].primary_access_key
  key_vault_id = azurerm_key_vault.example[0].id
  depends_on   = [azurerm_role_assignment.example_akv_rbac]
}

resource "azurerm_key_vault_secret" "cosmosdb_key" {
  count        = local.deploy_azure_cosmosdb && !local.deploy_azure_workload_identity ? 1 : 0
  name         = "AZURE-COSMOS-KEY"
  value        = azurerm_cosmosdb_account.example[0].primary_key
  key_vault_id = azurerm_key_vault.example[0].id
  depends_on   = [azurerm_role_assignment.example_akv_rbac]
}

resource "azurerm_key_vault_secret" "listener_key" {
  count        = local.deploy_azure_servicebus && !local.deploy_azure_workload_identity ? 1 : 0
  name         = "AZURE-SERVICE-BUS-LISTENER-KEY"
  value        = azurerm_servicebus_namespace_authorization_rule.example[0].primary_key
  key_vault_id = azurerm_key_vault.example[0].id
  depends_on   = [azurerm_role_assignment.example_akv_rbac]
}

resource "azurerm_key_vault_secret" "sender_key" {
  count        = local.deploy_azure_servicebus && !local.deploy_azure_workload_identity ? 1 : 0
  name         = "AZURE-SERVICE-BUS-SENDER-KEY"
  value        = azurerm_servicebus_queue_authorization_rule.example[0].primary_key
  key_vault_id = azurerm_key_vault.example[0].id
  depends_on   = [azurerm_role_assignment.example_akv_rbac]
}
