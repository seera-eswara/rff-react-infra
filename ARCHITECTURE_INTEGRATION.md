# Architecture Integration Guide

## Overview

This document describes how three key repositories work together to create a secure, governed, and scalable Azure infrastructure:

1. **terraform-azure-landingzone** - Management Groups, subscriptions, and baseline infrastructure
2. **terraform-azure-subscription-factory** - Automates subscription creation for app teams
3. **terraform-policy-as-code** - Governance policies and OPA/Conftest rules

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│           Azure Tenant (Root Management Group)              │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
        ┌───────▼────────┐         ┌────────▼────────┐
        │   cloud MG  │         │  LandingZones   │
        │                │         │      MG         │
        └────────────────┘         └────────┬────────┘
                │                           │
        ┌───────▼────────┐         ┌────────▼────────┐
        │ Infrastructure │         │   App Teams     │
        │  Subscriptions │         │  Subscriptions  │
        │   (Shared)     │         │  (Auto-Created) │
        └────────────────┘         └─────────────────┘

        ▲
        │ terraform-azure-landingzone
        │ Creates MG structure
        │
        ├─ Deploys Policies (via module)
        │  terraform-policy-as-code/modules/policies
        │
        │
        ▲
        │ terraform-azure-subscription-factory
        │ Creates new subscriptions on demand
        │
        ├─ Applies Policies
        │  (inherited from parent MG)
        │
        │
        ▲
        │ app1-infra (and other apps)
        │ Deploy application infrastructure
        │
        └─ Validates via OPA
           (terraform-policy-as-code/opa)
```

---

## Component Responsibilities

### 1. terraform-azure-landingzone

**Purpose**: Establishes governance foundation

**What It Does**:
- Creates Management Group hierarchy
- Deploys baseline Azure Policies
- Sets up diagnostic logging
- Configures role assignments
- Manages shared infrastructure

**Integrations**:
```
INPUT: Policies from terraform-policy-as-code
       ├─ Policy Definitions
       ├─ Policy Assignments
       └─ Role Definitions

OUTPUT: Management Group IDs, Policy Assignment IDs
        (used by subscription-factory)
```

**Key Files**:
```
terraform-azure-landingzone/
├── management-groups/
│   ├── main.tf (Creates cloud, LandingZones MGs)
│   ├── policies.tf (NEW - Deploys policies)
│   └── outputs.tf (Exports MG IDs)
├── policies/ (NEW)
│   └── assignments.tf (Assigns policies from policy-as-code)
└── modules/
    └── policies/ (NEW - Module for policy deployment)
```

### 2. terraform-azure-subscription-factory

**Purpose**: Automates subscription provisioning for app teams

**What It Does**:
- Creates new subscriptions
- Assigns to management groups
- Establishes per-env backends
- Applies inherited policies
- Sets up budgets & alerts
- Creates Log Analytics workspace

**Integrations**:
```
INPUT: 
  ├─ Landing Zone MG IDs (terraform-azure-landingzone output)
  └─ Policy Assignments (inherited from parent MG)

OUTPUT: New Subscription ID, Resource Group, Backend Config
        (App teams use in their repos)
```

**Key Files**:
```
terraform-azure-subscription-factory/
├── main.tf (Calls subscription module)
├── policies.tf (NEW - Applies policies to new subscriptions)
├── modules/
│   └── subscription/
│       ├── main.tf
│       ├── policies.tf (NEW - Policy assignments)
│       └── backend.tf (Creates state storage)
└── requests/
    └── dev/
        ├── app1.yaml
        ├── app2.yaml (on demand)
        └── terraform.tfvars
```

### 3. terraform-policy-as-code

**Purpose**: Define and test governance policies

**What It Does**:
- Defines Azure Policies (JSON)
- Implements OPA/Conftest rules
- Tests policies with example configs
- Versions policies independently
- Provides policy modules

**Integrations**:
```
INPUT: None (source of truth)

OUTPUT: 
  ├─ Policy Modules (used by terraform-azure-landingzone)
  ├─ Policy Definitions (deployed to Azure)
  ├─ OPA Rules (used in CI/CD pipelines)
  └─ Modules (included in app repos)
```

**Key Files**:
```
terraform-policy-as-code/
├── modules/ (NEW)
│   └── policies/
│       ├── main.tf (Policy module)
│       ├── variables.tf
│       └── outputs.tf
├── policies/
│   ├── definitions/
│   │   ├── allowed-vm-skus.json
│   │   ├── naming-convention.json
│   │   └── allowed-regions.json
│   └── assignments/ (NEW)
│       └── landing-zone.tf
├── opa/ (OPA/Conftest rules)
│   ├── allowed-skus.rego
│   ├── tagging.rego
│   └── naming.rego
└── tests/
    └── policy_test.rego
