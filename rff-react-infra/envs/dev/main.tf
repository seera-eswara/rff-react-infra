# Data source to get current client configuration
data "azurerm_client_config" "current" {}

# ============================================================================
# TAGS - Standardized tagging for all resources
# ============================================================================
module "tags" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/utility/tags?ref=v1.0.0"

  environment = var.environment
  application = "rff-react"
  cost_center = var.cost_center
  managed_by  = "terraform"
  project     = "rff-react-infra"
  owner       = var.owner_email

  custom_tags = var.tags
}

# ============================================================================
# RESOURCE GROUP - Foundation with optional lock
# ============================================================================
module "resource_group" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/utility/resource_group?ref=v1.0.0"

  name        = "rg-${var.app_code}-${var.module}-${var.environment}"
  location    = var.location
  create_lock = var.environment == "prod" ? true : false
  lock_level  = "CanNotDelete"

  tags = module.tags.tags
}

# ============================================================================
# MONITORING - Log Analytics Workspace
# ============================================================================
module "log_analytics" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/monitoring/log_analytics_workspace?ref=v1.0.0"

  name                = "law-${var.app_code}-${var.module}-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "prod" ? 90 : 30

  tags = module.tags.tags
}

# ============================================================================
# NETWORKING - VNet with Subnets (all from modules)
# ============================================================================
module "vnet" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/networking/vnet?ref=v1.0.0"

  name                = "vnet-${var.app_code}-${var.module}-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = [var.vnet_address_space]

  subnets = {
    "snet-app" = {
      address_prefixes = [var.app_subnet_prefix]
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.Web"
      ]
    }
    "snet-data" = {
      address_prefixes = [var.data_subnet_prefix]
      service_endpoints = [
        "Microsoft.Sql",
        "Microsoft.Storage",
        "Microsoft.KeyVault"
      ]
    }
  }

  enable_diagnostics         = true
  log_analytics_workspace_id = module.log_analytics.id

  tags = module.tags.tags
}

# ============================================================================
# NETWORK SECURITY - NSGs with diagnostic settings
# ============================================================================
module "nsg_app" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/networking/nsg?ref=v1.0.0"

  name                = "nsg-${var.app_code}-${var.module}-app-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name

  rules = {
    "AllowHttpsInbound" = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
    "AllowHttpInbound" = {
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  enable_diagnostics         = true
  log_analytics_workspace_id = module.log_analytics.id

  tags = module.tags.tags
}

module "nsg_data" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/networking/nsg?ref=v1.0.0"

  name                = "nsg-${var.app_code}-${var.module}-data-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name

  rules = {
    "DenyInternetOutbound" = {
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    }
  }

  enable_diagnostics         = true
  log_analytics_workspace_id = module.log_analytics.id

  tags = module.tags.tags
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = module.vnet.subnet_ids["snet-app"]
  network_security_group_id = module.nsg_app.id
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = module.vnet.subnet_ids["snet-data"]
  network_security_group_id = module.nsg_data.id
}

# ============================================================================
# STORAGE - Storage Account with security features
# ============================================================================
module "storage_account" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/data/storage_account?ref=v1.0.0"

  name                     = "st${var.app_code}${var.module}${var.environment}"
  location                 = var.location
  resource_group_name      = module.resource_group.name
  account_replication_type = var.environment == "prod" ? "ZRS" : "LRS"

  enable_static_website       = true
  static_website_index        = "index.html"
  static_website_error_404    = "404.html"

  enable_firewall = var.environment == "prod" ? true : false
  firewall_virtual_network_subnet_ids = var.environment == "prod" ? [module.vnet.subnet_ids["snet-app"]] : null

  enable_diagnostics         = true
  log_analytics_workspace_id = module.log_analytics.id

  tags = module.tags.tags
}

# Storage containers for application data
module "storage_containers" {
  source   = "git::https://github.com/your-org/terraform-azure-modules.git//modules/utility/storage_container?ref=v1.0.0"
  for_each = toset(["uploads", "assets", "backups"])

  name                  = each.key
  storage_account_name  = module.storage_account.name
  container_access_type = "private"

  metadata = {
    environment = var.environment
    application = "rff-react"
  }
}

# ============================================================================
# KEY VAULT - Secrets management with RBAC
# ============================================================================
module "key_vault" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/data/keyvault?ref=v1.0.0"

  name                = "kv-${var.app_code}-${var.module}-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  enable_rbac_authorization = true
  purge_protection_enabled  = var.environment == "prod" ? true : false
  soft_delete_retention_days = var.environment == "prod" ? 90 : 7

  network_acls = {
    bypass         = "AzureServices"
    default_action = var.environment == "prod" ? "Deny" : "Allow"
    ip_rules       = var.environment == "prod" ? [] : null
    virtual_network_subnet_ids = var.environment == "prod" ? [module.vnet.subnet_ids["snet-app"]] : null
  }

  enable_diagnostics         = true
  log_analytics_workspace_id = module.log_analytics.id

  tags = module.tags.tags
}

# ============================================================================
# APPLICATION INSIGHTS - Application monitoring (using module)
# ============================================================================
module "application_insights" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/monitoring/application_insights?ref=v1.0.0"

  name                = "appi-${var.app_code}-${var.module}-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  workspace_id        = module.log_analytics.id
  application_type    = "web"

  retention_in_days   = var.environment == "prod" ? 90 : 30
  sampling_percentage = 100

  tags = module.tags.tags
}
