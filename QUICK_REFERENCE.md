# Quick Reference: App-Based Management Group Architecture

## Naming Patterns

### Management Groups
```
MG-{APP_CODE}

Examples:
- MG-RFF  (Resource name: mg-rff)
- MG-ABC  (Resource name: mg-abc)
- MG-PAYMENT  (Resource name: mg-payment)
```

### Subscriptions
```
{APP_CODE}-{MODULE}-{ENV}

Where:
- APP_CODE = 3-10 character app identifier (e.g., RFF, ABC, PAYMENT)
- MODULE = Technology/functional area (e.g., REACT, API, ML, BACKEND, FRONTEND)
- ENV = Environment (DEV, STG, PRD)

Examples:
- RFF-REACT-DEV
- RFF-REACT-STG
- RFF-REACT-PRD
- ABC-API-DEV
- ABC-API-STG
- ABC-API-PRD
- PAYMENT-ML-DEV
- PAYMENT-ML-STG
- PAYMENT-ML-PRD
```

---

## Quick Start: Create App MG + Subscriptions

### Step 1: Define App (5 minutes)

Edit: `terraform-azure-landingzone/management-groups/terraform.tfvars`

```hcl
app_management_groups = {
  "RFF" = {
    owners = ["11111111-1111-1111-1111-111111111111"]
  }
}
```

Get Principal ID:
```bash
az ad user show --id john@company.com --query id
```

### Step 2: Create App MG (5 minutes)

```bash
cd terraform-azure-landingzone/management-groups
terraform init
terraform apply
# Creates: MG-RFF under Applications
```

### Step 3: Create Subscription Requests (2 minutes)

Files already created:
- `terraform-azure-subscription-factory/requests/dev/rff-react.yaml`
- `terraform-azure-subscription-factory/requests/staging/rff-react.yaml`
- `terraform-azure-subscription-factory/requests/prod/rff-react.yaml`

Update owner UUIDs in each file to match Step 1.

### Step 4: Create Subscriptions (5 minutes)

```bash
cd terraform-azure-subscription-factory
terraform init
terraform apply
# Creates: rff-react-dev, rff-react-stg, rff-react-prd
# Assigns all to: MG-RFF
```

**Done!** ✅ App ready with 3 subscriptions across environments

---

## File Locations

### Defining Apps
```
terraform-azure-landingzone/management-groups/terraform.tfvars
```

### Creating Subscriptions
```
terraform-azure-subscription-factory/requests/
├── dev/*.yaml
├── staging/*.yaml
└── prod/*.yaml
```

### Module Code
```
terraform-azure-landingzone/modules/app-management-group/
├── main.tf        (Create MG + RBAC)
├── variables.tf   (Inputs: app_code, parent MG, owners)
└── outputs.tf     (Outputs: MG ID, name, display name)
```

---

## Key Concepts

### Policy Inheritance
```
Policies at Applications MG
           ↓ (automatic)
        MG-RFF
           ↓ (automatic)
All subscriptions under MG-RFF
```

### Team Isolation
- Each app gets own MG with separate RBAC
- App teams can't see/modify other apps' subscriptions
- App leaders assigned to their MG

### Environment Consistency
- Same baseline resources per subscription
- Consistent naming across environments
- Easy to replicate config across dev/stg/prod

---

## Common Tasks

### Add New App
```
1. Add "APPCODE" entry to app_management_groups in terraform.tfvars
2. terraform apply
3. Done! MG-APPCODE created
```

### Add New Subscription to Existing App
```
1. Create new YAML file in requests/env/
   Example: terraform-azure-subscription-factory/requests/dev/rff-api.yaml
2. Set app_code: RFF (same as existing)
3. terraform apply
4. Subscription created under MG-RFF
```

### Add New Environment
```
1. Create new YAML files in requests/newenv/
   Example: requests/uat/rff-react.yaml
2. Set environment: uat in YAML
3. terraform apply
```

### Get Subscription Details
```bash
# List all RFF subscriptions
az account subscription list --query "[?contains(displayName, 'rff')]"

# Get specific subscription
az account subscription list --query "[?displayName=='rff-react-dev']"
```

### Check App MG Policies
```bash
# List policies assigned to MG-RFF
az policy assignment list --scope "/providers/Microsoft.Management/managementGroups/mg-rff"
```

### Add Member to App Owner Role
```bash
# First, get the MG ID
MG_ID=$(az account management-group show --name mg-rff --query id -o tsv)

# Assign role
az role assignment create \
  --role "Management Group Contributor" \
  --assignee "new-person@company.com" \
  --scope "$MG_ID"
```

---

## File Format Cheatsheet

### terraform.tfvars (Management Groups)
```hcl
app_management_groups = {
  "APP_CODE" = {
    owners       = ["principal-id-1", "principal-id-2"]
    contributors = ["principal-id-3"]
  }
}
```

### YAML (Subscription Requests)
```yaml
subscription_name: app-module-env
environment: dev
app_code: APP
module: MODULE
owners:
  - principal-id-1
  - principal-id-2
billing_entity: TEAM_NAME
cost_center: CC-CODE
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| MG not created | Check app_code in terraform.tfvars, run `terraform apply` |
| Subscription not in MG | Verify app_code in YAML matches MG (case-sensitive), wait 5 min |
| Policy not inherited | Policies take 15-20 min to propagate, check parent MG |
| Principal ID invalid | Get fresh ID: `az ad user show --id email --query id` |
| YAML not parsed | Validate YAML: `terraform validate` |

---

## Documentation

| Document | Purpose |
|----------|---------|
| [APP_MANAGEMENT_GROUP_GUIDE.md](APP_MANAGEMENT_GROUP_GUIDE.md) | Complete setup & troubleshooting |
| [ARCHITECTURE_INTEGRATION.md](ARCHITECTURE_INTEGRATION.md) | Architecture overview & flows |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | What was created & how to use |
| [terraform-azure-subscription-factory/requests/README.md](terraform-azure-subscription-factory/requests/README.md) | Subscription request details |

---

## Example: RFF App (Already Set Up)

### Already Created
```
Management Group: MG-RFF
  ├── Subscription: rff-react-dev
  ├── Subscription: rff-react-stg
  └── Subscription: rff-react-prd
```

### To Activate
1. Update principal IDs in YAML files
2. Update principal ID in terraform.tfvars
3. Run terraform apply
4. Share details with RFF team

### Files
```
terraform-azure-landingzone/management-groups/terraform.tfvars
  → Add RFF section with principal IDs

terraform-azure-subscription-factory/requests/
  dev/rff-react.yaml      (UPDATE: principal IDs)
  staging/rff-react.yaml  (UPDATE: principal IDs)
  prod/rff-react.yaml     (UPDATE: principal IDs)
```

---

## Success Criteria

✅ Management group created: `az account management-group show --name mg-rff`

✅ Subscriptions created: `az account subscription list --query "[?displayName=='rff-react-dev']"`

✅ Subscriptions assigned to MG: `az account management-group subscription show --name mg-rff --subscription rff-react-dev`

✅ Policies inherited: `az policy assignment list --scope "/providers/Microsoft.Management/managementGroups/mg-rff"`

✅ RBAC assigned: `az role assignment list --scope "/providers/Microsoft.Management/managementGroups/mg-rff"`

---

*For detailed information, see the full documentation in [APP_MANAGEMENT_GROUP_GUIDE.md](APP_MANAGEMENT_GROUP_GUIDE.md)*
