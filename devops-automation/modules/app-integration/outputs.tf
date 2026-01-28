output "client_id" {
  description = "App registration client ID for ARM_CLIENT_ID GitHub secret"
  value       = azuread_application.terraform_ci.client_id
}

output "service_principal_id" {
  description = "Service principal object ID"
  value       = azuread_service_principal.terraform_ci.id
}

output "tenant_id" {
  description = "Tenant ID for ARM_TENANT_ID GitHub secret"
  value       = local.tenant_id
}

output "subscription_id" {
  description = "Subscription ID for ARM_SUBSCRIPTION_ID GitHub secret"
  value       = var.subscription_id
}

output "app_registration_id" {
  description = "App registration object ID"
  value       = azuread_application.terraform_ci.id
}

output "github_secrets" {
  description = "Map of GitHub secret names and values for CI/CD"
  value = {
    ARM_CLIENT_ID      = azuread_application.terraform_ci.client_id
    ARM_TENANT_ID      = local.tenant_id
    ARM_SUBSCRIPTION_ID = var.subscription_id
    ARM_USE_OIDC       = "true"
  }
  sensitive = true
}
