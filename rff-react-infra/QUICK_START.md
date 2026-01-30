# 🚀 RFF React Quick Start Guide

This guide provides the essential commands to complete the RFF React onboarding.

## Current Status: ✅ Infrastructure Ready

All code and documentation has been created. Now we need to execute the deployment.

---

## Step-by-Step Execution

### 1️⃣ Create Subscriptions (Platform Team)

Execute these commands to create subscriptions using the subscription factory:

```bash
cd /home/eswar/IAC-pipeline/terraform-azure-subscription-factory

# DEV Environment
terraform plan \
  -var="app_code=rff" \
  -var="module=react" \
  -var="environment=dev" \
  -var="billing_entity=RFF-TEAM" \
  -var="owners=[\"4202840f-7cb6-4012-b0f3-5dadda936b61\"]" \
  -var="billing_scope_id=<YOUR_BILLING_SCOPE_ID>"

terraform apply  # Review and confirm

# STAGE Environment
terraform plan \
  -var="app_code=rff" \
  -var="module=react" \
  -var="environment=stage" \
  -var="billing_entity=RFF-TEAM" \
  -var="owners=[\"4202840f-7cb6-4012-b0f3-5dadda936b61\"]" \
  -var="billing_scope_id=<YOUR_BILLING_SCOPE_ID>"

terraform apply  # Review and confirm

# PROD Environment
terraform plan \
  -var="app_code=rff" \
  -var="module=react" \
  -var="environment=prod" \
  -var="billing_entity=RFF-TEAM" \
  -var="owners=[\"4202840f-7cb6-4012-b0f3-5dadda936b61\"]" \
  -var="billing_scope_id=<YOUR_BILLING_SCOPE_ID>"

terraform apply  # Review and confirm

# Capture subscription IDs
DEV_SUB_ID=$(terraform output -raw subscription_id)
# Repeat for stage and prod
```

📝 **Document the subscription IDs** for the next steps.

---

### 2️⃣ Create Service Principal for CI/CD

```bash
# Create app registration
az ad app create --display-name "terraform-rff-react-ci"

# Get App ID
APP_ID=$(az ad app list \
  --filter "displayName eq 'terraform-rff-react-ci'" \
  -o tsv --query '[0].appId')

echo "Client ID (save this): $APP_ID"

# Create service principal
OBJECT_ID=$(az ad sp create --id $APP_ID -o tsv --query objectId)
echo "Service Principal Object ID: $OBJECT_ID"

# Get Tenant ID
TENANT_ID=$(az account show -o tsv --query tenantId)
echo "Tenant ID: $TENANT_ID"

# Create federated credential for GitHub
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "gh-actions-rff-react",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/rff-react-infra:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Assign Contributor role to subscriptions
az role assignment create \
  --assignee $OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$DEV_SUB_ID"

az role assignment create \
  --assignee $OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$STAGE_SUB_ID"

az role assignment create \
  --assignee $OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$PROD_SUB_ID"

# Grant access to Terraform state storage
az role assignment create \
  --assignee $OBJECT_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/<TFSTATE_SUB_ID>/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatelzqiaypb"

echo ""
echo "✅ Service Principal Created!"
echo "Client ID: $APP_ID"
echo "Tenant ID: $TENANT_ID"
echo "Object ID: $OBJECT_ID"
```

---

### 3️⃣ Configure GitHub Secrets

Add these secrets to your `rff-react-infra` GitHub repository:

**Via GitHub UI**: Settings → Secrets and variables → Actions → New repository secret

Or **via GitHub CLI**:

```bash
gh secret set AZURE_CLIENT_ID --body "$APP_ID" --repo YOUR_ORG/rff-react-infra
gh secret set AZURE_TENANT_ID --body "$TENANT_ID" --repo YOUR_ORG/rff-react-infra
gh secret set AZURE_SUBSCRIPTION_ID_DEV --body "$DEV_SUB_ID" --repo YOUR_ORG/rff-react-infra
gh secret set AZURE_SUBSCRIPTION_ID_STAGE --body "$STAGE_SUB_ID" --repo YOUR_ORG/rff-react-infra
gh secret set AZURE_SUBSCRIPTION_ID_PROD --body "$PROD_SUB_ID" --repo YOUR_ORG/rff-react-infra
```

---

### 4️⃣ Update Infrastructure Configuration

```bash
cd /home/eswar/IAC-pipeline/rff-react-infra

# Get Hub VNet ID from platform team
HUB_VNET_ID=$(cd ../terraform-azure-landingzone && terraform output -raw hub_vnet_id)

# Create dev.tfvars
cat > envs/dev/dev.tfvars <<EOF
subscription_id     = "$DEV_SUB_ID"
location            = "eastus"
vnet_address_space  = "10.10.0.0/16"
app_subnet_prefix   = "10.10.1.0/24"
data_subnet_prefix  = "10.10.2.0/24"
hub_vnet_id         = "$HUB_VNET_ID"
EOF

# Create stage.tfvars
cat > envs/stage/stage.tfvars <<EOF
subscription_id     = "$STAGE_SUB_ID"
location            = "eastus"
vnet_address_space  = "10.11.0.0/16"
app_subnet_prefix   = "10.11.1.0/24"
data_subnet_prefix  = "10.11.2.0/24"
hub_vnet_id         = "$HUB_VNET_ID"
EOF

# Create prod.tfvars
cat > envs/prod/prod.tfvars <<EOF
subscription_id     = "$PROD_SUB_ID"
location            = "eastus"
vnet_address_space  = "10.12.0.0/16"
app_subnet_prefix   = "10.12.1.0/24"
data_subnet_prefix  = "10.12.2.0/24"
hub_vnet_id         = "$HUB_VNET_ID"
EOF

echo "✅ Configuration files created!"
```

