variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "nsg_rules" {
  type = map(object({
    nsg_name = string
    rules = map(object({
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string)
      destination_port_range     = optional(string)
      source_address_prefix      = optional(string)
      destination_address_prefix = optional(string)
      source_address_prefixes    = optional(list(string))
      destination_address_prefixes = optional(list(string))
      source_asg_ids             = optional(list(string))
      destination_asg_ids        = optional(list(string))
    }))
  }))
  description = "Map of NSG rules configuration"
  default     = {}

  validation {
    condition = alltrue([
      for nsg_key, nsg_config in var.nsg_rules : alltrue([
        for rule_key, rule_config in nsg_config.rules :
        contains(["Inbound", "Outbound"], rule_config.direction) &&
        contains(["Allow", "Deny"], rule_config.access) &&
        contains(["Tcp", "Udp", "Icmp", "*"], rule_config.protocol) &&
        rule_config.priority >= 100 && rule_config.priority <= 4096
      ])
    ])
    error_message = "Invalid NSG rule configuration. Check direction (Inbound/Outbound), access (Allow/Deny), protocol (Tcp/Udp/Icmp/*), and priority (100-4096)"
  }
}

variable "common_rules" {
  type        = map(any)
  description = "Common rules to apply to all NSGs"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