```

---

## App-Based Management Group Architecture

### Overview

This architecture implements **self-service app provisioning** where:
- **terraform-azure-landingzone** remains stable and controlled by the cloud team
- **terraform-azure-subscription-factory** creates app-specific management groups on-demand
- **App teams** request subscriptions via YAML files (no infrastructure code changes needed)

### Separation of Concerns

```
terraform-azure-landingzone (Cloud Infrastructure Team)
  ├── Creates and maintains: Root MGs, cloud infrastructure, policies
  ├── Changes frequency: Rarely (foundational infrastructure)
  └── Outputs: Applications MG ID (parent for all app MGs)

terraform-azure-subscription-factory (Self-Service)
  ├── Creates: App MGs and subscriptions on-demand
  ├── Input: YAML requests from app teams
  ├── Changes frequency: Frequently (new apps, new subscriptions)
  └── Uses module: terraform-azure-modules/modules/app-management-group

terraform-azure-modules/modules/app-management-group (Reusable Module)
  ├── Purpose: Create app-specific MG with RBAC
  ├── Called by: Subscription factory
  └── Location: Centralized module repository
```

### Naming Convention

#### Management Group Naming
- **Pattern**: `MG-{APP_CODE}` (display name) / `mg-{app_code}` (resource name)
- **Parent**: `Applications` management group (from landing zone)
- **Created**: On-demand by subscription factory on first subscription request
- **Example**: `MG-RFF` for the RFF application

#### Subscription Naming
- **Pattern**: `{APP_CODE}-{MODULE}-{ENVIRONMENT}`
- **Environments**: `DEV`, `STG` (Staging), `PRD` (Production)
- **Module**: Technology stack or functional area
- **Examples**:
  - `RFF-REACT-DEV` - RFF application, React module, Development environment
  - `RFF-REACT-STG` - RFF application, React module, Staging environment
  - `RFF-REACT-PRD` - RFF application, React module, Production environment

#### Hierarchy
```
Root (Tenant)
├── cloud (Infrastructure - created by landing zone)
│   ├── management
│   ├── connectivity
│   └── identity
└── LandingZones (created by landing zone)
    └── Applications (created by landing zone)
        ├── MG-RFF (created by factory on 1st RFF subscription request)
        │   ├── RFF-REACT-DEV (subscription - created by factory)
        │   ├── RFF-REACT-STG (subscription - created by factory)
        │   └── RFF-REACT-PRD (subscription - created by factory)
        ├── MG-ABC (created by factory on 1st ABC subscription request)
        │   ├── ABC-API-DEV (subscription - created by factory)
        │   ├── ABC-API-STG (subscription - created by factory)
        │   └── ABC-API-PRD (subscription - created by factory)
        └── MG-XYZ (created by factory on 1st XYZ subscription request)
            └── ...
```

### Implementation

#### 1. Cloud Team: Deploy Landing Zone (One-time)

```bash
cd terraform-azure-landingzone/management-groups
terraform apply
```

**Creates**: Root MGs, Applications MG (parent for all app MGs)  
**Outputs**: Applications MG ID (used by factory)

#### 2. App Teams: Request Subscriptions (On-demand)

Create YAML files in `terraform-azure-subscription-factory/requests/`:

**`requests/dev/rff-react.yaml`**:
```yaml
subscription_name: rff-react-dev
environment: dev
app_code: RFF
module: REACT
owners:
  - 11111111-1111-1111-1111-111111111111
  - 22222222-2222-2222-2222-222222222222
billing_entity: RFF-TEAM
cost_center: CC-RFF-001
```

#### 3. Factory: Auto-Create App MG + Subscriptions

```bash
cd terraform-azure-subscription-factory
terraform apply
```

**Factory automatically**:
1. **Creates** `MG-RFF` if it doesn't exist (first time only)
2. **Creates** subscription `rff-react-dev` 
3. **Assigns** subscription to `MG-RFF`
4. **Provisions** baseline resources
5. **Assigns** RBAC (owners to both subscription and app MG)

**Subsequent RFF subscriptions**:
- Reuse existing `MG-RFF`
- Create new subscription (e.g., `rff-react-stg`)
- Assign to same `MG-RFF`

### Benefits of This Architecture

#### ✅ Stable Landing Zone
- Cloud team manages foundational infrastructure once
- No changes needed for each new app
- Landing zone rarely changes

#### ✅ Self-Service for App Teams
- App teams request subscriptions via YAML files
- No infrastructure code modifications needed
- Git-based workflow for audit trail

#### ✅ Team Isolation
- Each app gets its own management group
- Isolated RBAC boundaries
- Clear ownership per app

#### ✅ Scalability
Adding a new app:
1. Create 3 YAML files (dev/stg/prod)
2. Run `terraform apply` in factory
3. Done! (MG + 3 subscriptions created automatically)

#### ✅ Policy Governance
```
Policies at Applications MG
        ↓ (automatic inheritance)
     MG-RFF
        ↓ (automatic inheritance)
