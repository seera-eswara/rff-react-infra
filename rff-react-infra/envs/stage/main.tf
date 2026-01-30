# Data source to get current client configuration
data "azurerm_client_config" "current" {}

# Resource group for RFF React Stage
resource "azurerm_resource_group" "app" {
  name     = "rg-${var.app_code}-${var.module}-${var.environment}"
  location = var.location

  tags = var.tags
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "app" {
  name                = "law-${var.app_code}-${var.module}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(var.tags, {
    Purpose = "Application Monitoring"
  })
}

# Virtual Network (Spoke VNet)
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.app_code}-${var.module}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  address_space       = [var.vnet_address_space]

  tags = var.tags
}

# Application Subnet
resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.app.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.app_subnet_prefix]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Web"
  ]
}

# Data Subnet
resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.app.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.data_subnet_prefix]

  service_endpoints = [
    "Microsoft.Sql",
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]
}

# Network Security Group for App Subnet
resource "azurerm_network_security_group" "app" {
  name                = "nsg-${var.app_code}-${var.module}-app-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name

  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHttpInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Network Security Group for Data Subnet
resource "azurerm_network_security_group" "data" {
  name                = "nsg-${var.app_code}-${var.module}-data-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name

  security_rule {
    name                       = "DenyInternetOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = var.tags
}

# Associate NSG with App Subnet
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# Associate NSG with Data Subnet
resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}

# Storage Account for React app static files
resource "azurerm_storage_account" "app" {
  name                     = "st${var.app_code}${var.module}${var.environment}"
  resource_group_name      = azurerm_resource_group.app.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Geo-redundant for staging
  account_kind             = "StorageV2"

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = var.tags
}

# Key Vault for secrets management
resource "azurerm_key_vault" "app" {
  name                       = "kv-${var.app_code}-${var.module}-${var.environment}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.app.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow" # Change to "Deny" and use private endpoint in production
  }

  tags = var.tags
}

# Application Insights for monitoring
resource "azurerm_application_insights" "app" {
  name                = "appi-${var.app_code}-${var.module}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.app.name
  workspace_id        = azurerm_log_analytics_workspace.app.id
  application_type    = "web"

  tags = var.tags
}
