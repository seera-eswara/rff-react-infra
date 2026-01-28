# Networking variables for app spoke VNet
# These should be added to the app-infra variables.tf

variable "vnet_address_space" {
  description = "Address space for the app spoke VNet"
  type        = string
}

variable "app_subnet_address_prefix" {
  description = "Address prefix for the application subnet"
  type        = string
}

variable "data_subnet_address_prefix" {
  description = "Address prefix for the data subnet"
  type        = string
}

variable "app_subnet_service_endpoints" {
  description = "Service endpoints for the application subnet"
  type        = list(string)
  default     = ["Microsoft.Storage", "Microsoft.KeyVault"]
}

variable "data_subnet_service_endpoints" {
  description = "Service endpoints for the data subnet"
  type        = list(string)
  default     = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
}
