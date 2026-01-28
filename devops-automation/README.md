# DevOps Automation

Purpose: automate app onboarding tasks (repo creation, Azure identity, OIDC, RBAC) for the org `seera-eswara`.

## Workflow: bootstrap-app-repo.yml

Runs manually to create a new app infra repo and wire Azure identity.

Inputs (workflow_dispatch):
- `app_code` (required)
- `environment` (default `dev`)
- `subscription_id` (required)
- `repo_name` (required) — will be created under the org
- `github_org` (default `seera-eswara`)
- `template_repo` (default `seera-eswara/app-infra-template`)
- `branch` (default `main`)
- `role_definition` (default `Contributor`)

What it does:
1) Creates a new repo from `template_repo` in the org.
2) Creates Azure AD app registration + service principal.
3) Adds GitHub OIDC federated credential for the repo/branch.
4) Assigns role to the SPN at the target subscription.
5) Writes GitHub secrets: `ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`, `ARM_USE_OIDC`.

Required secrets (in devops-automation repo):
- `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` — admin SPN with rights to create app regs and role assignments.
- `BOOTSTRAP_PAT` — PAT with `repo` and `admin:repo_hook` scope to create repos and set secrets.

Usage:
- Trigger `Bootstrap App Repo` workflow in the `Actions` tab.
- Provide inputs (app_code, subscription_id, repo_name). The workflow prints created IDs in the summary.

Notes:
- Repo is created as private. Adjust in workflow if you need public.
- Role default is Contributor; change input if needed (e.g., Owner for break-glass scenarios).
- Federated credential subject: `repo:<org>/<repo>:ref:refs/heads/<branch>`.
