terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.113.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "=2.5.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "=3.6.1"
    }
  }
}

provider "azurerm" {
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
  length    = 2
  separator = ""
  keepers = {
    location = var.location
  }
}

data "http" "ifconfig" {
  url = "http://ifconfig.me"
}

data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = "rg-${var.resource_group_name_suffix}"
  location = local.location
}
