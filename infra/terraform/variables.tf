variable "location" {
  description = "value of azure location to deploy resources"
  type        = string
}

variable "environment" {
  description = "value of environment name which will be used to prefix resources"
  type        = string
}

variable "aks_node_pool_vm_size" {
  description = "value of azure kubernetes node pool vm size"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "k8s_namespace" {
  description = "value of kubernetes namespace"
  type        = string
  default     = "pets"
}

variable "deploy_observability_tools" {
  description = "value to determine if observability tools should be deployed"
  type        = string
  default     = "false"
}

variable "deploy_azure_container_registry" {
  description = "value to determine if azure container registry should be deployed"
  type        = string
  default     = "false"
}

variable "deploy_azure_servicebus" {
  description = "value to determine if azure servicebus should be deployed"
  type        = string
  default     = "false"
}

variable "deploy_azure_cosmosdb" {
  description = "value to determine if azure cosmosdb should be deployed"
  type        = string
  default     = "false"
}

variable "cosmosdb_account_kind" {
  description = "value of azure cosmosdb account kind. this string value defaults to GlobalDocumentDB and will be used to set the local variable"
  type        = string
  default     = "GlobalDocumentDB"

  # validation {
  #   condition     = contains(["MongoDB", "GlobalDocumentDB"], local.cosmosdb_account_kind)
  #   error_message = "Valid values for var: cosmosdb_account_kind are (MongoDB, GlobalDocumentDB)."
  # }
}

variable "deploy_azure_openai" {
  description = "value to determine if azure openai should be deployed"
  type        = string
  default     = "false"
}

variable "azure_openai_location" {
  description = "value of azure location for ai resources"
  type        = string
  default     = ""
}

variable "chat_completion_model_name" {
  description = "value of azure openai model name"
  type        = string
  default     = "gpt-35-turbo"
}

variable "chat_completion_model_version" {
  description = "value of azure openai model version"
  type        = string
  default     = "0125"
}

variable "chat_completion_model_capacity" {
  description = "value of azure openai model capacity"
  type        = number
  default     = 8
}

variable "deploy_image_generation_model" {
  description = "value to determine if azure openai dall-e model should be deployed"
  type        = string
  default     = "false"
}

variable "image_generation_model_name" {
  description = "value of azure openai dall-e-3 model name"
  type        = string
  default     = "dall-e-3"
}

variable "image_generation_model_version" {
  description = "value of azure openai dall-e-3 model version"
  type        = string
  default     = "3.0"
}

variable "image_generation_model_capacity" {
  description = "value of azure openai dall-e-3 model capacity"
  type        = number
  default     = 1
}
