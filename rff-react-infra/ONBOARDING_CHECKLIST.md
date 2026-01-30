# RFF React Onboarding Checklist

Use this checklist to track the onboarding progress for RFF React application.

## Status: 🔄 In Progress

---

## Phase 1: Pre-Flight ✅ COMPLETE

- [x] App code is unique (rff) and follows pattern
- [x] Team lead identified (Seera Eswara Rao)
- [x] YAML request files created for all environments (dev, stage, prod)
- [x] Cost center defined (CC-RFF-001)
- [x] Management group structure planned (mg-rff under Applications)

## Phase 2: Subscription Factory Run ⏳ IN PROGRESS

### Dev Environment
- [ ] Reviewed `requests/dev/rff-react.yaml`
- [ ] Run `terraform init` in subscription factory
- [ ] Run `terraform plan` for dev subscription
- [ ] Run `terraform apply` to create dev subscription
- [ ] Verify subscription created in Azure portal
- [ ] Verify MG association (mg-rff under Applications)
- [ ] Document subscription ID: `__________________`
- [ ] Document resource group name: `rg-rff-react-dev`
- [ ] Document Log Analytics workspace ID: `__________________`

### Stage Environment
- [ ] Reviewed `requests/staging/rff-react.yaml`
- [ ] Run `terraform plan` for stage subscription
- [ ] Run `terraform apply` to create stage subscription
- [ ] Verify subscription created in Azure portal
- [ ] Document subscription ID: `__________________`
- [ ] Document resource group name: `rg-rff-react-stage`
- [ ] Document Log Analytics workspace ID: `__________________`

### Prod Environment
- [ ] Reviewed `requests/prod/rff-react.yaml`
- [ ] Run `terraform plan` for prod subscription
- [ ] Run `terraform apply` to create prod subscription
- [ ] Verify subscription created in Azure portal
- [ ] Document subscription ID: `__________________`
- [ ] Document resource group name: `rg-rff-react-prod`
- [ ] Document Log Analytics workspace ID: `__________________`

## Phase 3: Integration Setup ⏳ IN PROGRESS

### Service Principal & App Registration

- [ ] Created Azure AD app registration (`terraform-rff-react-ci`)
- [ ] Created service principal from app registration
- [ ] Documented:
  - [ ] Client ID (app registration ID): `__________________`
  - [ ] Tenant ID: `__________________`
  - [ ] Service Principal Object ID: `__________________`
- [ ] Created federated credential for GitHub OIDC
  - [ ] Issuer: `https://token.actions.githubusercontent.com`
  - [ ] Subject: `repo:YOUR_ORG/rff-react-infra:ref:refs/heads/main`
  - [ ] Audiences: `api://AzureADTokenExchange`
- [ ] Assigned Contributor role to SPN at dev subscription scope
- [ ] Assigned Contributor role to SPN at stage subscription scope
- [ ] Assigned Contributor role to SPN at prod subscription scope

### Backend State Configuration

- [x] Backend storage account exists (`tfstatelzqiaypb`)
- [x] State container configured (`tfstate`)
- [x] State keys defined:
  - [x] Dev: `rff-react/dev.tfstate`
  - [x] Stage: `rff-react/stage.tfstate`
  - [x] Prod: `rff-react/prod.tfstate`
- [ ] SPN has Storage Blob Data Contributor access to backend storage
- [ ] Verified with `az storage blob list --account-name tfstatelzqiaypb --container-name tfstate`

### GitHub Secrets

- [ ] Added `AZURE_CLIENT_ID` (client ID from app registration)
- [ ] Added `AZURE_TENANT_ID` (tenant ID)
- [ ] Added `AZURE_SUBSCRIPTION_ID_DEV` (dev subscription ID)
- [ ] Added `AZURE_SUBSCRIPTION_ID_STAGE` (stage subscription ID)
- [ ] Added `AZURE_SUBSCRIPTION_ID_PROD` (prod subscription ID)
- [ ] Verified secrets are not logged in any workflow

### App Infra Repo Initialization

- [x] Created `rff-react-infra` repository
- [x] Created directory structure: `envs/{dev,stage,prod}`
- [x] Added `providers.tf` with azurerm ~> 4.57.0
- [x] Added `backend.tf` with correct storage account, container, key
- [x] Added `main.tf` with infrastructure resources
- [x] Added `variables.tf` with all required variables
- [x] Added `outputs.tf` with resource outputs
- [x] Added `.gitignore` to exclude `.terraform/`, `*.tfvars`, etc.
- [x] Added CI/CD workflow template (`.github/workflows/terraform.yml`)
  - [x] Triggers on PR, push to main, manual dispatch
  - [x] Separate jobs for dev, stage, prod
  - [x] Uses GitHub OIDC for authentication
- [ ] Initialize Terraform: `cd envs/dev && terraform init`
- [ ] Run `terraform plan` to verify no errors
- [ ] Commit and push to repository

### Update Infrastructure Variables

After subscriptions are created, update the following files:

- [ ] Update `envs/dev/dev.tfvars` with actual subscription_id
- [ ] Update `envs/stage/stage.tfvars` with actual subscription_id
- [ ] Update `envs/prod/prod.tfvars` with actual subscription_id
- [ ] Update hub_vnet_id in all tfvars files (get from platform team)

