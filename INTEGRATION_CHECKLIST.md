# Integration Checklist for App Onboarding

Use this checklist when onboarding a new app team.

## Pre-Flight

- [ ] App code is unique and follows pattern (3 lowercase alphanumerics)
- [ ] Team lead identified
- [ ] Budget approved
- [ ] Compliance requirements documented (PCI, HIPAA, SOC2, etc.)
- [ ] RBAC group names defined (e.g., `app1-contributors`, `app1-operators`)

## Subscription Factory Run (cloud Team)

- [ ] Prepared `terraform.tfvars` with app_code, environment, billing_scope_id
- [ ] Ran `terraform init` in subscription factory
- [ ] Ran `terraform plan` and reviewed outputs
- [ ] Ran `terraform apply` (or queued in CI)
- [ ] Verified subscription created in Azure portal
- [ ] Verified MG association (lz-app1 under LandingZones)
- [ ] Verified baseline RG and Log Analytics workspace
- [ ] Verified RBAC assignments (groups have Contributor/Reader)
- [ ] Documented outputs:
  - [ ] Subscription ID
  - [ ] Resource group name
  - [ ] Log Analytics workspace ID
  - [ ] Management group path

## Integration Setup (DevOps Team)

### Service Principal & App Registration

- [ ] Created Azure AD app registration (e.g., `terraform-app1-dev-ci`)
- [ ] Created service principal from app registration
- [ ] Documented:
  - [ ] Client ID (app registration ID)
  - [ ] Tenant ID
  - [ ] Service Principal Object ID
- [ ] (Optional) Created managed identity in cloud subscription
- [ ] (Preferred) Created federated credential for GitHub OIDC
  - [ ] Issuer: `https://token.actions.githubusercontent.com`
  - [ ] Subject: `repo:YOUR_ORG/app1-infra:ref:refs/heads/main`
  - [ ] Audiences: `api://AzureADTokenExchange`
- [ ] Assigned Contributor role to SPN at subscription scope
- [ ] Assigned reader roles to other teams (e.g., Security) if needed

### Backend State Configuration

- [ ] Backend storage account exists and is accessible
- [ ] State container and key path exist/are correct (e.g., `app1/dev.tfstate`)
- [ ] SPN has access to backend storage
- [ ] Verified with `az storage blob list --account-name tfstatelzqiaypb --container-name tfstate`

### GitHub Secrets

- [ ] Added `ARM_CLIENT_ID` (client ID from app registration)
- [ ] Added `ARM_TENANT_ID` (tenant ID)
- [ ] Added `ARM_SUBSCRIPTION_ID` (subscription ID)
- [ ] Added `ARM_USE_OIDC` = `true`
- [ ] (Optional) Added `GITHUB_TOKEN` for artifact uploads
- [ ] Verified secrets are not logged in any workflow

### App Infra Repo Initialization

- [ ] Cloned or created `app1-infra` repository
- [ ] Created directory structure: `envs/{dev,stage,prod}`
- [ ] Added `providers.tf` with azurerm ~> 4.57
- [ ] Added `backend.tf` with correct storage account, container, key
- [ ] Added `main.tf` with module references (terraform-azure-modules)
- [ ] Added `.gitignore` to exclude `.terraform/`, `*.tfvars.json`, etc.
- [ ] Added CI/CD workflow template (GitHub Actions)
  - [ ] References `github-actions-templates` reusable workflows
  - [ ] Triggers on PR, push to main, manual
- [ ] Initialized Terraform: `terraform init`
- [ ] Ran `terraform plan` to verify no errors
- [ ] Committed and pushed to main

### Integration Manifest

- [ ] Created and stored integration manifest JSON:
  ```json
  {
    "app_code": "app1",
    "environment": "dev",
    "subscription_id": "00000000-xxxx",
    "management_group_id": "lz-app1",
    "app_registration_id": "11111111-xxxx",
    "service_principal_id": "22222222-xxxx",
    "tenant_id": "33333333-xxxx",
    "resource_group": "rg-app1-dev",
    "log_analytics_workspace_id": "/subscriptions/.../providers/Microsoft.OperationalInsights/workspaces/law-app1-dev",
    "backend_state_key": "app1/dev.tfstate"
  }
  ```
- [ ] Stored manifest in central registry (e.g., `registry` repo or S3)
- [ ] Shared manifest with app team

## Handoff to App Team

- [ ] Sent subscription login credentials / access instructions
- [ ] Provided copy of integration manifest
- [ ] Provided app infra repo access (GitHub)
- [ ] Provided documentation:
  - [ ] ONBOARDING.md (this file)
  - [ ] ARCHITECTURE_INTEGRATION.md (repo integration)
  - [ ] SECURITY.md (state file access, PIM, MFA)
  - [ ] Exemptions workflow (EXEMPTIONS.md)
  - [ ] CI/CD workflow details
- [ ] Assigned app team to RBAC groups in Azure AD (if not auto-added)
- [ ] Verified app team can:
  - [ ] Access subscription via Azure portal
  - [ ] Log in to app infra repo
  - [ ] View baseline resources (RG, LAW)
- [ ] Scheduled onboarding kickoff with app team

## Post-Onboarding Verification

- [ ] App team successfully cloned app infra repo
- [ ] App team ran `terraform plan` without errors
- [ ] First workload deployment successful (PR → approval → apply)
- [ ] CI/CD pipeline executed without issues
- [ ] Logs and metrics flowing to Log Analytics workspace
- [ ] App team knows how to request policy exemptions
- [ ] App team knows escalation contacts

## Common Issues & Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| "Authenticating using the Azure CLI only supported as User" | ARM_USE_OIDC not set or false | Ensure ARM_USE_OIDC=true in GitHub secrets |
| "InsufficientVCPUQuota" | VM SKU requires too many cores | Adjust vm_size in module or request quota increase |
| "Backend storage not accessible" | SPN lacks access to backend storage | Grant SPN Contributor or Storage Blob Data Contributor role |
| "Policy compliance violation" | App resource violates policy (e.g., non-approved VM SKU) | Request exemption via PR, approve, or modify resource |
| "MG association failed" | MG path incorrect or doesn't exist | Verify management_group_prefix + app_code form correct path |

