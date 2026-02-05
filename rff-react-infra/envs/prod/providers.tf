terraform {
  required_version = ">= 1.5"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.57.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true # Prevent accidental deletion in prod
    }
    key_vault {
      purge_soft_delete_on_destroy    = false # Keep soft delete in prod
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.subscription_id
}
