# NSG Rules Module

This module provides granular management of Network Security Group (NSG) rules specific to the rff-react application, enabling:
- **Centralized Rule Management** - Define and maintain NSG rules in one place
- **Module-Specific Rules** - Apply rules by module name or functional area
- **Rule Inheritance** - Common rules that apply across multiple NSGs
- **Dynamic Rule Generation** - Generate rules based on configuration

## Usage

```hcl
module "nsg_rules" {
  source = "./modules/nsg_rules"

  resource_group_name = azurerm_resource_group.main.name

  nsg_rules = {
    "app-subnet-rules" = {
      nsg_name = azurerm_network_security_group.app.name
      rules = {
        "AllowHttpsFromInternet" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
        }
        "AllowAppServiceToStorage" = {
          priority                   = 110
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = var.app_subnet_prefix
          destination_address_prefix = var.storage_service_tag
        }
      }
    }
    "data-subnet-rules" = {
      nsg_name = azurerm_network_security_group.data.name
      rules = {
        "AllowSqlFromApp" = {
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "1433"
          source_address_prefix      = var.app_subnet_prefix
          destination_address_prefix = "*"
        }
      }
    }
  }

  tags = local.tags
}
```

## Features

### Rule Organization
- Group rules by NSG or functional area
- Inherit common rules across NSGs
- Service tag support (Storage, SQL, AppService, etc.)

### Security Best Practices
- Default deny all inbound traffic
- Explicit allow rules for required flows
- Service endpoint integration
- Priority-based rule ordering

### Management
- Track rule purpose with descriptions
- Enable/disable rules without deletion
- Audit trail of rule changes
- Support for dynamic rule generation

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | Resource group name | `string` | n/a | yes |
| nsg_rules | Map of NSG rules by NSG name | `map(any)` | `{}` | no |
| common_rules | Rules to apply to all NSGs | `map(any)` | `{}` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Rule Structure

```hcl
nsg_rules = {
  "nsg-name" = {
    nsg_name = "actual-nsg-name"
    rules = {
      "rule-name" = {
        priority                   = 100
        direction                  = "Inbound|Outbound"
        access                     = "Allow|Deny"
        protocol                   = "Tcp|Udp|Icmp|*"
        source_port_range          = "80|80-443|*"
        destination_port_range     = "80|80-443|*"
        source_address_prefix      = "10.0.0.0/24|Internet|VirtualNetwork"
        destination_address_prefix = "10.0.0.0/24|Storage|*"
      }
    }
  }
}
```

## Common Service Tags

- `Internet` - All internet traffic
- `VirtualNetwork` - All VNet traffic
- `AzureCloud` - All Azure datacenters
- `Storage` - Azure Storage
- `Sql` - Azure SQL Database
- `AppService` - Azure App Service
- `EventHub` - Azure Event Hubs
- `ServiceBus` - Azure Service Bus
- `CosmosDB` - Azure Cosmos DB

## Examples

### Allow HTTPS from Internet
```hcl
"AllowHttpsFromInternet" = {
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "Internet"
  destination_address_prefix = "*"
}
```

### Allow SQL from App Subnet
```hcl
"AllowSqlFromApp" = {
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "1433"
  source_address_prefix      = "10.0.1.0/24"  # app-subnet
  destination_address_prefix = "*"
}
```

### Deny Internet Outbound from Data Subnet
```hcl
"DenyInternetOutbound" = {
  priority                   = 100
  direction                  = "Outbound"
  access                     = "Deny"
  protocol                   = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "10.0.2.0/24"  # data-subnet
  destination_address_prefix = "Internet"
}
```

## Outputs

| Name | Description |
|------|-------------|
| rule_ids | Map of created security rule resource IDs |
