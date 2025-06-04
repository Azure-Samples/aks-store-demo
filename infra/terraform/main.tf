terraform {
  required_version = ">= 1.9.2"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.2"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }

    http = {
      source  = "hashicorp/http"
      version = "=3.4.3"
    }
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    cognitive_account {
      purge_soft_delete_on_destroy = true
    }

    key_vault {
      purge_soft_delete_on_destroy = true
    }

    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
  }
}

resource "random_integer" "example" {
  min = 10
  max = 99
}

resource "random_pet" "example" {
  length    = 1
  separator = ""
  keepers = {
    location = var.location
  }
}

data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

data "http" "current_ip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  name                            = "${var.environment}${random_pet.example.id}${random_integer.example.result}"
  aks_node_pool_vm_size           = var.aks_node_pool_vm_size != "" ? var.aks_node_pool_vm_size : "Standard_DS2_v2"
  deploy_azure_cosmosdb           = var.deploy_azure_cosmosdb == "true" ? true : false
  default_cosmosdb_account_kind   = "GlobalDocumentDB"
  cosmosdb_account_kind           = var.cosmosdb_account_kind != "" ? var.cosmosdb_account_kind : local.default_cosmosdb_account_kind
  deploy_observability_tools      = var.deploy_observability_tools == "true" ? true : false
  deploy_azure_container_registry = var.deploy_azure_container_registry == "true" ? true : false
  deploy_azure_openai             = var.deploy_azure_openai == "true" ? true : false
  deploy_image_generation_model   = var.deploy_image_generation_model == "true" ? true : false
  deploy_azure_servicebus         = var.deploy_azure_servicebus == "true" ? true : false
}

resource "azurerm_resource_group" "example" {
  name     = "rg-${local.name}"
  location = var.location
}

resource "azuread_group" "example" {
  display_name     = "AKS Store Demo App"
  security_enabled = true
}

resource "azuread_group_member" "example" {
  group_object_id  = azuread_group.example.object_id
  member_object_id = data.azurerm_client_config.current.object_id
}