---

### 5️⃣ Deploy Infrastructure

```bash
cd /home/eswar/IAC-pipeline/rff-react-infra

# Deploy DEV
cd envs/dev
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars

# Capture VNet ID for peering
DEV_VNET_ID=$(terraform output -raw vnet_id)
echo "Dev VNet ID: $DEV_VNET_ID"

# Deploy STAGE
cd ../stage
terraform init
terraform plan -var-file=stage.tfvars
terraform apply -var-file=stage.tfvars

STAGE_VNET_ID=$(terraform output -raw vnet_id)
echo "Stage VNet ID: $STAGE_VNET_ID"

# Deploy PROD
cd ../prod
terraform init
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars

PROD_VNET_ID=$(terraform output -raw vnet_id)
echo "Prod VNet ID: $PROD_VNET_ID"

echo ""
echo "✅ All environments deployed!"
```

---

### 6️⃣ Configure Hub-Spoke Peering

```bash
cd /home/eswar/IAC-pipeline/terraform-azure-landingzone

# Backup current tfvars
cp terraform.tfvars terraform.tfvars.backup

# Add RFF React spoke VNets
cat >> terraform.tfvars <<EOF

# RFF React Application Spokes
app_spoke_vnets = merge(var.app_spoke_vnets, {
  "rff-react-dev" = {
    vnet_id = "$DEV_VNET_ID"
  }
  "rff-react-stage" = {
    vnet_id = "$STAGE_VNET_ID"
  }
  "rff-react-prod" = {
    vnet_id = "$PROD_VNET_ID"
  }
})
EOF

# Apply peering configuration
terraform plan
terraform apply

echo "✅ Hub-spoke peering established!"
```

---

### 7️⃣ Deploy React Application

```bash
# Build your React app
cd /path/to/your/react-app
npm install
npm run build

# Deploy to DEV
az storage blob upload-batch \
  --account-name strffreactdev \
  --destination '$web' \
  --source ./build \
  --overwrite

# Get the website URL
az storage account show \
  --name strffreactdev \
  --resource-group rg-rff-react-dev \
  --query "primaryEndpoints.web" \
  --output tsv

echo "✅ Application deployed to DEV!"
```

---

### 8️⃣ Verify Deployment

```bash
# Check subscription
az account subscription show --id $DEV_SUB_ID

# Check resource group
az group show --name rg-rff-react-dev

# Check VNet peering status
az network vnet peering list \
  --resource-group rg-rff-react-dev \
  --vnet-name vnet-rff-react-dev \
  --output table

# Check storage account website
curl -I $(az storage account show \
  --name strffreactdev \
  --resource-group rg-rff-react-dev \
  --query "primaryEndpoints.web" \
  --output tsv)

echo "✅ All checks passed!"
```

---

## 🎯 Summary of What Gets Created

### Per Environment (Dev, Stage, Prod):
- ✅ Azure Subscription
- ✅ Management Group Association
- ✅ Resource Group
- ✅ Virtual Network with 2 subnets
- ✅ Network Security Groups
- ✅ Storage Account (Static Website)
- ✅ Key Vault
- ✅ Application Insights
- ✅ Log Analytics Workspace
- ✅ Hub-Spoke VNet Peering

### Platform Level:
- ✅ Service Principal for CI/CD
- ✅ GitHub Actions Workflow
- ✅ Terraform State Management
- ✅ RBAC Assignments

---

## 📊 Resource Summary

| Environment | VNet CIDR | Subscription | Storage Account | Peering Status |
|-------------|-----------|--------------|-----------------|----------------|
| Dev | 10.10.0.0/16 | rff-react-dev | strffreactdev | ⏳ Pending |
| Stage | 10.11.0.0/16 | rff-react-stage | strffreactstage | ⏳ Pending |
| Prod | 10.12.0.0/16 | rff-react-prod | strffreactprod | ⏳ Pending |

---

## 🆘 Troubleshooting

### Issue: terraform init fails
```bash
# Check backend storage exists
az storage account show --name tfstatelzqiaypb

# Verify you have access
az storage container list --account-name tfstatelzqiaypb
```

### Issue: Service principal can't authenticate
```bash
# Verify federated credential
az ad app federated-credential list --id $APP_ID

# Check role assignments
az role assignment list --assignee $OBJECT_ID
```

### Issue: VNet peering not connecting
```bash
# Check peering status
az network vnet peering show \
  --name hub-to-rff-react-dev \
  --resource-group rg-hub-network \
  --vnet-name vnet-hub

# Verify no CIDR overlap
az network vnet show --name vnet-hub --resource-group rg-hub-network --query addressSpace
```

---

## 📚 Documentation References

- [Detailed Onboarding Summary](RFF_REACT_ONBOARDING.md)
- [Integration Manifest](rff-react-infra/INTEGRATION_MANIFEST.md)
- [Detailed Checklist](rff-react-infra/ONBOARDING_CHECKLIST.md)
- [Hub-Spoke Peering Guide](rff-react-infra/HUB_SPOKE_PEERING.md)

---

## ✅ Completion Checklist

- [ ] Subscriptions created (dev, stage, prod)
- [ ] Service principal created and configured
- [ ] GitHub secrets configured
- [ ] Infrastructure deployed (all 3 environments)
- [ ] Hub-spoke peering established
- [ ] React application deployed
- [ ] Monitoring configured
- [ ] Team handoff completed

---

**Ready to start?** Begin with Step 1 above! 🚀
