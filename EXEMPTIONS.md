# Policy Exemptions Workflow

Establishes a controlled, auditable process for temporary exceptions to Azure Policies.

## Principles
- Least privilege, time-bound, and documented.
- Dual approval (Security + cloud) via PR reviews.
- Full audit trail (who, what, why, when, scope).

## Roles
- **Requester (App Team):** Submits exemption request.
- **cloud Team:** Validates scope and technical impact.
- **Security Team:** Reviews justification and risk, approves/denies.

## Request Steps
1. Create a ticket (e.g., `SEC-12345`) with justification and business impact.
2. Open a PR in `terraform-azure-landingzone` referencing the ticket.
3. Add exemption in HCL using the module, e.g. in `management-groups/policies.tf`:

```hcl
module "policy_exemptions" {
  source = "git::https://github.com/seera-eswara/terraform-policy-as-code.git//modules/policy-exemptions?ref=v1.2.0"

  app_scopes = {
    app1 = azurerm_subscription.app1.id
  }

  exemptions = [
    {
      name                 = "app1-legacy-vm-exemption"
      display_name         = "App1 Legacy VM SKU Exception"
      description          = "App1 requires Standard_E4s_v3 for legacy DB; approved by Security."
      app_code             = "app1"  # scope resolved via app_scopes
      policy_assignment_id = module.landing_zone_policies.landingzone_policy_assignments.allowed_vm_skus
      exemption_category   = "Waiver"
      expires_on           = "2026-12-31T23:59:59Z"
      metadata = {
        requestedBy = "app1-team@company.com"
        approvedBy  = "security-team@company.com"
        ticketId    = "SEC-12345"
      }
    }
  ]
}
```

4. Include impact assessment: affected subscriptions/resources, duration, alternatives considered.
5. Request reviews from Security and cloud teams.

## Approval Rules
- Both Security and cloud teams must approve PR.
- Exemptions must have `expires_on`; 30–180 days typical.
- Only one active exemption per policy assignment and scope.
- Break-glass allowed only with incident ticket and post-mortem.

## Automation Recommendations
- CODEOWNERS require Security + cloud approval for changes to `management-groups/policies.tf`.
- GitHub Actions validate `expires_on` is in the future and `exemption_category` is valid.
- Label PRs with `policy-exemption` and capture audit metadata in release notes.

## Renewal & Revocation
- Renewal requires fresh justification and approvals.
- Revocation happens automatically on `expires_on`, or manually via PR.

## Audit
- Store exemption metadata in the Terraform state; also mirror to a centralized registry.
- Export monthly report of active exemptions for leadership review.
