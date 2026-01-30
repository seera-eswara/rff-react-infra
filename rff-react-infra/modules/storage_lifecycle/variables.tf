variable "storage_account_name" {
  type        = string
  description = "Name of the existing storage account"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group containing the storage account"
}

variable "lifecycle_rules" {
  type = map(object({
    container_names = list(string)
    filters = object({
      prefix     = optional(string)
      blob_types = optional(list(string))
    })
    actions = optional(object({
      cool_after_days        = optional(number)
      archive_after_days     = optional(number)
      delete_after_days      = optional(number)
      snapshot_delete_after_days = optional(number)
      version_delete_after_days  = optional(number)
    }))
    enabled = bool
  }))
  description = "Map of lifecycle rule configurations"
  default     = {}

  validation {
    condition = alltrue([
      for rule in values(var.lifecycle_rules) :
      rule.actions == null || (
        rule.actions.cool_after_days == null ||
        rule.actions.archive_after_days == null ||
        rule.actions.delete_after_days == null ||
        (
          (rule.actions.cool_after_days == null || rule.actions.archive_after_days == null || rule.actions.cool_after_days < rule.actions.archive_after_days) &&
          (rule.actions.archive_after_days == null || rule.actions.delete_after_days == null || rule.actions.archive_after_days < rule.actions.delete_after_days) &&
          (rule.actions.cool_after_days == null || rule.actions.delete_after_days == null || rule.actions.cool_after_days < rule.actions.delete_after_days)
        )
      )
    ])
    error_message = "Lifecycle days must follow progression: cool < archive < delete"
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
