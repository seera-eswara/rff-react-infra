terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# ============================================================================
# STORAGE LIFECYCLE MANAGEMENT
# ============================================================================
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = data.azurerm_storage_account.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.key
      enabled = rule.value.enabled

      filters {
        prefix_match       = lookup(rule.value.filters, "prefix", [""])
        blob_types         = lookup(rule.value.filters, "blob_types", ["blockBlob"])
      }

      actions {
        dynamic "base_blob" {
          for_each = rule.value.actions != null ? [rule.value.actions] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than    = lookup(base_blob.value, "cool_after_days", null)
            tier_to_archive_after_days_since_modification_greater_than  = lookup(base_blob.value, "archive_after_days", null)
            delete_after_days_since_modification_greater_than           = lookup(base_blob.value, "delete_after_days", null)
          }
        }

        dynamic "snapshot" {
          for_each = lookup(rule.value.actions, "snapshot_delete_after_days", null) != null ? [rule.value.actions] : []
          content {
            delete_after_days_since_creation_greater_than = lookup(snapshot.value, "snapshot_delete_after_days", null)
          }
        }

        dynamic "version" {
          for_each = lookup(rule.value.actions, "version_delete_after_days", null) != null ? [rule.value.actions] : []
          content {
            delete_after_days_since_creation_greater_than = lookup(version.value, "version_delete_after_days", null)
          }
        }
      }
    }
  }
}

# Data source to reference existing storage account
data "azurerm_storage_account" "main" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

# Container index to track which containers are managed
locals {
  managed_containers = distinct(flatten([
    for rule_name, rule in var.lifecycle_rules :
    rule.container_names
  ]))
}
