output "vault_id" {
  value       = azurerm_recovery_services_vault.main.id
  description = "Recovery Services Vault resource ID"
}

output "vault_name" {
  value       = azurerm_recovery_services_vault.main.name
  description = "Recovery Services Vault name"
}

output "policy_ids" {
  value = merge(
    {
      for name, policy in azurerm_backup_policy_vm.main :
      name => policy.id
    },
    {
      for name, policy in azurerm_backup_policy_sql_database.main :
      name => policy.id
    },
    {
      for name, policy in azurerm_backup_policy_file_share.main :
      name => policy.id
    }
  )
  description = "Map of backup policy IDs by policy name"
}

output "vault_properties" {
  value = {
    id                    = azurerm_recovery_services_vault.main.id
    name                  = azurerm_recovery_services_vault.main.name
    sku                   = azurerm_recovery_services_vault.main.sku
    soft_delete_enabled   = azurerm_recovery_services_vault.main.soft_delete_enabled
    cross_region_restore  = azurerm_recovery_services_vault.main.cross_region_restore_enabled
  }
  description = "Complete Recovery Services Vault properties"
}
