variable "name" {
  type        = string
  description = "Name of the load balancer"
}

variable "location" {
  type        = string
  description = "Azure region for the load balancer"
  default     = ""
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = ""
}

variable "type" {
  type        = string
  description = "Type of load balancer: application_gateway, internal_load_balancer, front_door"
  
  validation {
    condition     = contains(["application_gateway", "internal_load_balancer", "front_door"], var.type)
    error_message = "Type must be one of: application_gateway, internal_load_balancer, front_door"
  }
}

variable "sku" {
  type        = any
  description = "SKU configuration for the load balancer"
  default     = {}
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for Application Gateway"
  default     = null
}

variable "public_ip_address_id" {
  type        = string
  description = "Public IP address ID for Application Gateway frontend"
  default     = null
}

variable "backend_pools" {
  type        = map(any)
  description = "Backend pool configurations"
  default     = {}
}

variable "frontend_ip_configs" {
  type        = map(any)
  description = "Frontend IP configuration for Internal Load Balancer"
  default     = {}
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
