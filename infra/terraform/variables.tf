variable "location" {
  type = string
}

variable "ai_location" {
  description = "value of azure region for deploying azure ai service"
  type        = string
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