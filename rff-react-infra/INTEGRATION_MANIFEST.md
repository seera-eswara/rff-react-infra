# RFF React Integration Manifest

This manifest documents the complete integration details for the RFF React application across all environments.

## Application Information

- **App Code**: `rff`
- **Module**: `react`
- **Team**: RFF-TEAM
- **Cost Center**: CC-RFF-001
- **Owner**: Seera Eswara Rao (4202840f-7cb6-4012-b0f3-5dadda936b61)

## Management Group Structure

```
Tenant Root
└── Applications (mg-applications)
    └── MG-RFF (mg-rff)
        ├── rff-react-dev subscription
        ├── rff-react-stage subscription
        └── rff-react-prod subscription
```

## Environment Details

### Development Environment

| Property | Value |
|----------|-------|
| **Subscription Name** | rff-react-dev |
| **Subscription ID** | *To be populated after creation* |
| **Management Group** | mg-rff |
| **Resource Group** | rg-rff-react-dev |
| **Location** | eastus |
| **VNet CIDR** | 10.10.0.0/16 |
| **App Subnet** | 10.10.1.0/24 |
| **Data Subnet** | 10.10.2.0/24 |
| **State File Key** | rff-react/dev.tfstate |
| **Log Analytics** | law-rff-react-dev |

**Resources Created:**
- Virtual Network: `vnet-rff-react-dev`
- Storage Account: `strffreactdev` (Static website hosting)
- Key Vault: `kv-rff-react-dev`
- Application Insights: `appi-rff-react-dev`
- Network Security Groups: `nsg-rff-react-app-dev`, `nsg-rff-react-data-dev`

### Staging Environment

| Property | Value |
|----------|-------|
| **Subscription Name** | rff-react-stage |
| **Subscription ID** | *To be populated after creation* |
| **Management Group** | mg-rff |
| **Resource Group** | rg-rff-react-stage |
| **Location** | eastus |
| **VNet CIDR** | 10.11.0.0/16 |
| **App Subnet** | 10.11.1.0/24 |
| **Data Subnet** | 10.11.2.0/24 |
| **State File Key** | rff-react/stage.tfstate |
| **Log Analytics** | law-rff-react-stage |

**Resources Created:**
- Virtual Network: `vnet-rff-react-stage`
- Storage Account: `strffreactstage` (Static website hosting with GRS)
- Key Vault: `kv-rff-react-stage`
- Application Insights: `appi-rff-react-stage`
- Network Security Groups: `nsg-rff-react-app-stage`, `nsg-rff-react-data-stage`

### Production Environment

| Property | Value |
|----------|-------|
| **Subscription Name** | rff-react-prod |
| **Subscription ID** | *To be populated after creation* |
| **Management Group** | mg-rff |
| **Resource Group** | rg-rff-react-prod |
| **Location** | eastus |
| **VNet CIDR** | 10.12.0.0/16 |
| **App Subnet** | 10.12.1.0/24 |
| **Data Subnet** | 10.12.2.0/24 |
| **State File Key** | rff-react/prod.tfstate |
| **Log Analytics** | law-rff-react-prod |

**Resources Created:**
- Virtual Network: `vnet-rff-react-prod`
- Storage Account: `strffreactprod` (Static website hosting with ZRS + versioning)
- Key Vault: `kv-rff-react-prod` (with purge protection)
- Application Insights: `appi-rff-react-prod`
- Network Security Groups: `nsg-rff-react-app-prod`, `nsg-rff-react-data-prod`

## Service Principal / Managed Identity

### For GitHub Actions CI/CD

**To be created by Platform Team:**

```bash
# Create app registration
az ad app create --display-name "terraform-rff-react-ci"
APP_ID=$(az ad app list --filter "displayName eq 'terraform-rff-react-ci'" -o tsv --query '[0].appId')
OBJECT_ID=$(az ad sp create --id $APP_ID -o tsv --query objectId)

# Create federated credentials for GitHub OIDC
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "gh-actions-rff-react",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/rff-react-infra:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Grant Contributor role on each subscription
az role assignment create \
  --assignee $OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$DEV_SUBSCRIPTION_ID"

az role assignment create \
  --assignee $OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$STAGE_SUBSCRIPTION_ID"

az role assignment create \
  --assignee $OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/$PROD_SUBSCRIPTION_ID"
```

