// https://github.com/Azure/terraform-azurerm-avm-res-containerregistry-registry/
module "acr" {
  count               = local.deploy_azure_container_registry ? 1 : 0
  source              = "Azure/avm-res-containerregistry-registry/azurerm"
  version             = "0.4.0"
  name                = "acr${local.name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

// https://github.com/Azure/terraform-azurerm-avm-res-containerservice-managedcluster/
module "aks" {
  source                    = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version                   = "0.1.7"
  name                      = "aks-${local.name}"
  resource_group_name       = azurerm_resource_group.example.name
  location                  = azurerm_resource_group.example.location
  node_os_channel_upgrade   = "SecurityPatch"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  local_account_disabled    = true

  api_server_access_profile = {
    authorized_ip_ranges = ["${chomp(data.http.current_ip.response_body)}/32"]
  }

  azure_active_directory_role_based_access_control = {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  default_node_pool = {
    name       = "system"
    vm_size    = local.aks_node_pool_vm_size
    node_count = 3
    upgrade_settings = {
      max_surge = "10%"
    }
  }

  network_profile = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
  }

  key_vault_secrets_provider = {
    secret_rotation_enabled = true
  }

  managed_identities = {
    system_assigned = true
  }

  monitor_metrics = local.deploy_observability_tools ? {} : null
  oms_agent = local.deploy_observability_tools ? {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.example[0].id
    msi_auth_for_monitoring_enabled = true
  } : null
}

// https://github.com/Azure/terraform-azurerm-avm-res-authorization-roleassignment/
module "aks-role" {
  source  = "Azure/avm-res-authorization-roleassignment/azurerm"
  version = "0.2.0"
  # users_by_object_id = {
  #   current_user = data.azurerm_client_config.current.object_id
  # }
  groups_by_object_id = {
    demo_group = azuread_group.example.object_id
  }
  role_definitions = {
    aks_cluster_admin_role = {
      name = "Azure Kubernetes Service RBAC Cluster Admin"
    }
  }
  role_assignments_for_scopes = {
    aks_cluster_role_assignments = {
      scope = module.aks.resource_id
      role_assignments = {
        role_assignment_1 = {
          role_definition = "aks_cluster_admin_role"
          groups          = ["demo_group"]
        }
      }
    }
  }
}

module "acr-role" {
  count   = local.deploy_azure_container_registry ? 1 : 0
  source  = "Azure/avm-res-authorization-roleassignment/azurerm"
  version = "0.2.0"
  user_assigned_managed_identities_by_principal_id = {
    kubelet_identity = module.aks.kubelet_identity_id
  }
  role_definitions = {
    acr_pull_role = {
      name = "AcrPull"
    }
  }
  role_assignments_for_scopes = {
    acr_role_assignments = {
      scope = module.acr[0].resource_id
      role_assignments = {
        role_assignment_1 = {
          role_definition                  = "acr_pull_role"
          user_assigned_managed_identities = ["kubelet_identity"]
        }
      }
    }
  }
  depends_on = [module.aks]
}
