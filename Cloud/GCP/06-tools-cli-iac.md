# GCP 06 — Tools, CLI and IaC (and using the starter files)

## Tools

| Tool | Use |
|---|---|
| `gcloud` (Google Cloud CLI) | `gcloud init`, `gcloud auth login`, `gcloud auth application-default login` (local ADC for Terraform/SDKs) |
| `bq`, `gsutil`/`gcloud storage` | BigQuery and Storage CLIs (bundled) |
| Cloud Shell | a browser shell with tools and credentials |
| Terraform / OpenTofu (google + google-beta providers) | IaC; state in a GCS bucket |
| Infrastructure Manager | Google-managed Terraform runs |
| Config Connector | GCP resources as Kubernetes CRDs (GitOps) |
| Skaffold / Cloud Code | local dev loops for Cloud Run/GKE |

State bucket (once per org/bootstrap project):
```bash
gcloud storage buckets create gs://tfstate-<org>-<suffix> --location=EU --uniform-bucket-level-access --public-access-prevention
gcloud storage buckets update gs://tfstate-<org>-<suffix> --versioning
```

## Using the starter files (`files/terraform/cloud-run-app`)

```bash
cd files/terraform/cloud-run-app
gcloud auth application-default login                  # you log in. Nothing is stored in the repo
terraform init -backend-config="bucket=tfstate-<org>-<suffix>" -backend-config="prefix=myapp/dev"
terraform plan  -var="project_id=<project>" -var="region=europe-west1" -var="github_repo=your-org/your-repo"
terraform apply -var=...                               # same vars, after reviewing the plan
```
Then **add the secret value yourself** (Terraform creates only the empty secret):
```bash
gcloud secrets versions add myapp-api-key --project=<project> --data-file=-   # type it, then Ctrl-D
```
The Cloud Run service reads it via `secret_key_ref` (version `latest`). Redeploy or create a new
revision to pick up a new version.

CI: copy [`files/github-actions/deploy-cloud-run.yml`](files/github-actions/deploy-cloud-run.yml),
then set the GitHub **Variables** (not secrets) from the Terraform outputs: `GCP_WIF_PROVIDER`,
`GCP_DEPLOY_SA`, `GCP_PROJECT`, `GCP_REGION`, `GAR_REPO`, `SERVICE`.

Clean up: `terraform destroy` (set `deletion_protection = false` on the Cloud Run service first), or
delete the sandbox project.

## Learning resources
Google Cloud Skills Boost (labs), the Architecture Center, and the Cloud Foundation Fabric repo.
Certifications: Cloud Digital Leader → Associate Cloud Engineer → Professional Cloud Architect /
DevOps Engineer / Security Engineer.
