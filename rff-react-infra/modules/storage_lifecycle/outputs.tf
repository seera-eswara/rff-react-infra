output "lifecycle_rules" {
  value       = var.lifecycle_rules
  description = "Applied lifecycle rules configuration"
}

output "managed_containers" {
  value = distinct(flatten([
    for rule_name, rule in var.lifecycle_rules :
    rule.container_names
  ]))
  description = "List of containers managed by lifecycle policies"
}
