terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

locals {
  common_tags = {
    managed_by = "terraform"
    module     = "backup"
  }
}

# ============================================================================
# RECOVERY SERVICES VAULT
# ============================================================================
resource "azurerm_recovery_services_vault" "main" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  sku                         = var.sku
  soft_delete_enabled         = var.soft_delete_enabled
  immutability_enabled        = var.purge_protection_enabled
  public_network_access_enabled = false
  cross_region_restore_enabled = true

  storage_mode_type = "LocallyRedundant"

  tags = merge(local.common_tags, var.tags)
}

# ============================================================================
# BACKUP POLICIES - VM
# ============================================================================
resource "azurerm_backup_policy_vm" "main" {
  for_each = {
    for name, policy in var.backup_policies :
    name => policy
    if policy.resource_type == "VirtualMachine"
  }

  name                = each.key
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name
  timezone            = "UTC"

  backup {
    frequency = each.value.frequency
    time      = lookup(each.value, "time", "03:00")
    weekdays  = lookup(each.value, "weekdays", ["Sunday"])
  }

  retention_daily {
    count = each.value.frequency == "Daily" ? 1 : 0
    count = each.value.retention_days
  }

  retention_weekly {
    count    = each.value.frequency == "Weekly" ? 1 : 0
    count    = 12  # 12 weeks
    weekdays = lookup(each.value, "weekdays", ["Sunday"])
  }

  retention_monthly {
    count             = each.value.frequency == "Monthly" ? 1 : 0
    count             = 12  # 12 months
    format            = "First"
    monthdays         = [1]
    include_last_days = false
  }
}

# ============================================================================
# BACKUP POLICIES - SQL
# ============================================================================
resource "azurerm_backup_policy_sql_database" "main" {
  for_each = {
    for name, policy in var.backup_policies :
    name => policy
    if policy.resource_type == "SQLDatabase"
  }

  name                = each.key
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name

  backup {
    frequency       = "Daily"
    backup_hour     = lookup(each.value, "backup_hour", 2)
    backup_minute   = lookup(each.value, "backup_minute", 0)
  }

  retention_daily {
    count = lookup(each.value, "retention_daily", each.value.retention_days)
  }

  retention_weekly {
    count    = 12
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count             = 12
    format            = "First"
    monthdays         = [1]
    include_last_days = true
  }

  retention_yearly {
    count             = 5
    format            = "First"
    monthdays         = [1]
    months            = ["January"]
    include_last_days = true
  }

  transaction_log_retention_days = lookup(each.value, "transaction_log_retention_days", 15)
}

# ============================================================================
# BACKUP POLICIES - FILE SHARE
# ============================================================================
resource "azurerm_backup_policy_file_share" "main" {
  for_each = {
    for name, policy in var.backup_policies :
    name => policy
    if policy.resource_type == "FileShare"
  }

  name                = each.key
  resource_group_name = var.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.main.name

  backup {
    frequency = each.value.frequency
    time      = lookup(each.value, "time", "03:00")
  }

  retention_daily {
    count = lookup(each.value, "retention_daily", each.value.retention_days)
  }

  retention_weekly {
    count    = 12
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count             = 12
    format            = "First"
    monthdays         = [1]
    include_last_days = true
  }

  retention_yearly {
    count             = 5
    format            = "First"
    monthdays         = [1]
    months            = ["January"]
    include_last_days = true
  }
}

# ============================================================================
# DIAGNOSTIC SETTINGS
# ============================================================================
resource "azurerm_monitor_diagnostic_setting" "vault" {
  count = var.enable_diagnostics && var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.name}-diagnostics"
  target_resource_id         = azurerm_recovery_services_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "CoreAzureBackup"
  }

  enabled_log {
    category = "AddonAzureBackupJobs"
  }

  enabled_log {
    category = "AddonAzureBackupAlerts"
  }

  enabled_log {
    category = "AddonAzureBackupPolicy"
  }

  enabled_log {
    category = "AddonAzureBackupProtectedInstance"
  }

  enabled_log {
    category = "AddonAzureBackupStorage"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
