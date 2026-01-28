# App-Based Management Group & Subscription Architecture Guide

## Overview

This guide explains the app-based management group architecture that provides per-application isolation while maintaining centralized governance.

## Architecture Pattern

### Management Group Hierarchy

```
Azure Tenant (Root)
└── LandingZones
    └── Applications
        ├── MG-RFF (app code: RFF)
        ├── MG-ABC (app code: ABC)
        └── MG-XYZ (app code: XYZ)
```

### Subscription Naming Pattern

Each application can have multiple module-based subscriptions across environments:

```
{APP_CODE}-{MODULE}-{ENVIRONMENT}

Examples:
- RFF-REACT-DEV   (RFF app, React module, Development)
- RFF-REACT-STG   (RFF app, React module, Staging)
- RFF-REACT-PRD   (RFF app, React module, Production)

- RFF-API-DEV     (RFF app, API module, Development)
- RFF-API-STG     (RFF app, API module, Staging)
- RFF-API-PRD     (RFF app, API module, Production)
```

## Implementing App MGs

### Step 1: Define Apps in Landing Zone

Edit `terraform-azure-landingzone/management-groups/terraform.tfvars`:

```hcl
app_management_groups = {
  "RFF" = {
    owners       = ["11111111-1111-1111-1111-111111111111"]  # App owner team
    contributors = ["22222222-2222-2222-2222-222222222222"]  # DevOps team
  }
  "ABC" = {
    owners = ["33333333-3333-3333-3333-333333333333"]
  }
  "XYZ" = {
    owners       = ["44444444-4444-4444-4444-444444444444"]
    contributors = ["55555555-5555-5555-5555-555555555555"]
  }
}
```

### Step 2: Apply Management Groups

```bash
cd terraform-azure-landingzone/management-groups

terraform init
terraform plan
terraform apply
```

**Output**:
```
Outputs:

app_management_group_ids = {
  "RFF" = "/providers/Microsoft.Management/managementGroups/mg-rff"
  "ABC" = "/providers/Microsoft.Management/managementGroups/mg-abc"
  "XYZ" = "/providers/Microsoft.Management/managementGroups/mg-xyz"
}

app_management_group_display_names = {
  "RFF" = "MG-RFF"
  "ABC" = "MG-ABC"
  "XYZ" = "MG-XYZ"
}
```

## Provisioning Subscriptions

### Step 1: Create Request Files

For each environment (dev, staging, prod), create a YAML file in the appropriate requests folder:

**`terraform-azure-subscription-factory/requests/dev/rff-react.yaml`**:
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
application_id: rff-react
```

**`terraform-azure-subscription-factory/requests/staging/rff-react.yaml`**:
```yaml
subscription_name: rff-react-stg
environment: stage
app_code: RFF
module: REACT

owners:
  - 11111111-1111-1111-1111-111111111111
  - 22222222-2222-2222-2222-222222222222

billing_entity: RFF-TEAM
cost_center: CC-RFF-001
application_id: rff-react
```

**`terraform-azure-subscription-factory/requests/prod/rff-react.yaml`**:
```yaml
subscription_name: rff-react-prd
environment: prod
app_code: RFF
module: REACT

owners:
  - 11111111-1111-1111-1111-111111111111
  - 22222222-2222-2222-2222-222222222222

billing_entity: RFF-TEAM
cost_center: CC-RFF-001
application_id: rff-react
```

### Step 2: Provision Subscriptions

```bash
cd terraform-azure-subscription-factory

# This will create subscriptions for all request files
terraform init
terraform plan
terraform apply
```

**Created Resources**:
```
✓ Subscription: rff-react-dev
  - Assigned to: MG-RFF
  - Resource Group: rg-rff-react-dev
  - Log Analytics: log-rff-react-dev
  - Policies inherited from MG-RFF and Applications MG

✓ Subscription: rff-react-stg
  - Assigned to: MG-RFF
  - Resource Group: rg-rff-react-stg
  - Log Analytics: log-rff-react-stg
  - Policies inherited from MG-RFF and Applications MG

✓ Subscription: rff-react-prd
  - Assigned to: MG-RFF
  - Resource Group: rg-rff-react-prd
  - Log Analytics: log-rff-react-prd
  - Policies inherited from MG-RFF and Applications MG
