variable "app_code" {
  description = "Application code (e.g., app1)"
  type        = string
}

variable "environment" {
  description = "Environment (dev, stage, prod)"
  type        = string
}

variable "subscription_id" {
  description = "Target Azure subscription ID"
  type        = string
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "branch" {
  description = "Git branch for OIDC (e.g., main)"
  type        = string
  default     = "main"
}

variable "tags" {
  description = "Tags for Azure resources"
  type        = map(string)
  default     = {}
}
