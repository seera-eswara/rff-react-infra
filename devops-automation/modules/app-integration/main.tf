# App CI/CD Integration Module

resource "azuread_application" "terraform_ci" {
  display_name = "terraform-${var.app_code}-${var.environment}-ci"
}

resource "azuread_service_principal" "terraform_ci" {
  client_id = azuread_application.terraform_ci.client_id
}

# Federated credential for GitHub OIDC
resource "azuread_service_principal_federated_credential" "github" {
  service_principal_id = azuread_service_principal.terraform_ci.id
  display_name         = "github-${var.app_code}-${var.environment}"
  description          = "GitHub Actions OIDC for ${var.app_code}-${var.environment}"

  issuer      = "https://token.actions.githubusercontent.com"
  subject     = "repo:${var.github_org}/${var.repo_name}:ref:refs/heads/${var.branch}"
  audiences   = ["api://AzureADTokenExchange"]
}

data "azurerm_role_definition" "contributor" {
  name  = "Contributor"
  scope = "/"
}

# Assign Contributor to SPN at subscription scope
resource "azurerm_role_assignment" "terraform_ci" {
  scope              = "/subscriptions/${var.subscription_id}"
  role_definition_id = data.azurerm_role_definition.contributor.id
  principal_id       = azuread_service_principal.terraform_ci.id
}

data "azurerm_client_config" "current" {}

locals {
  tenant_id = data.azurerm_client_config.current.tenant_id
}
