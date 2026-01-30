# Hub-Spoke VNet Peering Configuration for RFF React

## Instructions for Platform Team

After the RFF React infrastructure is deployed in each environment, add the following configuration to establish hub-spoke VNet peering.

## File to Update

**Location**: `/home/eswar/IAC-pipeline/terraform-azure-landingzone/terraform.tfvars`

## Configuration to Add

Add the following to the `app_spoke_vnets` map in the terraform.tfvars file:

```hcl
app_spoke_vnets = {
  # ... existing app spoke VNets ...
  
  # RFF React Application Spokes
  "rff-react-dev" = {
    vnet_id = "/subscriptions/<DEV_SUBSCRIPTION_ID>/resourceGroups/rg-rff-react-dev/providers/Microsoft.Network/virtualNetworks/vnet-rff-react-dev"
  }
  "rff-react-stage" = {
    vnet_id = "/subscriptions/<STAGE_SUBSCRIPTION_ID>/resourceGroups/rg-rff-react-stage/providers/Microsoft.Network/virtualNetworks/vnet-rff-react-stage"
  }
  "rff-react-prod" = {
    vnet_id = "/subscriptions/<PROD_SUBSCRIPTION_ID>/resourceGroups/rg-rff-react-prod/providers/Microsoft.Network/virtualNetworks/vnet-rff-react-prod"
  }
}
```

## How to Get VNet IDs

After deploying the rff-react infrastructure, retrieve the VNet IDs:

```bash
# Dev Environment
cd /home/eswar/IAC-pipeline/rff-react-infra/envs/dev
terraform output vnet_id

# Stage Environment
cd /home/eswar/IAC-pipeline/rff-react-infra/envs/stage
terraform output vnet_id

# Prod Environment
cd /home/eswar/IAC-pipeline/rff-react-infra/envs/prod
terraform output vnet_id
```

## Apply the Configuration

```bash
cd /home/eswar/IAC-pipeline/terraform-azure-landingzone

# Plan to review the peering changes
terraform plan

# Review the output to ensure:
# - 3 new hub-to-spoke peerings will be created
# - 3 new spoke-to-hub peerings will be created (if not already created)
# - Private DNS zone links will be established

# Apply the changes
terraform apply
```

## What This Creates

For each spoke VNet:
1. **Hub → Spoke Peering**
   - Allows traffic from hub to spoke
   - Enables gateway transit (if configured)
   - Forwards traffic through Azure Firewall

2. **Spoke → Hub Peering**
   - Allows traffic from spoke to hub
   - Uses remote gateway
   - Routes 0.0.0.0/0 to firewall

3. **Private DNS Zone Links**
   - Links spoke VNets to hub's private DNS zones
   - Enables private endpoint resolution
   - Automatic for:
     - `privatelink.blob.core.windows.net`
     - `privatelink.vaultcore.azure.net`
     - `privatelink.azurewebsites.net`
     - `privatelink.database.windows.net`
     - And others...

## Verification Steps

After applying, verify the peering:

```bash
# Check peering status for dev
az network vnet peering list \
  --resource-group rg-hub-network \
  --vnet-name vnet-hub \
  --query "[?contains(name, 'rff-react')].{Name:name, Status:peeringState}" \
  --output table

# Expected output:
# Name                          Status
# ----------------------------  ----------
# hub-to-rff-react-dev          Connected
# hub-to-rff-react-stage        Connected
# hub-to-rff-react-prod         Connected
```

From the spoke side:

```bash
# Check spoke-to-hub peering
az network vnet peering list \
  --resource-group rg-rff-react-dev \
  --vnet-name vnet-rff-react-dev \
  --output table

# Expected output should show Connected status
```

## Troubleshooting

### Peering shows "Initiated" instead of "Connected"
- Check that both hub and spoke peerings exist
- Verify subscription permissions
- Ensure VNet address spaces don't overlap

### DNS resolution not working
- Verify private DNS zone links were created
- Check NSG rules aren't blocking DNS (port 53)
- Ensure DNS servers are set correctly (Azure-provided DNS)

### Can't reach resources in spoke from hub
- Check route tables on spoke subnets
- Verify NSG rules allow required traffic
- Ensure "Allow forwarded traffic" is enabled on peering

## Network Architecture After Peering

```
┌──────────────────────────────────────────────────────────┐
│                     Hub VNet (Platform)                   │
│                      10.0.0.0/16                          │
│                                                           │
│  ┌────────────────┐  ┌──────────────┐                   │
│  │ Azure Firewall │  │ Private DNS  │                   │
│  │   10.0.1.4     │  │    Zones     │                   │
│  └────────────────┘  └──────────────┘                   │
│           │                                               │
└───────────┼───────────────────────────────────────────────┘
            │ Peering
            │
   ┌────────┼────────┬────────────┬──────────────┐
   │                 │            │              │
   ▼                 ▼            ▼              ▼
┌─────────────┐  ┌──────────┐ ┌───────────┐  ┌──────────┐
│ RFF-React   │  │ RFF-React│ │ RFF-React │  │  Other   │
│  Dev Spoke  │  │  Stage   │ │   Prod    │  │  Spokes  │
│ 10.10.0.0/16│  │10.11.0.0 │ │10.12.0.0  │  │   ...    │
└─────────────┘  └──────────┘ └───────────┘  └──────────┘
```

## Traffic Flow

### Outbound Internet Access
```
React App → Spoke VNet → Route Table (0.0.0.0/0 → Firewall) → 
Hub Firewall → Internet
```

### Access to Azure PaaS Services
```
React App → Private Endpoint in Spoke → Private DNS Resolution → 
Private IP in Spoke/Hub
```

### Inter-Spoke Communication (if needed)
```
Spoke A → Hub Firewall → Spoke B
(Requires firewall rules to allow)
```

## Notes

- **CIDR Allocations**: Ensure no overlap
  - Hub: 10.0.0.0/16
  - RFF-React Dev: 10.10.0.0/16
  - RFF-React Stage: 10.11.0.0/16
  - RFF-React Prod: 10.12.0.0/16

- **Firewall Rules**: May need to add rules to allow specific traffic from RFF spokes

- **Cost**: VNet peering is charged per GB transferred
  - Typically $0.01-0.02 per GB depending on zones
  - Minimal cost for most workloads

- **Performance**: VNet peering provides low latency and high bandwidth
  - No bandwidth bottleneck
  - Traffic stays on Azure backbone

## Rollback Procedure

If peering needs to be removed:

```bash
# Remove from terraform.tfvars
# Then apply to remove peerings
cd /home/eswar/IAC-pipeline/terraform-azure-landingzone
terraform plan  # Verify removal
terraform apply
```

Or manually via Azure CLI:

```bash
# Delete hub-to-spoke peering
az network vnet peering delete \
  --name hub-to-rff-react-dev \
  --resource-group rg-hub-network \
  --vnet-name vnet-hub

# Delete spoke-to-hub peering
az network vnet peering delete \
  --name spoke-to-hub \
  --resource-group rg-rff-react-dev \
  --vnet-name vnet-rff-react-dev
```

---

**Document Updated**: January 29, 2026  
**Owner**: Platform Team  
**Related**: [RFF React Onboarding](../RFF_REACT_ONBOARDING.md)
