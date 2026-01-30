output "id" {
  value       = var.type == "application_gateway" ? azurerm_application_gateway.main[0].id : var.type == "internal_load_balancer" ? azurerm_lb.main[0].id : azurerm_cdn_frontdoor_profile.main[0].id
  description = "Resource ID of the load balancer"
}

output "name" {
  value       = var.name
  description = "Name of the load balancer"
}

output "fqdn" {
  value = var.type == "front_door" ? azurerm_cdn_frontdoor_profile.main[0].name : null
  description = "FQDN of the Front Door (if applicable)"
}

output "backend_pool_ids" {
  value = var.type == "internal_load_balancer" ? {
    for pool_name, pool in azurerm_lb_backend_address_pool.main :
    pool_name => pool.id
  } : {}
  description = "Map of backend pool IDs"
}

output "frontend_ip_config_ids" {
  value = var.type == "application_gateway" ? {
    "primary" = azurerm_application_gateway.main[0].frontend_ip_configuration[0].id
  } : var.type == "internal_load_balancer" ? {
    for config in azurerm_lb.main[0].frontend_ip_configuration :
    config.name => config.id
  } : {}
  description = "Map of frontend IP configuration IDs"
}
