# Storage Lifecycle Module

This module manages Azure Storage lifecycle rules for cost optimization, enabling automatic tiering of data:
- **Hot Tier** - Immediate access, highest cost, lowest latency
- **Cool Tier** - Infrequent access, medium cost, acceptable latency
- **Archive Tier** - Long-term retention, lowest cost, high latency (hours)
- **Delete** - Automatic deletion of old data

## Usage

```hcl
module "storage_lifecycle" {
  source = "./modules/storage_lifecycle"

  storage_account_name  = azurerm_storage_account.main.name
  resource_group_name   = azurerm_resource_group.main.name

  lifecycle_rules = {
    "app-logs" = {
      container_names = ["logs", "diagnostics"]
      filters = {
        prefix = "logs/"
        blob_types = ["blockBlob"]
      }
      actions = {
        cool_after_days    = 30    # Move to cool after 30 days
        archive_after_days = 90    # Move to archive after 90 days
        delete_after_days  = 365   # Delete after 1 year
      }
      enabled = true
    }
    "backups" = {
      container_names = ["backups"]
      filters = {
        prefix = ""
      }
      actions = {
        archive_after_days = 30
        delete_after_days  = 2555  # 7 years
      }
      enabled = true
    }
  }

  tags = local.tags
}
```

## Features

### Automatic Tiering
- Hot → Cool → Archive progression
- Configurable transition days
- Per-container or prefix-based rules

### Cost Optimization
- Reduce costs by up to 90% with archive tier
- Automatic cleanup of obsolete data
- Granular retention policies by data type

### Compliance
- Retention policies for regulatory compliance (HIPAA, GDPR)
- Immutable blob support for compliance records
- Audit logging of all lifecycle operations

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| storage_account_name | Storage account name | `string` | n/a | yes |
| resource_group_name | Resource group name | `string` | n/a | yes |
| lifecycle_rules | Map of lifecycle rule configurations | `map(any)` | `{}` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Lifecycle Rule Structure

```hcl
lifecycle_rules = {
  "rule-name" = {
    container_names = ["container1", "container2"]
    filters = {
      prefix      = "path/to/"           # Optional
      blob_types  = ["blockBlob"]        # Optional
    }
    actions = {
      cool_after_days    = 30            # Optional
      archive_after_days = 90            # Optional
      delete_after_days  = 365           # Optional
    }
    enabled = true
  }
}
```

## Examples

### Application Logs - 3-Year Retention
```hcl
"logs-3yr" = {
  container_names = ["logs"]
  filters = {
    prefix = "app-logs/"
  }
  actions = {
    cool_after_days    = 7      # Cool after 1 week
    archive_after_days = 30     # Archive after 1 month
    delete_after_days  = 1095   # Delete after 3 years
  }
  enabled = true
}
```

### Database Backups - 7-Year Retention
```hcl
"db-backups-7yr" = {
  container_names = ["backups"]
  filters = {
    blob_types = ["blockBlob"]
  }
  actions = {
    archive_after_days = 30     # Archive immediately
    delete_after_days  = 2555   # Delete after 7 years
  }
  enabled = true
}
```

### Audit Logs - Immutable for 10 Years
```hcl
"audit-logs-10yr" = {
  container_names = ["audit"]
  filters = {
    prefix = "audit/"
  }
  actions = {
    delete_after_days = 3650    # Delete after 10 years
  }
  enabled = true
}
```

## Outputs

| Name | Description |
|------|-------------|
| lifecycle_rules | Applied lifecycle rules configuration |