## Phase 4: App Infrastructure Deployment 🔲 NOT STARTED

### Dev Environment
- [ ] Navigate to `rff-react-infra/envs/dev`
- [ ] Run `terraform init`
- [ ] Run `terraform plan`
- [ ] Review plan output
- [ ] Run `terraform apply`
- [ ] Verify resources created:
  - [ ] Resource Group: `rg-rff-react-dev`
  - [ ] VNet: `vnet-rff-react-dev` (10.10.0.0/16)
  - [ ] Storage Account: `strffreactdev`
  - [ ] Key Vault: `kv-rff-react-dev`
  - [ ] Application Insights: `appi-rff-react-dev`
  - [ ] NSGs created and associated with subnets
- [ ] Document VNet ID for hub peering: `__________________`

### Stage Environment
- [ ] Navigate to `rff-react-infra/envs/stage`
- [ ] Run `terraform init`
- [ ] Run `terraform plan`
- [ ] Run `terraform apply`
- [ ] Verify all resources created
- [ ] Document VNet ID for hub peering: `__________________`

### Prod Environment
- [ ] Navigate to `rff-react-infra/envs/prod`
- [ ] Run `terraform init`
- [ ] Run `terraform plan`
- [ ] Run `terraform apply`
- [ ] Verify all resources created
- [ ] Document VNet ID for hub peering: `__________________`

## Phase 5: Hub-Spoke Network Integration 🔲 NOT STARTED

- [ ] Platform team: Update `terraform-azure-landingzone/terraform.tfvars`
- [ ] Add rff-react-dev spoke VNet ID
- [ ] Add rff-react-stage spoke VNet ID
- [ ] Add rff-react-prod spoke VNet ID
- [ ] Run `terraform plan` in landing zone
- [ ] Run `terraform apply` to establish peerings
- [ ] Verify peering status in Azure portal:
  - [ ] Dev: Hub → Spoke peering = Connected
  - [ ] Stage: Hub → Spoke peering = Connected
  - [ ] Prod: Hub → Spoke peering = Connected
- [ ] Verify private DNS zone links created

## Phase 6: Application Deployment 🔲 NOT STARTED

### React App Deployment

- [ ] Build React application: `npm run build`
- [ ] Upload to Dev storage account static website
  ```bash
  az storage blob upload-batch \
    -d '$web' \
    -s ./build \
    --account-name strffreactdev
  ```
- [ ] Verify Dev application accessible at primary web endpoint
- [ ] Deploy to Stage environment
- [ ] Verify Stage application
- [ ] Deploy to Prod environment (requires approval)
- [ ] Verify Prod application

### Application Insights Configuration

- [ ] Get instrumentation key from each environment
- [ ] Add instrumentation key to React app configuration
- [ ] Verify telemetry flowing to Application Insights
- [ ] Set up custom alerts for errors/performance

## Phase 7: Monitoring & Observability 🔲 NOT STARTED

- [ ] Configure Application Insights alerts:
  - [ ] Failed request rate > 5%
  - [ ] Response time > 3 seconds
  - [ ] Availability < 99%
- [ ] Configure budget alerts:
  - [ ] Alert at 80% of monthly budget
  - [ ] Alert at 100% of monthly budget
- [ ] Set up Azure Monitor dashboards
- [ ] Configure Log Analytics queries for troubleshooting

## Phase 8: Documentation & Handoff 🔲 NOT STARTED

- [x] Created INTEGRATION_MANIFEST.md with all details
- [ ] Updated INTEGRATION_MANIFEST.md with actual subscription IDs
- [ ] Updated INTEGRATION_MANIFEST.md with service principal details
- [ ] Updated INTEGRATION_MANIFEST.md with VNet IDs
- [ ] Created deployment runbook for app team
- [ ] Shared GitHub repository access with app team
- [ ] Shared Azure portal access for monitoring
- [ ] Conducted knowledge transfer session
- [ ] Provided support contacts and escalation paths

## Phase 9: Validation & Testing 🔲 NOT STARTED

- [ ] Verify RBAC assignments working correctly
- [ ] Test application deployment pipeline
- [ ] Test infrastructure updates via pull request
- [ ] Verify automated terraform plan on PR
- [ ] Verify automated terraform apply on merge to main
- [ ] Test rollback procedure
- [ ] Verify monitoring alerts working
- [ ] Test disaster recovery procedure

## Phase 10: Production Readiness 🔲 NOT STARTED

- [ ] Security review completed
- [ ] Cost optimization review completed
- [ ] Backup and disaster recovery plan documented
- [ ] Incident response plan documented
- [ ] On-call rotation established
- [ ] Production deployment approval process defined
- [ ] Post-deployment health checks automated

---

## Notes & Issues

**Progress Notes:**
- ✅ Infrastructure repository structure created
- ✅ CI/CD pipeline configured
- ✅ Integration manifest documented
- ⏳ Waiting for subscription creation via subscription factory
- ⏳ Service principal creation pending
- ⏳ GitHub secrets configuration pending

**Blockers:**
- None currently

**Decisions:**
- Using Storage Account static website hosting for React app (cost-effective)
- Using GitHub OIDC for authentication (no secret rotation needed)
- Using zone-redundant storage for production
- Key Vault network ACLs open in dev/stage, restricted in prod

---

**Last Updated:** {{ date }}
**Updated By:** Platform Team
