variable "name" {
  type        = string
  description = "Name of the Recovery Services Vault"
}

variable "location" {
  type        = string
  description = "Azure region for the vault"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "sku" {
  type        = string
  description = "SKU level: Standard or Premium"
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard", "Premium"], var.sku)
    error_message = "SKU must be either Standard or Premium"
  }
}

variable "backup_policies" {
  type = map(object({
    resource_type      = string
    frequency          = string
    interval           = number
    retention_days     = number
    time              = optional(string)
    weekdays          = optional(list(string))
    backup_hour       = optional(number)
    backup_minute     = optional(number)
    transaction_log_retention_days = optional(number)
    retention_daily   = optional(number)
  }))
  description = "Map of backup policies for different resource types"
  default     = {}
}

variable "soft_delete_enabled" {
  type        = bool
  description = "Enable soft delete protection (recoverable for 14 days)"
  default     = true
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Enable purge protection (immutable vault configuration)"
  default     = false
}

variable "enable_diagnostics" {
  type        = bool
  description = "Enable diagnostic logging"
  default     = true
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostic settings"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
