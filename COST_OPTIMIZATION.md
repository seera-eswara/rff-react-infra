# Azure Cost Optimization Guide for Learning/Testing

## 💰 Monthly Cost Breakdown

### 🔴 **EXPENSIVE - Disable for Learning**

| Resource | Monthly Cost | Annual Cost | Status |
|----------|--------------|-------------|--------|
| **DDoS Protection Plan** | ~$2,944 | ~$35,328 | ❌ DISABLED |
| **Azure Firewall Premium** | ~$900 | ~$10,800 | ❌ DISABLED |
| **Azure Firewall Standard** | ~$800 | ~$9,600 | ❌ DISABLED |
| **Azure Bastion Standard** | ~$140 | ~$1,680 | ❌ DISABLED |
| **TOTAL IF ALL ENABLED** | **~$4,784** | **~$57,408** | ⚠️ AVOID |

### 🟡 **MODERATE - Use Wisely**

| Resource | Monthly Cost | Notes |
|----------|--------------|-------|
| Azure Firewall Basic | ~$150 | If you need firewall for learning |
| VNet Peerings | ~$10-50 | Based on data transfer |
| Public IPs | ~$3 each | Only if needed |
| Storage for state | ~$1-5 | Very cheap, keep it |

### 🟢 **CHEAP/FREE - Safe to Use**

| Resource | Monthly Cost | Notes |
|----------|--------------|-------|
| VNets | FREE | No charge for VNet itself |
| Subnets | FREE | No charge |
| NSGs | FREE | No charge for NSG rules |
| Route Tables | FREE | No charge |
| Private DNS Zones | ~$0.50 each | Very cheap, OK to use |
| Log Analytics | FREE (5GB/month) | Stay under 5GB ingestion |
| Resource Groups | FREE | No charge |

---

## 📊 Recommended Configuration for Learning ($0 - $20/month)

### **Minimal Setup (Nearly Free)**
```hcl
# terraform.tfvars
enable_firewall         = false   # Save $900/month
enable_bastion          = false   # Save $140/month
enable_ddos_protection  = false   # Save $2,944/month

# Result: $0-5/month (just storage + minimal data transfer)
```

**What you still get:**
- ✅ Hub-spoke VNet topology
- ✅ Subnets and NSGs
- ✅ Route tables (manual routes)
- ✅ Private DNS zones
- ✅ Log Analytics (free tier)
- ✅ Full Terraform structure

**What you lose:**
- ❌ No centralized firewall filtering
- ❌ No Bastion (use Azure CLI/Portal instead)
- ❌ No DDoS protection (not needed for testing)

### **If You Need Firewall (~$150/month)**
```hcl
enable_firewall    = true
firewall_sku_tier  = "Basic"  # NOT Premium

# Result: ~$150/month
```

---

## 🎓 Learning Path by Budget

### **$0 Budget - Maximum Learning, Zero Cost**

**Deploy:**
1. ✅ Management Groups (free)
2. ✅ Hub VNet (free)
3. ✅ One spoke VNet (free)
4. ✅ NSGs with rules (free)
5. ✅ Route tables (free)
6. ✅ Private DNS zones - 2-3 only ($1-2/month)
7. ✅ Log Analytics workspace (free tier)

**Skip:**
- ❌ Azure Firewall
- ❌ Azure Bastion
- ❌ DDoS Protection
- ❌ VPN Gateway

**Duration:** Can run indefinitely on free tier!

**Use Cases:**
- Learn Terraform syntax
- Understand hub-spoke topology
- Practice IaC workflows
- Test CI/CD pipelines

---

### **$50 Budget - Add Firewall Basic**

**Deploy everything above PLUS:**
- ✅ Azure Firewall Basic (~$150/month)

**Run for:** ~10 days then destroy, or ~1 month if needed

**What you learn:**
- Centralized traffic filtering
- Firewall policies and rules
- Network diagnostics

---

### **$200 Budget - Full Learning Experience**

**Option A: Run full stack for 1 week**
- Everything enabled
- Learn enterprise patterns
- **Destroy after 1 week!**

**Option B: Run minimal for 3+ months**
- Firewall Basic only
- Learn over time
- More sustainable

