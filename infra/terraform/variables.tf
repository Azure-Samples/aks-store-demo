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
  default     = "default"
}

variable "cosmosdb_account_kind" {
  description = "value of cosmosdb account kind. this string value will be used to set the local variable"
  type        = string
  default     = "MongoDB"

  # validation {
  #   condition     = contains(["MongoDB", "GlobalDocumentDB"], local.cosmosdb_account_kind)
  #   error_message = "Valid values for var: cosmosdb_account_kind are (MongoDB, GlobalDocumentDB)."
  # }
}

variable "deploy_acr" {
  description = "value of deploy acr. this string value will be used to set the local variable"
  type        = string
  default     = "false"
}
