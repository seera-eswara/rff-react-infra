output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.app.name
}

output "vnet_id" {
  description = "ID of the spoke VNet"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Name of the spoke VNet"
  value       = azurerm_virtual_network.spoke.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.app.name
}

output "storage_primary_web_endpoint" {
  description = "Primary web endpoint for static website"
  value       = azurerm_storage_account.app.primary_web_endpoint
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.app.id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.app.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.app.connection_string
  sensitive   = true
}
