# Networking Template for App Infrastructure Repositories
# This file should be included when scaffolding new app-infra repos
# It creates an app-owned spoke VNet that integrates with the platform hub

# Reference the platform landing zone state to get hub info
data "terraform_remote_state" "platform" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatecloud001"
    container_name       = "tfstate"
    key                  = "landing-zone/prod.tfstate"
  }
}

# App Spoke Virtual Network
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.app_code}-${var.module_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_address_space]

  tags = merge(var.tags, {
    Application = "${var.app_code}-${var.module_name}"
    Environment = var.environment
  })
}

# Application Subnet
resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.app_subnet_address_prefix]
  service_endpoints    = var.app_subnet_service_endpoints

  # Enable private endpoint network policies
  private_endpoint_network_policies_enabled     = true
  private_link_service_network_policies_enabled = true
}

# Data Subnet (for databases, caches, etc.)
resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.data_subnet_address_prefix]
  service_endpoints    = var.data_subnet_service_endpoints

  private_endpoint_network_policies_enabled     = true
  private_link_service_network_policies_enabled = true
}

# Network Security Group for App Subnet
resource "azurerm_network_security_group" "app" {
  name                = "nsg-${var.app_code}-${var.module_name}-app-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# NSG Rule: Allow HTTPS inbound
resource "azurerm_network_security_rule" "app_https" {
  name                        = "AllowHTTPS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.app.name
}

# NSG Rule: Allow HTTP inbound (non-prod only)
resource "azurerm_network_security_rule" "app_http" {
  count = var.environment != "prod" ? 1 : 0

  name                        = "AllowHTTP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.app.name
}

# Associate NSG with App Subnet
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# Network Security Group for Data Subnet
resource "azurerm_network_security_group" "data" {
  name                = "nsg-${var.app_code}-${var.module_name}-data-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# NSG Rule: Deny direct internet access to data subnet
resource "azurerm_network_security_rule" "data_deny_internet" {
  name                        = "DenyInternetInbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.data.name
}

# Associate NSG with Data Subnet
resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}

# Route Table for App Subnet
resource "azurerm_route_table" "spoke" {
  name                          = "rt-${var.app_code}-${var.module_name}-${var.environment}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.main.name
  disable_bgp_route_propagation = false

  tags = var.tags
}

# Default Route to Azure Firewall
resource "azurerm_route" "default_to_firewall" {
  name                   = "route-default-to-firewall"
  resource_group_name    = azurerm_resource_group.main.name
  route_table_name       = azurerm_route_table.spoke.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = data.terraform_remote_state.platform.outputs.firewall_private_ip
}

# Associate Route Table with App Subnet
resource "azurerm_subnet_route_table_association" "app" {
  subnet_id      = azurerm_subnet.app.id
  route_table_id = azurerm_route_table.spoke.id
}

# Associate Route Table with Data Subnet
resource "azurerm_subnet_route_table_association" "data" {
  subnet_id      = azurerm_subnet.data.id
  route_table_id = azurerm_route_table.spoke.id
}

# VNet Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-${var.app_code}-${var.module_name}-to-hub"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = data.terraform_remote_state.platform.outputs.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Diagnostic Settings for VNet
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "diag-vnet-${var.app_code}-${var.module_name}"
  target_resource_id         = azurerm_virtual_network.spoke.id
  log_analytics_workspace_id = data.terraform_remote_state.platform.outputs.log_analytics_workspace_id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic Settings for NSGs
resource "azurerm_monitor_diagnostic_setting" "nsg_app" {
  name                       = "diag-nsg-app"
  target_resource_id         = azurerm_network_security_group.app.id
  log_analytics_workspace_id = data.terraform_remote_state.platform.outputs.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg_data" {
  name                       = "diag-nsg-data"
  target_resource_id         = azurerm_network_security_group.data.id
  log_analytics_workspace_id = data.terraform_remote_state.platform.outputs.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

# Outputs
output "vnet_id" {
  description = "Spoke VNet ID (provide to cloud team for hub peering)"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Spoke VNet name"
  value       = azurerm_virtual_network.spoke.name
}

output "app_subnet_id" {
  description = "Application subnet ID"
  value       = azurerm_subnet.app.id
}

output "data_subnet_id" {
  description = "Data subnet ID"
  value       = azurerm_subnet.data.id
}

output "app_nsg_id" {
  description = "Application NSG ID"
  value       = azurerm_network_security_group.app.id
}

output "data_nsg_id" {
  description = "Data NSG ID"
  value       = azurerm_network_security_group.data.id
}