All RFF subscriptions (DEV, STG, PRD)
```

- Clear compliance boundary per app
- Easy to audit which subscriptions are governed

#### ✅ Cost Management
- Per-app cost tracking via billing entity tags
- Budget alerts per subscription
- Easy cost center chargeback

### Policy Inheritance Flow

```
Root (Tenant) - Tenant-level policies
  ↓ (inherited)
  
cloud MG - Cloud infrastructure policies
  ↓ (inherited)
  
LandingZones MG - Landing zone policies
  ↓ (inherited)
  
Applications MG - App governance policies (e.g., naming, tagging)
  ↓ (inherited)
  
MG-RFF - RFF-specific policies (if any)
  ↓ (inherited)
  
RFF-REACT-DEV, RFF-REACT-STG, RFF-REACT-PRD
(All inherit all parent policies automatically)
```

### Onboarding a New App

**Step 1**: App team creates YAML request file:
```yaml
# requests/dev/newapp-module.yaml
subscription_name: newapp-module-dev
environment: dev
app_code: NEWAPP
module: MODULE
owners:
  - owner-principal-id
```

**Step 2**: Infrastructure team runs factory:
```bash
cd terraform-azure-subscription-factory
terraform apply
```

**Step 3**: Factory creates:
- ✅ Management Group: `MG-NEWAPP` (under Applications)
- ✅ Subscription: `NEWAPP-MODULE-DEV`
- ✅ Resource Group, Log Analytics, etc.
- ✅ Policy assignments and RBAC

**Step 4**: Share details with app team
- Subscription ID
- Resource Group name
- App MG: `MG-NEWAPP`
- Inherited policies

---

## Integration Points

### Integration 1: Landing Zone Deploys Policies

**Flow**:
```
terraform-azure-landingzone/
  ├── calls module from terraform-policy-as-code
  └── Deploys policies to cloud & LandingZones MGs
```

**Implementation**:
```hcl
# terraform-azure-landingzone/policies.tf

module "landing_zone_policies" {
  source = "git::https://github.com/seera-eswara/terraform-policy-as-code.git//modules/policies?ref=v1.0.0"

  management_group_id = azurerm_management_group.cloud.id
  
  policies = {
    allowed_vm_skus      = true
    naming_convention    = true
    allowed_regions      = true
    require_tags         = true
    cost_control         = true
  }
  
  allowed_regions = ["eastus", "westus2"]
  required_tags   = ["Environment", "CostCenter", "Owner"]
  
  tags = {
    ManagedBy = "terraform-azure-landingzone"
    Purpose   = "Governance"
  }
}
```

**Outputs Used By**:
- Subscription Factory (policy assignment IDs)
- Audit & Compliance (policy version tracking)

---

### Integration 2: Subscription Factory Applies Policies

**Flow**:
```
terraform-azure-subscription-factory/
  ├── Creates new subscription
  ├── Assigns to team MG (under LandingZones)
  ├── Policies inherited from parent MG
  ├── Applies additional policies (if needed)
  └── Outputs subscription details
```

**Implementation**:
```hcl
# terraform-azure-subscription-factory/modules/subscription/policies.tf

# Policies automatically inherited from parent MG
# No explicit assignment needed - Azure applies parent policies

# But we can add scope-specific policies:
resource "azurerm_management_group_policy_assignment" "app_specific" {
  for_each = var.additional_policies

  name              = "${var.app_code}-${each.key}"
  policy_definition_id = data.azurerm_policy_definition.from_policy_repo[each.key].id
  management_group_id  = var.management_group_id
  
  parameters = jsonencode(each.value.parameters)
  
  description = "Policy: ${each.key} for ${var.app_code}"
}

