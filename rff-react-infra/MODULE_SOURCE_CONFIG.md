# Module Source Configuration Guide

## 📦 Module Source Strategy

All modules should be sourced from the **centralized GitHub repository** with version pinning for stability and reproducibility.

---

## 🎯 Source Format

### Production (Recommended)
```hcl
module "example" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/category/module-name?ref=v1.0.0"
  # ... configuration
}
```

### Alternative GitHub Format
```hcl
module "example" {
  source = "github.com/your-org/terraform-azure-modules//modules/category/module-name?ref=v1.0.0"
  # ... configuration
}
```

---

## 🔐 Authentication

### SSH (Recommended for CI/CD)
```hcl
source = "git::git@github.com:your-org/terraform-azure-modules.git//modules/category/module-name?ref=v1.0.0"
```

**Setup:**
```bash
# GitHub Actions
- uses: webfactory/ssh-agent@v0.5.4
  with:
    ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}

# Azure DevOps
# Use SSH service connection
```

### HTTPS with Token
```hcl
source = "git::https://oauth2:${var.github_token}@github.com/your-org/terraform-azure-modules.git//modules/category/module-name?ref=v1.0.0"
```

**Setup:**
```bash
# Set in environment or tfvars
export TF_VAR_github_token="ghp_xxxxxxxxxxxx"
```

---

## 📌 Version Pinning Strategies

### 1. Semantic Versioning (Recommended)
```hcl
# Specific version (most stable)
source = "...?ref=v1.0.0"

# Minor version updates (bug fixes only)
source = "...?ref=v1.0"

# Major version (patch + minor updates)
source = "...?ref=v1"
```

### 2. Branch References
```hcl
# Development branch (not recommended for production)
source = "...?ref=main"

# Feature branch (testing only)
source = "...?ref=feature/new-capability"
```

### 3. Commit SHA (Maximum stability)
```hcl
# Specific commit (immutable)
source = "...?ref=abc123def456"
```

---

## 🏗️ Module Repository Structure

```
terraform-azure-modules/
├── modules/
│   ├── compute/
│   │   ├── app_service/
│   │   ├── aks_cluster/
│   │   └── ...
│   ├── data/
│   │   ├── storage_account/
│   │   ├── keyvault/
│   │   └── ...
│   ├── networking/
│   │   ├── vnet/
│   │   ├── nsg/
│   │   └── ...
│   ├── monitoring/
│   │   ├── log_analytics_workspace/
│   │   ├── application_insights/
│   │   └── ...
│   ├── security/
│   │   └── ...
│   └── utility/
│       ├── tags/
│       ├── resource_group/
│       └── ...
├── CHANGELOG.md
├── README.md
└── VERSION
```

---

## 🔄 Version Management

### Tagging Strategy

```bash
# Create new version tag
git tag -a v1.0.0 -m "Initial stable release"
git push origin v1.0.0

# List all tags
git tag -l

# Delete tag (if needed)
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

### CHANGELOG.md Format
```markdown
# Changelog

## [1.0.0] - 2026-01-29
### Added
- Initial module library with 31 modules
- Compute: app_service, aks_cluster, vm_linux, vm_windows
- Data: storage_account, keyvault, sql_server
- Networking: vnet, nsg, private_endpoint
- Monitoring: log_analytics_workspace, application_insights
- Utility: tags, resource_group, acr

### Security
- All modules include diagnostic settings
- RBAC enabled by default on Key Vault
- Network isolation for production environments
```

---

## 🚀 CI/CD Integration

### GitHub Actions Example

```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout App Code
      uses: actions/checkout@v3
    
    # No need to checkout module repo - Terraform handles it!
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.6.6
    
    - name: Configure Git for Module Access
      run: |
        git config --global url."https://${{ secrets.GH_TOKEN }}@github.com/".insteadOf "https://github.com/"
    
    - name: Terraform Init
      run: terraform init
      working-directory: ./envs/dev
    
    - name: Terraform Plan
      run: terraform plan -var-file=dev.tfvars
      working-directory: ./envs/dev
    
    - name: Terraform Apply
      run: terraform apply -auto-approve -var-file=dev.tfvars
      working-directory: ./envs/dev
```

---

## 📋 Module Source Checklist

For each module reference in your infrastructure code:

- [ ] Use full GitHub URL (not relative path)
- [ ] Include `?ref=` version tag
- [ ] Use semantic versioning (v1.0.0)
- [ ] Configure authentication (SSH or token)
- [ ] Test `terraform init` downloads modules correctly
- [ ] Document required module versions in README
- [ ] Pin to stable versions in production
- [ ] Use latest versions in dev/test

---

## 🔍 Troubleshooting

### Issue: "Module not found"
```bash
# Clear module cache
rm -rf .terraform/modules

# Re-initialize
terraform init -upgrade
```

### Issue: "Authentication failed"
```bash
# For HTTPS - set token
export TF_VAR_github_token="your_token"

# For SSH - verify key
ssh -T git@github.com

# Configure Git credentials
git config --global credential.helper store
```

### Issue: "Module version conflict"
```bash
# Force module update
terraform init -upgrade

# Lock specific version
terraform init -upgrade=false
```

---

## 📚 Example Configurations

### Development Environment
```hcl
# Use latest minor version for dev (get bug fixes)
module "storage" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/data/storage_account?ref=v1"
  # ...
}
```

### Production Environment
```hcl
# Pin exact version for production (maximum stability)
module "storage" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/data/storage_account?ref=v1.0.0"
  # ...
}
```

### Testing New Module Version
```hcl
# Test specific branch before releasing
module "storage" {
  source = "git::https://github.com/your-org/terraform-azure-modules.git//modules/data/storage_account?ref=feature/enhanced-firewall"
  # ...
}
```

---

## 🎯 Best Practices

1. **Always version pin** in production (`?ref=v1.0.0`)
2. **Use SSH for CI/CD** pipelines (more secure)
3. **Tag every release** with semantic versioning
4. **Maintain CHANGELOG.md** for all module updates
5. **Test upgrades** in dev before production
6. **Document breaking changes** in release notes
7. **Keep module versions** consistent across environments
8. **Use Terraform lock file** (`.terraform.lock.hcl`) to ensure consistency

---

## 📖 Related Documentation

- [Terraform Module Sources](https://www.terraform.io/language/modules/sources)
- [Semantic Versioning](https://semver.org/)
- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

---

**Updated:** January 29, 2026  
**Current Version:** v1.0.0  
**Repository:** https://github.com/your-org/terraform-azure-modules
