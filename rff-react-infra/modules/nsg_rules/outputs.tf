output "rule_ids" {
  value = {
    for rule_key, rule in azurerm_network_security_rule.main :
    rule_key => rule.id
  }
  description = "Map of created security rule resource IDs"
}

output "nsg_rules_summary" {
  value = {
    for nsg_key, nsg_config in var.nsg_rules :
    nsg_key => {
      nsg_name      = nsg_config.nsg_name
      rule_count    = length(nsg_config.rules)
      rule_names    = keys(nsg_config.rules)
    }
  }
  description = "Summary of NSG rules by NSG"
}
