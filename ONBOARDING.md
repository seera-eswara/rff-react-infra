# App Team Onboarding Workflow

End-to-end process when an app team approaches the cloud team to onboard into the Azure estate.

## Phase 1: Request & Intake (App Team + cloud Team)

1. App team submits request via GitHub issue or form with:
   - App code (e.g., `app1`)
   - Environment(s): dev, stage, prod
   - Budget estimate
   - Team lead & contacts
   - RBAC group names (e.g., `app1-contributors`, `app1-operators`)

2. cloud team reviews:
   - App code uniqueness
   - Budget feasibility
   - Compliance requirements

3. cloud team creates tracking issue and schedules integration task.

## Phase 2: Subscription & Baseline Creation (Terraform)

cloud team runs subscription factory automation:

```bash
cd terraform-azure-subscription-factory/requests/dev
cat <<EOF > app1.yaml
appCode: app1
environment: dev
billingEntity: app1-business-unit
estimatedMonthlyCost: 500
EOF

# Create tfvars with app-specific values
cat <<EOF > terraform.tfvars
subscription_name       = "app1-dev-001"
app_code                = "app1"
environment             = "dev"
management_group_prefix = "lz"
billing_scope_id        = "/providers/Microsoft.Billing/billingAccounts/.../billingProfiles/..."
owners                  = []  # Use groups instead
app_contributor_groups  = ["app1-contributors", "app1-operators"]
finops_reader_groups    = ["finops-readers"]
monthly_budget          = 500
EOF

terraform plan
terraform apply
```

**Outputs from subscription factory:**
- Subscription ID
- Subscription Name
- Management Group association
- Baseline resource group
- Log Analytics workspace ID
- RBAC assignments created

**Created in Azure:**
- Subscription (e.g., `app1-dev-001`)
- MG association (e.g., `lz-app1` → LandingZones → Tenant)
- Resource group (`rg-app1-dev`)
- Log Analytics workspace (`law-app1-dev`)
- Role assignments: Contributor + Reader for groups

## Phase 3: Integration Setup (DevOps Team)

DevOps team configures CI/CD, secrets, and backend state:

### 3.1 Service Principal for Terraform CI/CD

Create a service principal that the GitHub Actions workflow will use:

```bash
# Create app registration + service principal
az ad app create --display-name "terraform-app1-dev-ci"
APP_ID=$(az ad app list --filter "displayName eq 'terraform-app1-dev-ci'" -o tsv --query '[0].appId')
OBJECT_ID=$(az ad sp create --id $APP_ID -o tsv --query objectId)

# Create federated credential for GitHub OIDC
az identity federated-credential create \
  --resource-group "$RESOURCE_GROUP" \
  --identity-name "id-app1-dev" \
  --name "gh-actions-app1-dev" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:YOUR_ORG/app1-infra:ref:refs/heads/main"

# Grant Contributor at subscription scope
az role assignment create \
  --assignee $OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

**Or use Terraform module** (see Phase 3.6).

### 3.2 Backend State Configuration

DevOps team ensures backend state is configured:

```hcl
# app1-infra/envs/dev/backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstatelzqiaypb"
    container_name       = "tfstate"
    key                  = "app1/dev.tfstate"
  }
}
```

**Verify backend access:**
```bash
terraform init
terraform plan
```

### 3.3 GitHub Secrets & Env Vars

Add to GitHub org / repo:

```
ARM_CLIENT_ID          = <app-registration-client-id>
ARM_TENANT_ID          = <tenant-id>
ARM_SUBSCRIPTION_ID    = <subscription-id>
ARM_USE_OIDC           = true
```

Workflow uses these to authenticate without storing credentials.

### 3.4 App Registration & Management IDs

Document and share with app team:

| Field | Value | Usage |
|-------|-------|-------|
| Subscription ID | `00000000-xxxx` | Terraform backend, CI/CD |
| Management Group | `lz-app1` | Governance, policy scope |
| App Registration ID | `11111111-xxxx` | Service principal auth |
| Service Principal ID | `22222222-xxxx` | Role assignments |
| Tenant ID | `33333333-xxxx` | Authentication endpoint |

**Create a manifest file:**
```bash
cat > /tmp/app1-dev-integration.json <<EOF
{
  "app_code": "app1",
  "environment": "dev",
  "subscription_id": "$SUBSCRIPTION_ID",
  "management_group_id": "lz-app1",
  "app_registration_id": "$APP_ID",
  "service_principal_id": "$OBJECT_ID",
  "tenant_id": "$TENANT_ID",
  "resource_group": "rg-app1-dev",
  "log_analytics_workspace_id": "$LAW_ID",
  "backend_state_key": "app1/dev.tfstate"
}
EOF
```

### 3.5 Repo Initialization

Clone app infra template and initialize:

```bash
git clone https://github.com/YOUR_ORG/terraform-azure-modules.git app1-infra
cd app1-infra

