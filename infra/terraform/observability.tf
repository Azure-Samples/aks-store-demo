resource "azurerm_log_analytics_workspace" "example" {
  count               = local.deploy_observability_tools ? 1 : 0
  name                = "logs-${local.name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_workspace" "example" {
  count               = local.deploy_observability_tools ? 1 : 0
  name                = "metrics-${local.name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

resource "azurerm_dashboard_grafana" "example" {
  count                 = local.deploy_observability_tools ? 1 : 0
  name                  = "grafana-${substr(local.name, 0, 15)}"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  grafana_major_version = "11"

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.example[0].id
  }
}

resource "azurerm_role_assignment" "example_amg_me" {
  count                = local.deploy_observability_tools ? 1 : 0
  scope                = azurerm_dashboard_grafana.example[0].id
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "example_rg_amg" {
  count                = local.deploy_observability_tools ? 1 : 0
  principal_id         = azurerm_dashboard_grafana.example[0].identity[0].principal_id
  role_definition_name = "Monitoring Data Reader"
  scope                = azurerm_resource_group.example.id
}

resource "azurerm_monitor_data_collection_endpoint" "example_msprom" {
  count               = local.deploy_observability_tools ? 1 : 0
  name                = "MSProm-${azurerm_resource_group.example.location}-${module.aks.name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  kind                = "Linux"
}

resource "azurerm_monitor_data_collection_rule" "example_msprom" {
  count                       = local.deploy_observability_tools ? 1 : 0
  name                        = "MSProm-${azurerm_resource_group.example.location}-${module.aks.name}"
  resource_group_name         = azurerm_resource_group.example.name
  location                    = azurerm_resource_group.example.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.example_msprom[0].id

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.example[0].id
      name               = azurerm_monitor_workspace.example[0].name
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = [azurerm_monitor_workspace.example[0].name]
  }
}

resource "azurerm_monitor_data_collection_rule_association" "example_dcr_to_aks" {
  count                   = local.deploy_observability_tools ? 1 : 0
  name                    = "dcr-${module.aks.name}"
  target_resource_id      = module.aks.resource_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.example_msprom[0].id
}

resource "azurerm_monitor_data_collection_rule_association" "example_dce_to_aks" {
  count                       = local.deploy_observability_tools ? 1 : 0
  target_resource_id          = module.aks.resource_id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.example_msprom[0].id
}

resource "azurerm_monitor_alert_prometheus_rule_group" "example_node" {
  count               = local.deploy_observability_tools ? 1 : 0
  name                = "NodeRecordingRulesRuleGroup-${module.aks.name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  cluster_name        = module.aks.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.example[0].id]

  rule {
    record     = "instance:node_num_cpu:sum"
    expression = "count without (cpu, mode) (node_cpu_seconds_total{job=\"node\",mode=\"idle\"})"
  }

  rule {
    record     = "instance:node_cpu_utilisation:rate5m"
    expression = "1 - avg without (cpu) (sum without (mode) (rate(node_cpu_seconds_total{job=\"node\", mode=~\"idle|iowait|steal\"}[5m])))"
  }

  rule {
    record     = "instance:node_load1_per_cpu:ratio"
    expression = "(node_load1{job=\"node\"}/  instance:node_num_cpu:sum{job=\"node\"})"
  }

  rule {
    record     = "instance:node_memory_utilisation:ratio"
    expression = "1 - ((node_memory_MemAvailable_bytes{job=\"node\"} or (node_memory_Buffers_bytes{job=\"node\"} + node_memory_Cached_bytes{job=\"node\"} + node_memory_MemFree_bytes{job=\"node\"} + node_memory_Slab_bytes{job=\"node\"})) / node_memory_MemTotal_bytes{job=\"node\"})"
  }

  rule {
    record     = "instance:node_vmstat_pgmajfault:rate5m"
    expression = "rate(node_vmstat_pgmajfault{job=\"node\"}[5m])"
  }

  rule {
    record     = "instance_device:node_disk_io_time_seconds:rate5m"
    expression = "rate(node_disk_io_time_seconds_total{job=\"node\", device!=\"\"}[5m])"
  }

  rule {
    record     = "instance_device:node_disk_io_time_weighted_seconds:rate5m"
    expression = "rate(node_disk_io_time_weighted_seconds_total{job=\"node\", device!=\"\"}[5m])"
  }

  rule {
    record     = "instance:node_network_receive_bytes_excluding_lo:rate5m"
    expression = "sum without (device) (rate(node_network_receive_bytes_total{job=\"node\", device!=\"lo\"}[5m]))"
  }

  rule {
    record     = "instance:node_network_transmit_bytes_excluding_lo:rate5m"
    expression = "sum without (device) (rate(node_network_transmit_bytes_total{job=\"node\", device!=\"lo\"}[5m]))"
  }

  rule {
    record     = "instance:node_network_receive_drop_excluding_lo:rate5m"
    expression = "sum without (device) (rate(node_network_receive_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
  }

  rule {
    record     = "instance:node_network_transmit_drop_excluding_lo:rate5m"
    expression = "sum without (device) (rate(node_network_transmit_drop_total{job=\"node\", device!=\"lo\"}[5m]))"
  }
}

resource "azurerm_monitor_alert_prometheus_rule_group" "example_k8s" {
  count               = local.deploy_observability_tools ? 1 : 0
  name                = "KubernetesRecordingRulesRuleGroup-${module.aks.name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  cluster_name        = module.aks.name
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.example[0].id]

  rule {
    record     = "node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate"
    expression = "sum by (cluster, namespace, pod, container) (irate(container_cpu_usage_seconds_total{job=\"cadvisor\", image!=\"\"}[5m])) * on (cluster, namespace, pod) group_left(node) topk by (cluster, namespace, pod) (1, max by(cluster, namespace, pod, node) (kube_pod_info{node!=\"\"}))"
  }


  rule {
    record     = "node_namespace_pod_container:container_memory_working_set_bytes"
    expression = "container_memory_working_set_bytes{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1, max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
  }

  rule {
    record     = "node_namespace_pod_container:container_memory_rss"
    expression = "container_memory_rss{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1, max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
  }

  rule {
    record     = "node_namespace_pod_container:container_memory_cache"
    expression = "container_memory_cache{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1, max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
  }

  rule {
    record     = "node_namespace_pod_container:container_memory_swap"
    expression = "container_memory_swap{job=\"cadvisor\", image!=\"\"}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1, max by(namespace, pod, node) (kube_pod_info{node!=\"\"}))"
  }

  rule {
    record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_requests"
    expression = "kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"} * on(namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ((kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
  }

  rule {
    record     = "namespace_memory:kube_pod_container_resource_requests:sum"
    expression = "sum by (namespace, cluster) (sum by (namespace, pod, cluster) (max by (namespace, pod, container, cluster) (kube_pod_container_resource_requests{resource=\"memory\",job=\"kube-state-metrics\"}) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)))"
  }

  rule {
    record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests"
    expression = "kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"} * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ((kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
  }

  rule {
    record     = "namespace_cpu:kube_pod_container_resource_requests:sum"
    expression = "sum by (namespace, cluster) (sum by(namespace, pod, cluster) (max by(namespace, pod, container, cluster) (kube_pod_container_resource_requests{resource=\"cpu\",job=\"kube-state-metrics\"}) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)))"
  }

  rule {
    record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_limits"
    expression = "kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"} * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ((kube_pod_status_phase{phase=~\"Pending|Running\"} == 1))"
  }

  rule {
    record     = "namespace_memory:kube_pod_container_resource_limits:sum"
    expression = "sum by (namespace, cluster) (sum by (namespace, pod, cluster) (max by (namespace, pod, container, cluster) (kube_pod_container_resource_limits{resource=\"memory\",job=\"kube-state-metrics\"}) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)))"
  }

  rule {
    record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits"
    expression = "kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"} * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ( (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1) )"
  }

  rule {
    record     = "namespace_cpu:kube_pod_container_resource_limits:sum"
    expression = "sum by (namespace, cluster) (sum by (namespace, pod, cluster) (max by(namespace, pod, container, cluster) (kube_pod_container_resource_limits{resource=\"cpu\",job=\"kube-state-metrics\"}) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (kube_pod_status_phase{phase=~\"Pending|Running\"} == 1)))"
  }

  rule {
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = "max by (cluster, namespace, workload, pod) (label_replace(label_replace(kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"ReplicaSet\"}, \"replicaset\", \"$1\", \"owner_name\", \"(.*)\") * on(replicaset, namespace) group_left(owner_name) topk by(replicaset, namespace) (1, max by (replicaset, namespace, owner_name) (kube_replicaset_owner{job=\"kube-state-metrics\"})), \"workload\", \"$1\", \"owner_name\", \"(.*)\"))"
    labels = {
      "workload_type" = "deployment"
    }
  }

  rule {
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = "max by (cluster, namespace, workload, pod) (label_replace(kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"DaemonSet\"}, \"workload\", \"$1\", \"owner_name\", \"(.*)\"))"
    labels = {
      "workload_type" = "daemonset"
    }
  }

  rule {
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = "max by (cluster, namespace, workload, pod) (label_replace(kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"StatefulSet\"}, \"workload\", \"$1\", \"owner_name\", \"(.*)\"))"
    labels = {
      "workload_type" = "statefulset"
    }
  }

  rule {
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = "max by (cluster, namespace, workload, pod) (label_replace(kube_pod_owner{job=\"kube-state-metrics\", owner_kind=\"Job\"}, \"workload\", \"$1\", \"owner_name\", \"(.*)\"))"
    labels = {
      "workload_type" = "job"
    }
  }

  rule {
    record     = ":node_memory_MemAvailable_bytes:sum"
    expression = "sum(node_memory_MemAvailable_bytes{job=\"node\"} or (node_memory_Buffers_bytes{job=\"node\"} + node_memory_Cached_bytes{job=\"node\"} + node_memory_MemFree_bytes{job=\"node\"} + node_memory_Slab_bytes{job=\"node\"})) by (cluster)"
  }

  rule {
    record     = "cluster:node_cpu:ratio_rate5m"
    expression = "sum(rate(node_cpu_seconds_total{job=\"node\",mode!=\"idle\",mode!=\"iowait\",mode!=\"steal\"}[5m])) by (cluster) /count(sum(node_cpu_seconds_total{job=\"node\"}) by (cluster, instance, cpu)) by (cluster)"
  }
}

resource "azurerm_monitor_data_collection_rule" "example_msci" {
  count               = local.deploy_observability_tools ? 1 : 0
  name                = "MSCI-${azurerm_resource_group.example.location}-${module.aks.name}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  kind                = "Linux"

  data_sources {
    extension {
      name           = "ContainerInsightsExtension"
      extension_name = "ContainerInsights"
      streams        = ["Microsoft-ContainerInsights-Group-Default"]
      extension_json = <<JSON
      {
        "dataCollectionSettings": {
          "interval": "1m",
          "namespaceFilteringMode": "Off",
          "enableContainerLogV2": true
        }
      }
      JSON
    }
  }

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.example[0].id
      name                  = azurerm_log_analytics_workspace.example[0].name
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
    destinations = [azurerm_log_analytics_workspace.example[0].name]
  }
}

resource "azurerm_monitor_data_collection_rule_association" "example_msci_to_aks" {
  count                   = local.deploy_observability_tools ? 1 : 0
  name                    = "msci-${module.aks.name}"
  target_resource_id      = module.aks.resource_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.example_msci[0].id
}
