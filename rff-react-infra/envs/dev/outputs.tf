output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

output "vnet_id" {
  description = "ID of the spoke VNet"
  value       = module.vnet.id
}

output "vnet_name" {
  description = "Name of the spoke VNet"
  value       = module.vnet.name
}

output "app_subnet_id" {
  description = "ID of the application subnet"
  value       = module.vnet.subnet_ids["snet-app"]
}

output "data_subnet_id" {
  description = "ID of the data subnet"
  value       = module.vnet.subnet_ids["snet-data"]
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage_account.name
}

output "storage_primary_web_endpoint" {
  description = "Primary web endpoint for static website"
  value       = module.storage_account.primary_web_endpoint
}

output "storage_containers" {
  description = "Created storage containers"
  value       = { for k, v in module.storage_containers : k => v.name }
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = module.key_vault.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.vault_uri
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = module.application_insights.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = module.application_insights.connection_string
  sensitive   = true
}

output "application_insights_app_id" {
  description = "Application Insights App ID"
  value       = module.application_insights.app_id
}
