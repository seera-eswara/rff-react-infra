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
    module     = "load_balancer"
  }
}

# ============================================================================
# APPLICATION GATEWAY
# ============================================================================
resource "azurerm_application_gateway" "main" {
  count = var.type == "application_gateway" ? 1 : 0

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.sku.capacity
  }

  gateway_ip_configuration {
    name      = "${var.name}-ip-config"
    subnet_id = var.subnet_id
  }

  # Frontend ports
  frontend_port {
    name = "http"
    port = 80
  }

  frontend_port {
    name = "https"
    port = 443
  }

  # Frontend IP
  frontend_ip_configuration {
    name                 = "${var.name}-frontend-ip"
    public_ip_address_id = var.public_ip_address_id
  }

  # Backend pools
  dynamic "backend_address_pool" {
    for_each = var.backend_pools

    content {
      name = backend_address_pool.key

      dynamic "fqdns" {
        for_each = lookup(backend_address_pool.value, "fqdns", [])
        content {
          fqdn = fqdns.value
        }
      }

      dynamic "ip_addresses" {
        for_each = lookup(backend_address_pool.value, "backend_addresses", [])
        content {
          ip_address = ip_addresses.value
        }
      }
    }
  }

  # HTTP settings
  dynamic "backend_http_settings" {
    for_each = var.backend_pools

    content {
      name                  = "${backend_http_settings.key}-settings"
      cookie_based_affinity = "Disabled"
      port                  = 80
      protocol              = "Http"
      request_timeout       = 20
    }
  }

  # HTTP listener
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "${var.name}-frontend-ip"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  # Request routing rule
  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = keys(var.backend_pools)[0]
    backend_http_settings_name = "${keys(var.backend_pools)[0]}-settings"
  }

  tags = merge(local.common_tags, var.tags)
}

# Diagnostic settings for Application Gateway
resource "azurerm_monitor_diagnostic_setting" "appgw" {
  count = var.type == "application_gateway" && var.enable_diagnostics ? 1 : 0

  name               = "${var.name}-diagnostics"
  target_resource_id = azurerm_application_gateway.main[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ============================================================================
# INTERNAL LOAD BALANCER
# ============================================================================
resource "azurerm_lb" "main" {
  count = var.type == "internal_load_balancer" ? 1 : 0

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  load_balancer_type  = "Internal"

  frontend_ip_configuration {
    name            = "${var.name}-frontend-ip"
    subnet_id       = var.frontend_ip_configs["primary"].subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(local.common_tags, var.tags)
}

resource "azurerm_lb_backend_address_pool" "main" {
  for_each = var.type == "internal_load_balancer" ? var.backend_pools : {}

  name            = each.key
  loadbalancer_id = azurerm_lb.main[0].id
}

resource "azurerm_lb_rule" "main" {
  for_each = var.type == "internal_load_balancer" ? {
    for pool_name, pool_config in var.backend_pools :
    pool_name => pool_config
  } : {}

  name                       = "${each.key}-rule"
  loadbalancer_id            = azurerm_lb.main[0].id
  frontend_ip_configuration_name = "${var.name}-frontend-ip"
  protocol                   = "Tcp"
  frontend_port              = lookup(each.value, "frontend_port", 80)
  backend_port               = lookup(each.value, "backend_port", 80)
  backend_address_pool_ids   = [azurerm_lb_backend_address_pool.main[each.key].id]
  probe_id                   = azurerm_lb_probe.main[each.key].id
}

resource "azurerm_lb_probe" "main" {
  for_each = var.type == "internal_load_balancer" ? var.backend_pools : {}

  name            = "${each.key}-probe"
  loadbalancer_id = azurerm_lb.main[0].id
  protocol        = "Tcp"
  port            = lookup(each.value, "backend_port", 80)
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Diagnostic settings for Load Balancer
resource "azurerm_monitor_diagnostic_setting" "ilb" {
  count = var.type == "internal_load_balancer" && var.enable_diagnostics ? 1 : 0

  name                           = "${var.name}-diagnostics"
  target_resource_id             = azurerm_lb.main[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "LoadBalancerAlertEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ============================================================================
# FRONT DOOR
# ============================================================================
resource "azurerm_cdn_frontdoor_profile" "main" {
  count = var.type == "front_door" ? 1 : 0

  name                = var.name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku

  tags = merge(local.common_tags, var.tags)
}

resource "azurerm_cdn_frontdoor_origin_group" "main" {
  for_each = var.type == "front_door" ? var.backend_pools : {}

  name                     = "${each.key}-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id
  session_affinity_enabled = false

  restore_traffic_time_to_healed_origin_in_minutes = 10

  health_probe {
    interval_in_seconds = 100
    path                = "/"
    protocol            = "Http"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "main" {
  for_each = var.type == "front_door" ? var.backend_pools : {}

  name                          = each.key
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main[each.key].id
  enabled                       = true

  host_name           = each.value.backend_addresses[0]
  http_port           = 80
  https_port          = 443
  origin_host_header  = each.value.backend_addresses[0]
  priority            = 1
  weight              = 1000
}

resource "azurerm_cdn_frontdoor_route" "main" {
  for_each = var.type == "front_door" ? var.backend_pools : {}

  name                      = "${each.key}-route"
  cdn_frontdoor_profile_id  = azurerm_cdn_frontdoor_profile.main[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main[each.key].id
  enabled                   = true

  forwarding_protocol    = "HttpOnly"
  patterns_to_match      = ["/*"]
  supported_http_methods = ["GET", "HEAD", "PUT", "POST", "DELETE", "OPTIONS", "PATCH"]
  https_redirect_enabled = true
  link_to_default_domain = true
  
  cdn_frontdoor_origin_ids = [azurerm_cdn_frontdoor_origin.main[each.key].id]
}
