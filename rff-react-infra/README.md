# RFF React Infrastructure

Infrastructure as Code for RFF React application using Terraform and Azure.

## Overview

This repository manages the Azure infrastructure for the RFF React application across multiple environments (dev, stage, prod).

## Structure

```
rff-react-infra/
├── envs/
│   ├── dev/          # Development environment
│   ├── stage/        # Staging environment
│   └── prod/         # Production environment
└── .github/
    └── workflows/    # CI/CD pipelines
```

## Prerequisites

- Azure CLI
- Terraform >= 1.6.6
- GitHub OIDC authentication configured

## Subscription Details

| Environment | Subscription Name | App Code | Management Group |
|-------------|------------------|----------|------------------|
| Dev | rff-react-dev | rff | mg-rff |
| Stage | rff-react-stage | rff | mg-rff |
| Prod | rff-react-prod | rff | mg-rff |

## Usage

### Local Development

```bash
# Navigate to environment
cd envs/dev

# Initialize Terraform
terraform init

# Plan changes
terraform plan -var-file=dev.tfvars

# Apply changes
terraform apply -var-file=dev.tfvars
```

### CI/CD

All infrastructure changes are automated via GitHub Actions:
- **Pull Requests**: Runs `terraform plan` and posts results as PR comment
- **Merge to main**: Automatically runs `terraform apply` for the respective environment

## Networking

Each environment has a spoke VNet that peers with the central hub:

| Environment | VNet CIDR | App Subnet | Data Subnet |
|-------------|-----------|------------|-------------|
| Dev | 10.10.0.0/16 | 10.10.1.0/24 | 10.10.2.0/24 |
| Stage | 10.11.0.0/16 | 10.11.1.0/24 | 10.11.2.0/24 |
| Prod | 10.12.0.0/16 | 10.12.1.0/24 | 10.12.2.0/24 |

## Resources Created

- Resource Groups
- Virtual Networks with subnets
- Network Security Groups
- Storage Accounts
- App Services / Static Web Apps
- Key Vault
- Application Insights

## Contacts

- **Owner**: Seera Eswara Rao
- **Team**: RFF-TEAM
- **Cost Center**: CC-RFF-001