| Property | Value |
|----------|-------|
| **App Registration Name** | terraform-rff-react-ci |
| **Client ID** | *To be populated* |
| **Tenant ID** | *To be populated* |
| **Service Principal Object ID** | *To be populated* |

## GitHub Secrets Configuration

Add the following secrets to the `rff-react-infra` GitHub repository:

```bash
# Repository Secrets
AZURE_CLIENT_ID=<client-id-from-app-registration>
AZURE_TENANT_ID=<tenant-id>

# Environment-specific secrets
# Dev Environment
AZURE_SUBSCRIPTION_ID_DEV=<dev-subscription-id>

# Stage Environment
AZURE_SUBSCRIPTION_ID_STAGE=<stage-subscription-id>

# Prod Environment
AZURE_SUBSCRIPTION_ID_PROD=<prod-subscription-id>
```

## Backend State Configuration

All environments use the shared Terraform state storage:

| Property | Value |
|----------|-------|
| **Resource Group** | rg-tfstate |
| **Storage Account** | tfstatelzqiaypb |
| **Container** | tfstate |
| **Dev State Key** | rff-react/dev.tfstate |
| **Stage State Key** | rff-react/stage.tfstate |
| **Prod State Key** | rff-react/prod.tfstate |

## Hub-Spoke Networking Integration

The platform team needs to add the following configuration to establish hub-spoke peering:

**File**: `terraform-azure-landingzone/terraform.tfvars`

```hcl
app_spoke_vnets = {
  # ... existing spokes ...
  
  "rff-react-dev" = {
    vnet_id = "/subscriptions/<dev-subscription-id>/resourceGroups/rg-rff-react-dev/providers/Microsoft.Network/virtualNetworks/vnet-rff-react-dev"
  }
  "rff-react-stage" = {
    vnet_id = "/subscriptions/<stage-subscription-id>/resourceGroups/rg-rff-react-stage/providers/Microsoft.Network/virtualNetworks/vnet-rff-react-stage"
  }
  "rff-react-prod" = {
    vnet_id = "/subscriptions/<prod-subscription-id>/resourceGroups/rg-rff-react-prod/providers/Microsoft.Network/virtualNetworks/vnet-rff-react-prod"
  }
}
```

## RBAC Assignments

### Subscription Level

- **Owner**: Seera Eswara Rao (4202840f-7cb6-4012-b0f3-5dadda936b61)
- **Contributor**: terraform-rff-react-ci (Service Principal)

### Management Group Level (mg-rff)

- **Owner**: Seera Eswara Rao
- Policies inherited from Applications management group

## Next Steps

### For Platform Team

1. ✅ Review and approve subscription requests in `terraform-azure-subscription-factory/requests/`
2. ⏳ Run subscription factory to create subscriptions (dev, stage, prod)
3. ⏳ Create service principal and federated credentials for GitHub Actions
4. ⏳ Update this manifest with actual subscription IDs and service principal details
5. ⏳ Configure GitHub secrets in `rff-react-infra` repository
6. ⏳ Run app infrastructure deployment for each environment
7. ⏳ Update landing zone with spoke VNet peering configuration

### For App Team

1. ⏳ Review infrastructure code in `rff-react-infra` repository
2. ⏳ Verify GitHub Actions workflow configuration
3. ⏳ Test local deployment to dev environment
4. ⏳ Deploy application code to storage account static website
5. ⏳ Configure custom domain and SSL certificate (if needed)
6. ⏳ Set up monitoring alerts in Application Insights

## Support Contacts

- **Platform Team**: cloud-team@company.com
- **Security Team**: security@company.com
- **App Owner**: Seera Eswara Rao

## Documentation References

- [ONBOARDING.md](/ONBOARDING.md)
- [INTEGRATION_CHECKLIST.md](/INTEGRATION_CHECKLIST.md)
- [APP_SPOKE_INTEGRATION.md](/terraform-azure-landingzone/docs/APP_SPOKE_INTEGRATION.md)
- [rff-react-infra README](/rff-react-infra/README.md)