```

## Policy Inheritance Flow

```
Root (Tenant)
├── Policies applied here
│
└── LandingZones MG
    ├── Policies applied here (all landing zone apps inherit)
    │
    └── Applications MG
        ├── Policies applied here (all app MGs inherit)
        │
        └── MG-RFF
            ├── Policies applied here (all RFF subscriptions inherit)
            │
            ├── rff-react-dev subscription (inherits all above)
            ├── rff-react-stg subscription (inherits all above)
            └── rff-react-prd subscription (inherits all above)
```

## Key Benefits

### 1. **Team Isolation**
- Each app has its own management group
- Team leads can manage app-specific policies and RBAC
- Clear ownership boundaries

### 2. **Policy Governance**
- Policies defined at Applications level apply to all apps
- App-specific policies can be added at MG-{APP} level
- Subscription-level policies for environment-specific rules

### 3. **Scalability**
- Adding a new app: just add to `app_management_groups` variable
- Adding new module/environment: just create new subscription request YAML
- No changes to infrastructure code needed

### 4. **Cost Management**
- Per-app cost tracking via billing entity and cost center tags
- Budget alerts per subscription
- Easy to correlate costs to applications

### 5. **Compliance & Audit**
- Policy compliance reported per app via MG
- Clear audit trail of who deployed what
- RBAC at MG level enables team-based governance

## Onboarding a New Application

### Quick Steps

1. **Add to terraform.tfvars** in landing zone:
   ```hcl
   "NEWAPP" = {
     owners = ["owner-uuid"]
   }
   ```

2. **Apply management groups**:
   ```bash
   cd terraform-azure-landingzone/management-groups
   terraform apply
   # Creates: MG-NEWAPP
   ```

3. **Create subscription requests** (3 files for 3 envs):
   ```bash
   # requests/dev/newapp-module.yaml
   # requests/staging/newapp-module.yaml
   # requests/prod/newapp-module.yaml
   ```

4. **Apply subscriptions**:
   ```bash
   cd terraform-azure-subscription-factory
   terraform apply
   # Creates: NEWAPP-MODULE-DEV, NEWAPP-MODULE-STG, NEWAPP-MODULE-PRD
   ```

5. **Share details with app team**:
   - Subscription IDs
   - Resource group names
   - Management group name
   - Inherited policies
   - RBAC assignments

## Reference: RFF Application Setup

### Files Created

```
terraform-azure-landingzone/
└── modules/
    └── app-management-group/        (NEW - Reusable module)
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md

terraform-azure-subscription-factory/
└── requests/
    ├── dev/
    │   └── rff-react.yaml           (NEW)
    ├── staging/
    │   └── rff-react.yaml           (NEW)
    └── prod/
        └── rff-react.yaml           (NEW)
```

### Updated Files

- `terraform-azure-landingzone/management-groups/main.tf` - Added app MG module
- `terraform-azure-landingzone/management-groups/variables.tf` - Added `app_management_groups` variable
- `terraform-azure-landingzone/management-groups/outputs.tf` - Added app MG outputs
- `ARCHITECTURE_INTEGRATION.md` - Added complete app-based architecture section

## Troubleshooting

### App MG Not Created
```bash
# Check if app_management_groups is defined in terraform.tfvars
cat terraform-azure-landingzone/management-groups/terraform.tfvars | grep app_management_groups

# Validate the variable format
terraform validate
```

### Subscription Not Assigned to Correct MG
```bash
# Check app_code matches exactly (case-sensitive in lookup)
cat terraform-azure-subscription-factory/requests/dev/*.yaml | grep app_code

# Verify MG exists
az account management-group show --name mg-rff
```

### Policy Not Applied
```bash
# Policies are inherited automatically from parent MG
# If not showing:
# 1. Wait 15-20 minutes for propagation
# 2. Check policy is assigned to Applications or MG-{APP}
# 3. Verify no policy exemptions are blocking
az policy assignment list --scope "/providers/Microsoft.Management/managementGroups/mg-rff"
```

## Next Steps

1. **Define your apps** and add to landing zone
2. **Provision management groups** for each app
3. **Create subscription requests** for each environment
4. **Provision subscriptions** via factory
5. **Configure app-level policies** as needed
6. **Communicate to teams** their subscription details
