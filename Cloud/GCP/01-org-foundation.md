# GCP 01 — Organization Foundation

## Resource hierarchy

```
Organization (example.com)          ← created from Cloud Identity / Google Workspace
├── Folder: bootstrap / common      → seed project (Terraform state + CI), logging project, security project
├── Folder: networking              → host projects for Shared VPC (prod / non-prod)
├── Folder: production              → app-a-prod, app-b-prod
├── Folder: non-production          → app-a-stg, app-a-dev
└── Folder: sandbox                 → personal projects with budgets
```
IAM and org policies **inherit downward**: grant at the folder level for teams, and at the
project level for specific apps.
Google's **setup checklist** (Console → "Google Cloud setup") and the Terraform-based **Cloud
Foundation Fabric** / enterprise foundations blueprint build this for you.

## Step-by-step

1. **Cloud Identity Free** (or Workspace) for your domain → the organization resource appears.
   Enforce 2-step verification (security keys for admins).
2. **Super admin:** two break-glass accounts, used for nothing else. Daily admins get
   `roles/resourcemanager.organizationAdmin` through a **group**.
3. **Groups** (`gcp-org-admins@`, `gcp-billing-admins@`, `gcp-network-admins@`, `gcp-security-admins@`,
   `gcp-devops@`, `gcp-developers@`). Grant roles to groups only.
4. **Billing account:** link projects, and set **budgets with alerts** per project (Cloud ch. 07).
   Export billing to BigQuery.
5. **Org policies** from [`files/org-policy/`](files/org-policy):
   ```bash
   for f in files/org-policy/*.yaml; do sed "s/ORG_ID/<your-org-id>/" "$f" > /tmp/p.yaml && gcloud org-policies set-policy /tmp/p.yaml; done
   ```
   Recent organizations get several secure-by-default policies automatically (e.g. no SA key
   creation, uniform bucket-level access). Check yours with `gcloud org-policies list --organization=<ID>`.
6. **Centralised logging:** an aggregated **log sink** at the org level → a log bucket in the
   logging project (locked retention). Enable **Data Access audit logs** for sensitive services.
7. **Security Command Center** at the org level (Standard is free; Premium/Enterprise add threat
   detection and compliance).

## IAM best practices on GCP

- Use **predefined roles**, never the primitive Owner/Editor/Viewer in prod.
- **No service-account keys.** Use attached service accounts on Cloud Run/GKE/GCE, Workload
  Identity Federation for CI and other clouds, and impersonation for humans
  (`gcloud --impersonate-service-account=...`).
- One **dedicated service account per workload**, never the default compute SA. Recent orgs block
  automatic Editor grants to the default SAs. Make sure yours do too
  (`iam.automaticIamGrantsForDefaultServiceAccounts`).
- Use IAM Conditions and Privileged Access Manager (PAM) for just-in-time elevation.
- Use IAM Recommender to remove unused permissions.

## Checklist
- [ ] Organization exists; 2SV enforced; break-glass super admins
- [ ] Folders per environment; groups mapped to roles
- [ ] Org policies applied; budgets per project; billing export
- [ ] Org log sink → locked log bucket; Data Access logs where needed
- [ ] SCC enabled; no SA keys anywhere
