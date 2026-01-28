# Security Best Practices & State Access Control

## Overview

This document outlines security best practices for managing Terraform state and infrastructure access in the IAC pipeline, with a focus on protecting sensitive data and implementing proper access controls.

---

## 1. State File Security

### Why State Files Are Sensitive

Terraform state files contain sensitive information:
- Database passwords and connection strings
- API keys and authentication tokens
- Resource IDs and configuration details
- SSH keys and certificates
- Service principal credentials
- Any secrets referenced in infrastructure

**Risk**: Direct exposure to application teams increases the attack surface and violates principle of least privilege.

### Current Setup

- **Storage Location**: Azure Storage Account (`tfstatelzqiaypb`)
- **Resource Group**: `rg-tfstate`
- **Container**: `tfstate`
- **Encryption**: Azure managed encryption at rest

---

## 2. Access Control Model (Recommended)

### Team Roles & Responsibilities

| Role | Responsibility | State Access | Notes |
|------|-----------------|--------------|-------|
| **Security Team** | Manages encryption, audit, compliance | Full with MFA+PIM | Approves state access requests |
| **cloud/DevOps Team** | Deploys infrastructure, manages state | Via PIM (time-limited) | Requires Security approval |
| **Application Team** | Consumes infrastructure outputs | Read-only configs only | NO direct state access |
| **SRE Team** | Incident response, emergency access | Via PIM with expedited approval | Audit trail required |

### Principle of Least Privilege

- Application teams get **only what they need** (outputs, connection strings, endpoints)
- State file access is **restricted to infrastructure teams**
- All state access is **logged and audited**
- Access is **time-limited and revocable**

---

## 3. Recommended Implementation: Azure PIM + MFA

### Overview

**Azure Privileged Identity Management (PIM)** enables:
- Just-in-time (JIT) access to sensitive resources
- Dual approval workflows (Security + cloud teams)
- Multi-factor authentication (MFA) requirement
- Time-limited access (auto-revoke after X hours)
- Complete audit trail

### Architecture

```
cloud Team Request
         ↓
    [PIM Request]
         ↓
Security Team Reviews + Approves (with MFA)
         ↓
cloud Team Authenticates (with MFA)
         ↓
Access Granted for [Duration] (e.g., 2 hours)
         ↓
Auto-Revoke After Expiration
```

### Setup Steps

#### Step 1: Enable PIM on Storage Account

```bash
# Prerequisites
# - Azure subscription with PIM license (Premium P2)
# - Security team member with Global Admin role

# In Azure Portal:
# 1. Go to "Storage Account" → "rg-tfstate/tfstatelzqiaypb"
# 2. Search for "Privileged Identity Management"
# 3. Configure PIM for role: "Storage Account Contributor"
```

#### Step 2: Create PIM Role Assignment

**Role**: Storage Account Contributor (or custom scoped role)

**Eligible Members**:
- cloud/DevOps team lead
- Infrastructure engineer

**Approval Settings**:
- Require approval: ✓ YES
- Approvers: Security team members (2-3 people)
- MFA on activation: ✓ REQUIRED
- Maximum activation duration: 2 hours
- Require justification: ✓ YES

#### Step 3: Configure Conditional Access (Azure AD)

```json
{
  "displayName": "Require MFA for State Storage Access",
  "conditions": {
    "applications": {
      "includeApplications": ["Azure Storage"]
    },
    "users": {
      "includeRoles": ["Storage Account Contributor"]
    },
    "locations": {
      "excludeLocations": ["Internal corporate network"]
    }
  },
  "grantControls": {
    "builtInControls": ["mfa"]
  }
}
```

#### Step 4: Enable Storage Account Logging

```bash
# Enable audit logging for all access
az storage account logging update \
  --account-name tfstatelzqiaypb \
  --account-key <key> \
  --services b \
  --log rwd \
  --retention 90

# Enable Azure Monitor alerts
# Navigate to: Storage Account → Diagnostics → Logs
# - Enable: All logs
# - Export to: Log Analytics Workspace
```

---

## 4. Workflow for Accessing State

### For cloud/DevOps Team

1. **Request Access via PIM**
   ```
   Azure Portal → PIM → My Roles → Activate Role
   Select: "Storage Account Contributor"
   Duration: 2 hours
   Justification: "Need to review state for incident response"
   ```

2. **Security Team Approves**
   - Receives notification
   - Reviews justification
   - Approves with MFA

3. **cloud Team Authenticates**
   - Completes MFA challenge
   - Access granted for 2 hours

4. **Access State**
   ```bash
   # Only available during activated time window
   terraform state list
   terraform state show <resource>
   az storage blob download --account-name tfstatelzqiaypb --container-name tfstate --name app1/dev.tfstate
   ```

5. **Auto-Revoke**
   - Access automatically expires after 2 hours
   - Manual revoke available before expiration

### For Application Team (Approved Output Distribution)

1. **Receive Outputs Only**
   ```
   cloud team exports state outputs to secure location:
   - Database connection string
   - API endpoints
   - Service IPs
   ```

2. **Via Secret Management (Recommended)**
   ```bash
   # cloud team stores outputs in Azure Key Vault
   # Application team accesses via managed identity
   
   az keyvault secret get --vault-name app1-kv --name db-connection-string
   ```