# Create structure for app1-dev
mkdir -p envs/dev
cat > envs/dev/terraform.tf <<'EOF'
terraform {
  required_version = ">= 1.6.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.57"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
EOF

cat > envs/dev/backend.tf <<'EOF'
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstatelzqiaypb"
    container_name       = "tfstate"
    key                  = "app1/dev.tfstate"
  }
}
EOF

git add .
git commit -m "init: app1-dev environment setup"
git push origin main
```

### 3.6 (Optional) Automate SPN & Backend via Terraform

Create a DevOps module to automate service principal + backend:

```hcl
# devops-automation/modules/app-integration/main.tf
resource "azuread_application" "app" {
  display_name = "terraform-${var.app_code}-${var.environment}-ci"
}

resource "azuread_service_principal" "app" {
  client_id = azuread_application.app.client_id
}

resource "azuread_service_principal_federated_credential" "github" {
  service_principal_id = azuread_service_principal.app.id
  display_name         = "github-${var.app_code}-${var.environment}"
  description          = "GitHub Actions OIDC for ${var.app_code}-${var.environment}"

  issuer      = "https://token.actions.githubusercontent.com"
  subject     = "repo:${var.github_org}/${var.repo_name}:ref:refs/heads/${var.branch}"
  audiences   = ["api://AzureADTokenExchange"]
}

resource "azurerm_role_assignment" "terraform_sp" {
  scope              = var.subscription_id
  role_definition_id = data.azurerm_role_definition.contributor.id
  principal_id       = azuread_service_principal.app.id
}

output "client_id" {
  value = azuread_application.app.client_id
}
```

Usage:
```hcl
module "app1_dev_integration" {
  source = "./modules/app-integration"

  app_code       = "app1"
  environment    = "dev"
  subscription_id = azurerm_subscription.app1_dev.id
  github_org     = "your-org"
  repo_name      = "app1-infra"
  branch         = "main"
}
```

## Phase 4: Handoff to App Team

cloud team provides app team:

1. **Subscription ID & Credentials:**
   - Subscription name, ID, MG path
   - Initial login credentials (if needed)

2. **Integration Manifest:**
   - Copy of `app1-dev-integration.json`
   - How to use each field

3. **App Infra Repo:**
   - Pre-initialized GitHub repo with baseline module refs
   - CI/CD workflow template

4. **Documentation:**
   - How to run Terraform locally (init, plan, apply)
   - How CI/CD works
   - How to request exemptions or role escalations
   - Escalation contacts (cloud team, security team)

5. **Support:**
   - Point of contact for issues
   - Slack channel for async support

## Phase 5: App Team Continues

App team develops their workloads:

```bash
cd app1-infra/envs/dev
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

Changes trigger CI/CD: TFLint → TFSec → Conftest → Approve → Apply.

## Roles & Responsibilities

| Role | Phase | Responsibilities |
|------|-------|------------------|
| **App Team** | 1, 5 | Submit request, develop workloads, manage app resources |
| **cloud Team** | 2, 3, 4 | Run subscription factory, coordinate integration, handoff |
| **DevOps Team** | 3 | Set up SPN, backend, secrets, CI/CD integration |
| **Security Team** | 1, 3 | Review compliance, approve policies & exemptions |

## Automation Recommendations

- Automate subscription factory run via GitHub Actions trigger / REST API.
- Store integration manifest in a central registry (e.g., JSON file in a `registry` repo).
- Export manifests to Terraform remote data source so other repos can reference IDs.
- Create a Slack notification bot to alert teams of new subscriptions.
