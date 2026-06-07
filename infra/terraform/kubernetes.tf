// https://github.com/Azure/terraform-azurerm-avm-res-containerregistry-registry/
module "acr" {
  count               = local.deploy_azure_container_registry ? 1 : 0
  source              = "Azure/avm-res-containerregistry-registry/azurerm"
  version             = "0.5.1"
  name                = "acr${local.name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

// https://github.com/Azure/terraform-azurerm-avm-res-containerservice-managedcluster/
module "aks" {
  source    = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version   = "0.6.1"
  name      = "aks-${local.name}"
  parent_id = azurerm_resource_group.example.id
  location  = azurerm_resource_group.example.location

  auto_upgrade_profile = {
    node_os_channel_upgrade = "SecurityPatch"
  }

  oidc_issuer_profile = {
    enabled = true
  }

  security_profile = {
    workload_identity = {
      enabled = true
    }
  }

  disable_local_accounts = true

  api_server_access_profile = {
    authorized_ip_ranges = ["${chomp(data.http.current_ip.response_body)}/32"]
  }

  aad_profile = {
    managed           = true
    enable_azure_rbac = true
    tenant_id         = data.azurerm_client_config.current.tenant_id
  }

  default_agent_pool = {
    vm_size = local.aks_node_pool_vm_size
    upgrade_settings = {
      max_surge = "10%"
    }
  }

  network_profile = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_dataplane   = "cilium"
  }

  addon_profile_key_vault_secrets_provider = {
    enabled = true
    config = {
      enable_secret_rotation = true
    }
  }

  managed_identities = {
    system_assigned = true
  }

  azure_monitor_profile = local.deploy_observability_tools ? {
    enabled = true
    kube_state_metrics = {
      metric_annotations_allow_list = "*"
      metric_labels_allowlist       = "*"
    }
  } : null

  addon_profile_oms_agent = local.deploy_observability_tools ? {
    enabled = true
    config = {
      log_analytics_workspace_resource_id = azurerm_log_analytics_workspace.example[0].id
      use_aad_auth                        = true
    }
  } : null

  role_assignments = {
    "aks_cluster_admin" = {
      role_definition_id_or_name = "Azure Kubernetes Service RBAC Cluster Admin"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
}

// https://github.com/Azure/terraform-azurerm-avm-res-authorization-roleassignment/
// Assign AcrPull role to kubelet identity on ACR
resource "azurerm_role_assignment" "acr_pull" {
  count                = local.deploy_azure_container_registry ? 1 : 0
  scope                = module.acr[0].resource_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity.objectId
  depends_on           = [module.aks]
}
