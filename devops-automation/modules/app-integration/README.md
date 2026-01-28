# DevOps Integration Module

Terraform module to automate service principal + federated credential creation for app CI/CD.

## Usage

```hcl
module "app_ci_integration" {
  source = "./modules/app-integration"

  app_code        = "app1"
  environment     = "dev"
  subscription_id = azurerm_subscription.app1_dev.subscription_id
  
  github_org      = "your-org"
  repo_name       = "app1-infra"
  branch          = "main"
  
  tags = {
    Owner = "cloud Team"
    Purpose = "Terraform CI/CD"
  }
}

output "integration" {
  value = {
    client_id            = module.app_ci_integration.client_id
    tenant_id            = data.azurerm_client_config.current.tenant_id
    service_principal_id = module.app_ci_integration.service_principal_id
  }
}
```

Use outputs to populate GitHub secrets.
