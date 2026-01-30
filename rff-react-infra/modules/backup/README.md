# Backup Module

This module manages backup and disaster recovery for the rff-react application, including:
- **Recovery Services Vault** - Centralized backup storage
- **Backup Policies** - Retention and frequency policies for different resource types
- **Backup Instances** - VM, Database, and File Share backups
- **Retention Management** - Granular control over backup retention periods

## Usage

```hcl
module "backup" {
  source = "./modules/backup"

  name                = "rsv-rff-react-dev"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.main.name

  sku = "Standard"
  
  backup_policies = {
    "vm-daily" = {
      resource_type = "VirtualMachine"
      frequency     = "Daily"
      interval      = 1
      retention_days = 30
    }
    "vm-weekly" = {
      resource_type = "VirtualMachine"
      frequency     = "Weekly"
      interval      = 1
      retention_days = 90
    }
  }

  soft_delete_enabled = true
  purge_protection_enabled = false

  enable_diagnostics         = true
  log_analytics_workspace_id = module.log_analytics.id

  tags = local.tags
}
```

## Features

### Backup Policies
- **VM Backup**: Daily/Weekly/Monthly snapshots with configurable retention
- **Database Backup**: Point-in-time recovery with transaction logs
- **File Share Backup**: Incremental backups with snapshot management
- **Custom Retention**: Differentiated retention for development, staging, and production

### Disaster Recovery
- Soft delete protection (recoverable for 14 days)
- Purge protection (immutable vault configuration)
- Cross-region vault pairing for geo-redundancy
- Immutable backup copies

### Compliance
- Audit logging of all backup operations
- Retention policies aligned with regulations
- Encryption at rest (platform-managed keys)
- RBAC for backup access control

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the Recovery Services Vault | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| sku | SKU level: Standard or Premium | `string` | `"Standard"` | no |
| backup_policies | Map of backup policies | `map(any)` | `{}` | no |
| soft_delete_enabled | Enable soft delete protection | `bool` | `true` | no |
| purge_protection_enabled | Enable purge protection | `bool` | `false` | no |
| enable_diagnostics | Enable diagnostic logging | `bool` | `true` | no |
| log_analytics_workspace_id | Log Analytics workspace ID | `string` | `null` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vault_id | Recovery Services Vault resource ID |
| vault_name | Recovery Services Vault name |
| policy_ids | Map of backup policy IDs |
