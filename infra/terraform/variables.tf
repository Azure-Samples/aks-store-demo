variable "resource_group_name_suffix" {
  description = "value of azure resource group name suffix"
  type        = string
  default     = "demo"
}

variable "location" {
  type = string
}

variable "aks_node_pool_vm_size" {
  description = "value of azure kubernetes service vmss sku"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "kv_rbac_enabled" {
  description = "value of keyvault rbac enabled. when set to true, key vault will use azure role-based access control"
  type        = bool
  default     = false
}

variable "ai_location" {
  description = "value of azure region for deploying azure ai service. check this doc for availability: https://learn.microsoft.com/azure/ai-services/openai/concepts/models#provisioned-deployment-model-availability"
  type        = string
  default     = ""
}

variable "openai_model_name" {
  description = "value of azure openai model name"
  type        = string
  default     = "gpt-35-turbo"
}

variable "openai_model_version" {
  description = "value of azure openai model version"
  type        = string
  default     = "0613"
}

variable "openai_model_capacity" {
  description = "value of azure openai model capacity"
  type        = number
  default     = 30
}

variable "openai_dalle_model_name" {
  description = "value of azure openai dall-e-3 model name"
  type        = string
  default     = "dall-e-3"
}

variable "openai_dalle_model_version" {
  description = "value of azure openai dall-e-3 model version"
  type        = string
  default     = "3.0"
}

variable "openai_dalle_model_capacity" {
  description = "value of azure openai dall-e-3 model capacity"
  type        = number
  default     = 1
}

variable "k8s_namespace" {
  description = "value of kubernetes namespace"
  type        = string
  default     = "pets"
}

variable "cosmosdb_account_kind" {
  description = "value of azure cosmosdb account kind. this string value defaults to MongoDB and will be used to set the local variable"
  type        = string
  default     = "MongoDB"

  # validation {
  #   condition     = contains(["MongoDB", "GlobalDocumentDB"], local.cosmosdb_account_kind)
  #   error_message = "Valid values for var: cosmosdb_account_kind are (MongoDB, GlobalDocumentDB)."
  # }
}

variable "cosmosdb_failover_location" {
  description = "value of azure cosmosdb failover location. check this doc for region pair listings: https://learn.microsoft.com/azure/reliability/cross-region-replication-azure"
  type        = string
  default     = ""
}


variable "deploy_azure_container_registry" {
  description = "value of setting to deploy azure container registry. this string value will be used to set the local boolean variable"
  type        = string
  default     = "false"
}

variable "deploy_azure_workload_identity" {
  description = "value of setting to deploy azure workload identity for service authentication. this string value will be used to set the local boolean variable"
  type        = string
  default     = "false"
}

variable "deploy_azure_openai" {
  description = "value of setting to deploy azure openai. this string value will be used to set the local boolean variable"
  type        = string
  default     = "false"
}

variable "deploy_azure_openai_dalle_model" {
  description = "value of setting to deploy azure openai dall-e-3 model. this string value will be used to set the local boolean variable"
  type        = string
  default     = "false"
}


variable "deploy_azure_servicebus" {
  description = "value of setting to deploy azure service bus. this string value will be used to set the local boolean variable"
  type        = string
  default     = "false"
}

variable "deploy_azure_cosmosdb" {
  description = "value of setting to deploy azure cosmosdb. this string value will be used to set the local boolean variable"
  type        = string
  default     = "false"
}

variable "deploy_observability_tools" {
  description = "value of setting to deploy observability stack which includes prometheus, grafana, and container insights. this string value will be used to set the local boolean variable"
  type        = string
  default     = "false"
}