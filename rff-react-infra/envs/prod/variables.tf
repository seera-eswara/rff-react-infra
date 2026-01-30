variable "subscription_id" {
  description = "Azure subscription ID for RFF React Prod environment"
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
  default     = "prod"
}

variable "vnet_address_space" {
  description = "Address space for the spoke VNet"
  type        = string
  default     = "10.12.0.0/16"
}

variable "app_subnet_prefix" {
  description = "Address prefix for application subnet"
  type        = string
  default     = "10.12.1.0/24"
}

variable "data_subnet_prefix" {
  description = "Address prefix for data subnet"
  type        = string
  default     = "10.12.2.0/24"
}

variable "hub_vnet_id" {
  description = "Hub VNet resource ID for peering"
  type        = string
  default     = "" # Will be provided by platform team
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Application = "rff-react"
    Environment = "prod"
    ManagedBy   = "Terraform"
    CostCenter  = "CC-RFF-001"
    BillingEntity = "RFF-TEAM"
  }
}
