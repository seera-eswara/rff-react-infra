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
    module     = "nsg_rules"
  }
  
  # Flatten all rules by NSG and rule name
  flattened_rules = merge([
    for nsg_key, nsg_config in var.nsg_rules : {
      for rule_key, rule_config in nsg_config.rules :
      "${nsg_key}/${rule_key}" => merge(
        rule_config,
        {
          nsg_name = nsg_config.nsg_name
          rule_key = rule_key
        }
      )
    }
  ]...)
}

# ============================================================================
# NETWORK SECURITY GROUP RULES
# ============================================================================
resource "azurerm_network_security_rule" "main" {
  for_each = local.flattened_rules

  name                        = each.value.rule_key
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = lookup(each.value, "source_port_range", "*")
  destination_port_range      = lookup(each.value, "destination_port_range", "*")
  source_address_prefix       = lookup(each.value, "source_address_prefix", "*")
  destination_address_prefix  = lookup(each.value, "destination_address_prefix", "*")
  
  # Optional: Support for multiple address prefixes
  source_address_prefixes       = lookup(each.value, "source_address_prefixes", null)
  destination_address_prefixes  = lookup(each.value, "destination_address_prefixes", null)
  
  # Optional: Support for application security groups
  source_application_security_group_ids      = lookup(each.value, "source_asg_ids", null)
  destination_application_security_group_ids = lookup(each.value, "destination_asg_ids", null)

  resource_group_name         = var.resource_group_name
  network_security_group_name = each.value.nsg_name
}

# ============================================================================
# COMMON RULES (applied to all NSGs if specified)
# ============================================================================
resource "azurerm_network_security_rule" "common" {
  for_each = {
    for nsg_key, nsg_config in var.nsg_rules :
    nsg_key => nsg_config
    if length(var.common_rules) > 0
  }

  # This is a placeholder for common rules
  # In a real scenario, you would iterate through var.common_rules here
  # and apply them to each NSG with appropriate naming

  depends_on = [azurerm_network_security_rule.main]
}
