# Load Balancer Module

This module manages load balancing solutions for the rff-react application, including:
- **Application Gateway** - Layer 7 (HTTP/HTTPS) load balancing
- **Internal Load Balancer (ILB)** - Layer 4 (TCP/UDP) internal load balancing
- **Front Door** - Global, multi-region load balancing and DDoS protection

## Usage

### Application Gateway
```hcl
module "app_gateway" {
  source = "./modules/load_balancer"

  name                = "appgw-rff-react-dev"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.main.name
  
  type = "application_gateway"
  
  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  backend_pools = {
    "pool-app" = {
      backend_addresses = ["10.0.1.10", "10.0.1.11"]
    }
  }

  tags = local.tags
}
```

### Internal Load Balancer
```hcl
module "ilb" {
  source = "./modules/load_balancer"

  name                = "ilb-rff-react-dev"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.main.name
  
  type = "internal_load_balancer"
  
  sku = "Standard"

  frontend_ip_configs = {
    "primary" = {
      subnet_id = azurerm_subnet.app.id
    }
  }

  tags = local.tags
}
```

### Front Door
```hcl
module "front_door" {
  source = "./modules/load_balancer"

  name  = "fd-rff-react"
  
  type = "front_door"
  
  sku = "Premium"

  backend_pools = {
    "pool-primary" = {
      backend_addresses = ["api-dev.rff-react.com"]
    }
  }

  tags = local.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the load balancer | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| type | Type of load balancer: application_gateway, internal_load_balancer, front_door | `string` | n/a | yes |
| sku | SKU configuration | `any` | n/a | yes |
| backend_pools | Backend pool configuration | `map(any)` | `{}` | no |
| frontend_ip_configs | Frontend IP configuration | `map(any)` | `{}` | no |
| enable_diagnostics | Enable diagnostic logging | `bool` | `true` | no |
| log_analytics_workspace_id | Log Analytics workspace ID for diagnostics | `string` | `null` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Load balancer resource ID |
| name | Load balancer name |
| fqdn | Fully qualified domain name (for Front Door) |
| backend_pool_ids | Map of backend pool IDs |
| frontend_ip_config_ids | Map of frontend IP configuration IDs |
