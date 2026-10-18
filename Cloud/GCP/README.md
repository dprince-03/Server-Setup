# Google Cloud (GCP) Guide

| # | Chapter | Covers |
|---|---|---|
| 01 | [Organization foundation](01-org-foundation.md) | resource hierarchy, Cloud Identity, IAM, org policies, billing, audit logs |
| 02 | [Networking](02-networking.md) | global VPCs, Shared VPC, Cloud NAT, Private Google Access/PSC, Cloud Load Balancing, Cloud Armor |
| 03 | [Compute and app patterns](03-compute-app-patterns.md) | Cloud Run (services/jobs/functions), GKE Autopilot, Compute Engine, App Engine, Firebase |
| 04 | [Data, analytics and AI](04-data-analytics-ai.md) | Cloud Storage, Cloud SQL, AlloyDB, Spanner, Firestore, BigQuery, Pub/Sub, Vertex AI |
| 05 | [Security and operations](05-security-operations.md) | Security Command Center, Secret Manager, KMS, Cloud Logging/Monitoring, backups |
| 06 | [Tools, CLI and IaC](06-tools-cli-iac.md) | gcloud, Terraform, Infrastructure Manager, using the starter files |

**Files** (`files/`):

| Path | What |
|---|---|
| `terraform/cloud-run-app/` | APIs, Artifact Registry, runtime service account, a Secret Manager secret (container only: **you add the value**), Cloud Run service, Workload Identity Federation for GitHub |
| `org-policy/*.yaml` | baseline organization policies (no SA keys, location restriction, no external VM IPs, domain-restricted sharing, uniform bucket access) |
| `github-actions/deploy-cloud-run.yml` | build → Artifact Registry → deploy to Cloud Run via WIF |
