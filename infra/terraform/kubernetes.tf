resource "azurerm_container_registry" "example" {
  count               = local.deploy_azure_container_registry ? 1 : 0
  name                = "acr${local.name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Premium"
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "aks-${local.name}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "aks-${local.name}"

  default_node_pool {
    name       = "system"
    vm_size    = local.aks_node_pool_vm_size
    node_count = 3

    upgrade_settings {
      max_surge = "10%"
    }
  }

  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  api_server_access_profile {
    authorized_ip_ranges = [
      "${data.http.ifconfig.response_body}/32"
    ]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
  }

  identity {
    type = "SystemAssigned"
  }

  node_os_channel_upgrade   = "SecurityPatch"
  oidc_issuer_enabled       = local.deploy_azure_workload_identity
  workload_identity_enabled = local.deploy_azure_workload_identity

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  dynamic "monitor_metrics" {
    for_each = local.deploy_observability_tools ? [1] : []
    content {
    }
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.example.id
    msi_auth_for_monitoring_enabled = true
  }

  lifecycle {
    ignore_changes = [
      monitor_metrics,
      azure_policy_enabled,
      microsoft_defender
    ]
  }
}

resource "azurerm_role_assignment" "aks_cluster_admin" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.example.id
}

resource "azurerm_role_assignment" "example" {
  count                            = local.deploy_azure_container_registry ? 1 : 0
  principal_id                     = azurerm_kubernetes_cluster.example.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.example[0].id
  skip_service_principal_aad_check = true
}