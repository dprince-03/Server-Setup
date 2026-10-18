# 02 — Landing Zones and Identity

A **landing zone** is the pre-built, governed foundation (accounts/projects/subscriptions, identity,
networking, logging, guardrails) that every workload lands in. Build it **before** the first
production app. Fixing it later is a migration project.

## Structure: isolate by environment and blast radius

| | AWS | GCP | Azure |
|---|---|---|---|
| Top container | Organization (management account) | Organization (domain) | Entra tenant → root management group |
| Grouping | Organizational Units (OUs) | Folders | Management groups |
| Isolation unit | **Account** | **Project** | **Subscription** (+ resource groups) |
| Guardrails | SCPs / RCPs, Control Tower controls | Organization Policies | Azure Policy (assigned at management group level) |
| Turnkey landing zone | **Control Tower** / Landing Zone Accelerator | Cloud Foundation Fabric / Setup checklist / Foundations blueprint | **Azure Landing Zones** (ALZ, Bicep/Terraform accelerators) |

Typical layout (the names vary by provider):
```
Org root
├── Security        → log archive (immutable audit logs), security tooling/audit
├── Infrastructure  → shared networking (hub, DNS, egress), shared services (CI runners, registry)
├── Workloads
│   ├── Prod        → app-a-prod, app-b-prod
│   ├── Staging     → app-a-stg
│   └── Dev         → app-a-dev
├── Sandbox         → per-developer playgrounds with budgets + auto-cleanup
└── Suspended       → closed accounts, where everything is denied
```
**Prod and non-prod in separate accounts/projects/subscriptions.** A dev mistake can't touch prod,
and IAM, budgets and quotas stay separate.

## Human identity (workforce)

1. **One identity provider (IdP)**: Entra ID, Google Workspace/Cloud Identity, Okta, or JumpCloud.
   Every cloud trusts it via SSO (SAML/OIDC).
2. **MFA everywhere**, phishing-resistant (passkeys/FIDO2 keys) for admins.
3. Access goes through **groups → roles/permission sets**, never per-user policies.
4. **No IAM users with passwords or access keys** for humans (AWS). Use IAM Identity Center and
   `aws sso login`.
5. **Root / global admin accounts:** hardware MFA, no access keys, used only for break-glass. Keep
   two **break-glass** accounts with alerts on every use.
6. **Just-in-time elevation** for admin roles (Entra PIM, AWS TEAM / temporary elevated access,
   GCP PAM). Standing admin access is a risk.
7. Quarterly **access reviews**. Off-boarding is removing the person in the IdP, and that's all.

## Workload identity (machines, CI, apps)

- Apps use **roles/managed identities/service accounts** attached to the compute (EC2 instance
  profile / ECS task role / Lambda role; GCP service account on Cloud Run/GKE Workload Identity;
  Azure managed identity). **No keys in code, environment files or images.**
- CI/CD (GitHub Actions, GitLab) uses **OIDC federation**: short-lived tokens scoped to a repo/branch/
  environment. Templates are in each platform's `files/`.
- GCP: block service-account key creation by org policy. Azure: prefer managed identity over
  app secrets. AWS: alert on any new IAM access key.

## Least privilege in practice

- Start from managed job-function roles, then tighten with access analysers (IAM Access Analyzer,
  GCP IAM Recommender, Entra/Defender recommendations).
- Use conditions (tags, source VPC, MFA present, time).
- Separate **deploy** permissions (CI) from **runtime** permissions (app).

## Baseline guardrails (enable on day 1)

- Deny disabling audit logging, security services and the log archive.
- Deny leaving the organisation. Restrict regions to the ones you use.
- Deny public storage buckets (S3 Block Public Access at the org level, GCP
  `storage.publicAccessPrevention`, Azure Policy against public blob access).
- Require encryption and tags. Deny external IPs on VMs unless they're approved.
- Org-wide audit trail → the log-archive account/project, with retention and object lock.
- **Budgets + anomaly alerts** on every account/project/subscription.

## Exercises
1. Draw your org structure for a startup with 2 products and 3 environments.
2. Set up SSO from your IdP into one cloud and remove every long-lived credential.
3. Write one guardrail as code (SCP / org policy / Azure Policy) and prove it blocks a test action.