---

## 🛡️ Cost Protection Strategies

### 1. **Use Azure Cost Alerts**

```bash
# Set budget alerts at $10, $50, $100
az consumption budget create \
  --budget-name "learning-budget" \
  --amount 100 \
  --time-grain Monthly
```

### 2. **Auto-Shutdown Schedule**

Create a script to destroy expensive resources nightly:

```bash
# shutdown.sh
#!/bin/bash
# Run this daily at 6 PM to stop expensive resources

# Disable firewall
az network firewall delete --name afw-hub-dev --resource-group rg-network-hub-dev

# Takes 5 minutes, saves $5/night if not needed
```

### 3. **Use Dev/Test Pricing**

Some resources offer dev/test pricing:
```bash
az account set --subscription "Pay-As-You-Go Dev/Test"
```

### 4. **Resource Locks**

Prevent accidental deployment of expensive resources:

```hcl
# Add to terraform code
resource "azurerm_management_lock" "prevent_firewall" {
  name       = "no-expensive-resources"
  scope      = azurerm_resource_group.network.id
  lock_level = "CanNotDelete"
  notes      = "Prevent accidental costly deployments"
}
```

### 5. **Terraform Cost Estimation**

Use Infracost before applying:

```bash
# Install infracost
brew install infracost  # or download from infracost.io

# Get cost estimate BEFORE applying
infracost breakdown --path .

# Output shows:
# Azure Firewall Premium: $900/mo ⚠️
# You can cancel before running terraform apply
```

---

## 📅 Recommended Timeline for $200 Credit

### **Month 1-2: Free Resources Only ($0)**
- Deploy management groups
- Deploy hub-spoke VNets
- Test NSGs, route tables
- Learn Terraform basics
- Practice CI/CD

### **Month 3: Firewall Basic ($150)**
- Enable firewall for 1 month
- Learn firewall rules
- Test traffic filtering
- Then disable/destroy

### **Month 4-6: Subscription Factory ($5-20/month)**
- Test subscription vending
- Minimal resource deployment
- Focus on automation workflows

### **Total Spent: ~$170 over 6 months** ✅

---

## 🚨 What to NEVER Enable for Learning

| Resource | Monthly Cost | Why Avoid |
|----------|--------------|-----------|
| Azure Firewall Premium | $900 | Basic or disabled is fine |
| DDoS Protection | $2,944 | Not needed for learning at all |
| VPN Gateway | $140+ | Use Bastion or Portal access |
| ExpressRoute | $1,000+ | Enterprise-only, not for learning |
| Application Gateway | $150+ | Use Static Web Apps instead |

---

## ✅ Modified Defaults in This Repo

I've changed the default values to be cost-optimized:

```hcl
# OLD (Enterprise Production)
enable_firewall         = true   # $900/month
enable_bastion          = true   # $140/month
enable_ddos_protection  = true   # $2,944/month
firewall_sku_tier       = "Premium"
log_analytics_retention = 90 days

# NEW (Learning/Testing)
enable_firewall         = false  # $0/month
enable_bastion          = false  # $0/month  
enable_ddos_protection  = false  # $0/month
firewall_sku_tier       = "Basic"  # $150/month if enabled
log_analytics_retention = 30 days  # Free tier
```

**You can now safely run `terraform apply` without surprise charges!**

---

## 🎯 Quick Start for $0 Learning

```bash
cd terraform-azure-landingzone

# Copy the learning config
cp terraform.tfvars.example-learning terraform.tfvars

# Review costs (should be $0-2/month)
infracost breakdown --path .

# Deploy safely
terraform init
terraform plan   # Review - should show NO expensive resources
terraform apply  # Safe to apply!

# Learn and experiment...

# When done (or reaching credit limit)
terraform destroy  # Remove everything
```

---

## 📞 Getting Help

- **Azure Pricing Calculator**: https://azure.microsoft.com/pricing/calculator/
- **Check Current Costs**: Azure Portal → Cost Management
- **Free Tier Limits**: https://azure.microsoft.com/free/
- **Student Credits**: Get $100/year with Azure for Students

**Remember:** You can always add enterprise features later in a real job. Focus on learning the patterns and workflows first!