3. **No Direct State Access**
   - Application team cannot read `*.tfstate` files
   - Cannot modify infrastructure
   - Cannot approve/decline PIM requests

---

## 5. Audit & Monitoring

### Access Audit Trail

All state access is logged to Azure Monitor:

```kusto
// Query: Who accessed state files in last 24 hours
StorageBlobLogs
| where TimeGenerated > ago(24h)
| where ContainerName == "tfstate"
| project TimeGenerated, CallerIpAddress, UserObjectId, OperationName, ResourceUri
| sort by TimeGenerated desc
```

### Alert on Suspicious Activity

Set up alerts for:
- ✓ Unauthorized access attempts
- ✓ State modification outside of CI/CD pipeline
- ✓ Access from unusual IP addresses
- ✓ Failed MFA attempts
- ✓ PIM approval rejections

```bash
# Example: Alert if state is accessed outside business hours
# Configure in: Storage Account → Alerts → Create Alert Rule
```

### Compliance Reporting

Generate monthly reports:
- Who accessed state and when
- PIM approvals and rejections
- Any security incidents or anomalies
- Policy violations

---

## 6. Emergency Access (Break Glass)

### Scenario
Security/cloud incident requires immediate state access without normal approval workflow.

### Procedure

1. **Declare Emergency** (requires 2+ team leads)
   ```
   Notify: Security Lead + DevOps Lead + CTO
   State: "Production incident - emergency state access needed"
   ```

2. **Enable Break Glass Access**
   ```bash
   # One-time elevated access granted by Azure Admin
   # Bypasses normal PIM workflow
   # REQUIRES secondary approval from Security Lead
   ```

3. **Document Everything**
   - Who accessed state
   - When
   - What was done
   - Why it was emergency
   - Post-incident review

4. **Post-Incident**
   - Review incident log
   - Adjust policies if needed
   - Update team on findings

---

## 7. Best Practices Checklist

### Access Control
- [ ] State storage configured in separate resource group
- [ ] PIM roles defined for infrastructure teams only
- [ ] Application teams have NO direct state access
- [ ] MFA required for all state access
- [ ] Time-limited access (max 2 hours per session)

### Encryption & Security
- [ ] Azure Managed encryption at rest ✓
- [ ] TLS 1.2+ for transit
- [ ] Consider customer-managed keys for sensitive environments
- [ ] Firewall rules: Restrict state storage to corporate IPs only

### Audit & Monitoring
- [ ] Azure Monitor logging enabled
- [ ] Log retention: 90+ days
- [ ] Alerts configured for suspicious activity
- [ ] Monthly audit reports generated
- [ ] State access reviewed in security meetings

### Secrets Management
- [ ] Secrets NOT stored in state (use Azure Key Vault)
- [ ] Terraform sensitive outputs marked with `sensitive = true`
- [ ] Application teams use managed identities (not keys in state)
- [ ] Rotate secrets regularly

### CI/CD Pipeline
- [ ] Only CI/CD service principal can modify state
- [ ] Manual approvals required for apply (humans review)
- [ ] Automated destroy for POC environments (cost control)
- [ ] Pipeline has audit trail in GitHub Actions logs

---

## 8. Implementation Timeline

| Phase | Timeline | Owner | Actions |
|-------|----------|-------|---------|
| **Phase 1: Quick Wins** | Week 1 | Security | Enable Azure Monitor logging, set up alerts |
| **Phase 2: PIM Setup** | Week 2-3 | Azure Admin | Configure PIM roles, test workflows |
| **Phase 3: Training** | Week 3 | DevOps | Train teams on new access model |
| **Phase 4: Enforcement** | Week 4 | Security | Enable conditional access policies, enforce MFA |
| **Phase 5: Compliance** | Ongoing | Security | Monthly audit reports, policy reviews |

---

## 9. References & Documentation

- [Azure PIM Documentation](https://learn.microsoft.com/en-us/azure/active-directory/privileged-identity-management/)
- [Terraform State Security](https://www.terraform.io/docs/state/sensitive-data)
- [Azure Storage Security](https://learn.microsoft.com/en-us/azure/storage/blobs/security-recommendations)
- [Azure Conditional Access](https://learn.microsoft.com/en-us/azure/active-directory/conditional-access/)
- [Principle of Least Privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)

---

## 10. Questions & Escalation

**Q: What if a team member leaves?**
A: PIM roles are automatically revoked. Remove from Azure AD group and review Azure RBAC assignments.

**Q: Can we share state access with contractors?**
A: Yes, via temporary PIM role (e.g., 2 weeks). Requires Security + DevOps approval. Full audit trail.

**Q: What about disaster recovery?**
A: Security + DevOps lead can trigger break-glass access. Full incident review required afterward.

**Q: How do we handle environment promotion (dev → prod)?**
A: Same PIM workflow. Prod access requires additional approval from CTO/Security Director.

---

## Approval & Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Security Lead | | | |
| cloud Lead | | | |
| CTO | | | |

---

**Document Version**: 1.0  
**Last Updated**: January 18, 2026  
**Next Review**: Quarterly
