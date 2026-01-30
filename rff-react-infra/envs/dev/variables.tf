variable "subscription_id" {
  description = "Azure subscription ID for RFF React Dev environment"
  type        = string
  default     = "" # Will be populated after subscription creation
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "app_code" {
  description = "Application code"
  type        = string
  default     = "rff"
}

variable "module" {
  description = "Module name"
  type        = string
  default     = "react"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vnet_address_space" {
  description = "Address space for the spoke VNet"
  type        = string
  default     = "10.10.0.0/16"
}

variable "app_subnet_prefix" {
  description = "Address prefix for application subnet"
  type        = string
  default     = "10.10.1.0/24"
}

variable "data_subnet_prefix" {
  description = "Address prefix for data subnet"
  type        = string
  default     = "10.10.2.0/24"
}

variable "hub_vnet_id" {
  description = "Hub VNet resource ID for peering"
  type        = string
  default     = "" # Will be provided by platform team
}

variable "tags" {
  description = "Custom tags to apply to resources (will be merged with standard tags)"
  type        = map(string)
  default     = {}
}

# ============================================================================
# NEW VARIABLES - Required for module integration
# ============================================================================
variable "cost_center" {
  description = "Cost center for billing and charge-back"
  type        = string
  default     = "IT-OPS"
}

variable "owner_email" {
  description = "Owner email for resource tracking"
  type        = string
  default     = "platform-team@company.com"
}