# Reference policies from terraform-policy-as-code
data "azurerm_policy_definition" "from_policy_repo" {
  for_each = var.additional_policies
  
  name = each.value.policy_name
}
```

**Example: App Team Onboarding Flow**:
```
1. cloud team receives request:
   App: "payment-service"
   Environment: "dev"
   Budget: $500/month

2. Run subscription-factory:
   terraform apply -var-file="requests/dev/payment-service.yaml"

3. Subscription Factory creates:
   ├─ Subscription: "payment-service-dev-sub"
   ├─ MG: "payment-service" (under LandingZones)
   ├─ Backend: "payment-service/dev.tfstate"
   ├─ Log Analytics: "log-payment-dev"
   ├─ Budget Alert: $500 threshold
   └─ Policies Applied: 
       ├─ Naming convention (inherited)
       ├─ Allowed regions (inherited)
       ├─ Cost controls (inherited)
       └─ App-specific compliance (if added)

4. Output provided to app team:
   subscription_id = "xxxx-xxxx-xxxx"
   resource_group = "rg-payment-dev"
   backend_key = "payment-service/dev.tfstate"
```

---

### Integration 3: App Repos Validate Against Policies (via CI/CD)

**Flow**:
```
app1-infra/ (or any app repo)
  ├── Terraform code
  ├── CI/CD Pipeline (GitHub Actions)
  │   ├── terraform plan → plan.json
  │   ├── conftest test (OPA rules from terraform-policy-as-code)
  │   ├── tfsec security scan
  │   └── terraform apply (if approved)
  └── Policies enforce naming, tagging, SKUs, regions
```

**Implementation in CI/CD**:
```bash
# .github/workflows/terraform-iac.yml (github-actions-templates)

- name: Checkout policy repo
  uses: actions/checkout@v4
  with:
    repository: seera-eswara/terraform-policy-as-code
    path: terraform-policy-as-code
    ref: v1.0.0  # Use specific version

- name: OPA Policy Enforcement
  run: |
    conftest test plan.json \
      -p terraform-policy-as-code/opa \
      -d terraform-policy-as-code/policies/definitions
```

**Example OPA Rule Check**:
```rego
# terraform-policy-as-code/opa/naming.rego
package azure_naming

# Enforce naming convention: app-env-resource
deny[msg] {
  resource_name := input.resource.azurerm_resource_group[_].name
  not regex.match("^[a-z]+-[a-z]+-[a-z]+$", resource_name)
  msg := sprintf("Invalid naming: %s. Use format: app-env-resource", [resource_name])
}
```

**Example Tagging Rule Check**:
```rego
# terraform-policy-as-code/opa/tagging.rego
package azure_tagging

required_tags := {"Environment", "CostCenter", "Owner"}

deny[msg] {
  resource := input.resource.azurerm_resource_group[_]
  tags := resource.tags
  missing := required_tags - object.keys(tags)
  count(missing) > 0
  msg := sprintf("Missing required tags: %v", [missing])
}
```

---

## Data Flow Diagram

```
┌──────────────────────────────────┐
│  terraform-policy-as-code        │
│  (Source of Truth)               │
├──────────────────────────────────┤
│ • Policy Definitions (JSON)      │
│ • OPA Rules (.rego files)        │
│ • Policy Modules                 │
│ • Tests                          │
└────────────┬──────────────────────┘
             │
      ┌──────▼──────────────────────────┐
      │                                 │
┌─────▼────────────────┐     ┌─────────▼────────────────┐
│ terraform-azure-     │     │ CI/CD Pipeline           │
│ landingzone          │     │ (GitHub Actions)         │
├──────────────────────┤     ├──────────────────────────┤
│ • Creates MGs        │     │ • conftest validation    │
│ • Deploys Policies   │     │ • Tests against OPA      │
│ • Baseline setup     │     │ • Enforces naming/tags   │
└──────────┬───────────┘     └──────────────────────────┘
           │                         ▲
           │                         │
      ┌────▼─────────────────────────┴─────┐
      │ terraform-azure-subscription-factory │
      ├────────────────────────────────────┤
      │ • Creates subscriptions            │
      │ • Applies inherited policies       │
      │ • Sets up per-env backends         │
      │ • Outputs for app teams            │
      └────────────────────────────────────┘
           │
      ┌────▼──────────────┐
      │ app1-infra        │
      │ app2-infra        │
      │ (App Teams)       │
      └───────────────────┘
```

---

## Workflow: New App Onboarding

```
Step 1: App Team Request
├─ Request subscription via form/ticket
├─ Specify app name, environment, budget
└─ Assigned to cloud team

Step 2: cloud Team Setup
├─ Add request to terraform-azure-subscription-factory/requests/
├─ Run: terraform apply -var-file="requests/dev/app1.yaml"
├─ Subscription, MG, backend, LAW created
└─ Policies automatically inherited

Step 3: cloud Team Provides Output
├─ Subscription ID
├─ Resource Group
├─ Backend config
│   - resource_group_name: "rg-tfstate"
│   - storage_account_name: "tfstatelzqiaypb"
│   - container_name: "tfstate"
│   - key: "app1/dev.tfstate"
├─ Log Analytics Workspace ID
└─ Cost alerts configured

Step 4: App Team Creates Infrastructure
├─ Clone app1-infra template
├─ Update backend config
├─ Update subscription_id variable
├─ Push to GitHub → CI/CD triggered
├─ Policies validated (via OPA/conftest)
├─ Infrastructure deployed
└─ Resources created with enforced naming/tagging

Step 5: Ongoing Compliance
├─ Every deployment validates against policies
├─ Cost monitoring via budgets
├─ Audit logs tracked
└─ Policy changes cascade to all subscriptions
```

---

## Versioning & Release Strategy

### Policy Releases

```
terraform-policy-as-code/
├─ v1.0.0 (Current)
│  ├─ Allowed VM SKUs
│  ├─ Naming Convention
│  └─ Allowed Regions
├─ v1.1.0 (Proposed - Next Release)
│  ├─ Add: Cost tagging enforcement
│  ├─ Add: Network security rules
│  └─ Breaking: Stricter naming rules
```

### Landing Zone Upgrades

When policies are updated:
```bash
# Step 1: Update policy version in landing zone
# terraform-azure-landingzone/policies.tf
module "policies" {
  source = "git::https://github.com/seera-eswara/terraform-policy-as-code.git//modules/policies?ref=v1.1.0"  # ← Updated
}

# Step 2: Apply upgrade
terraform apply

# Step 3: Existing subscriptions automatically get new policies
# (Policy hierarchy cascades changes)
```

---

## Security & Governance

### Policy Audit Trail
```
terraform-policy-as-code (Git)
├─ v1.0.0 - Initial policies
├─ v1.0.1 - Fix naming regex
├─ v1.1.0 - Add cost tagging
└─ v1.2.0 - Require encryption

Each version:
├─ Reviewable in GitHub
├─ Tagged and released
├─ Tested before deployment
└─ Deployed via terraform-azure-landingzone
```

### Policy Compliance Checking
```
App Team Deployment
├─ Terraform code written
├─ conftest validates against:
│  ├─ Naming rules
│  ├─ Tagging rules
│  ├─ SKU restrictions
│  ├─ Region restrictions
│  └─ Compliance rules (encryption, etc.)
├─ If violates: Deployment blocked
└─ If passes: Deployment allowed
```

---

## Troubleshooting

### Issue: App deployment fails with "Policy violation"

**Diagnosis**:
```
Error: conftest violation
Reason: Resource name doesn't match naming convention
```

**Resolution**:
1. Check policy repo version in CI/CD
2. Review naming rules in terraform-policy-as-code/opa/naming.rego
3. Update resource name to match pattern
4. Redeploy

### Issue: New policy doesn't apply to existing subscriptions

**Diagnosis**:
```
Old subscriptions don't have new policy
```

**Resolution**:
1. Run: `terraform-azure-subscription-factory apply`
2. Existing subscriptions inherit from parent MG
3. New policies cascade automatically
4. Verify: Check Azure Portal > Policy > Compliance

### Issue: Policy version mismatch between repos

**Diagnosis**:
```
Landing zone uses v1.0.0
CI/CD pipeline uses v1.1.0
Results in different validations
```

**Resolution**:
1. Standardize version across all repos
2. Update:
   - terraform-azure-landingzone (ref= in module)
   - github-actions-templates (ref= in checkout)
   - Subscription factory (ref= in data source)
3. Test before deploying

---

## Reference Links

| Component | Repository | Key Files |
|-----------|-----------|-----------|
| Landing Zone | terraform-azure-landingzone | management-groups/main.tf, policies.tf |
| Subscription Factory | terraform-azure-subscription-factory | main.tf, modules/subscription/policies.tf |
| Policies | terraform-policy-as-code | modules/policies/, policies/definitions/ |
| Apps | app1-infra, app2-infra | .github/workflows/iac-pipeline.yml |

---

**Document Version**: 1.0  
**Last Updated**: January 18, 2026  
**Maintained By**: Infrastructure Team
