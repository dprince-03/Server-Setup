# 04 — Infrastructure as Code and CI/CD

## Pick an IaC tool

| Tool | Clouds | Strengths | Watch out |
|---|---|---|---|
| **Terraform** (BSL) / **OpenTofu** (MPL, open-source fork) | all + SaaS (Cloudflare, GitHub, Datadog) | the industry standard, huge module ecosystem, one language for everything | state management is your job |
| AWS CDK / CloudFormation | AWS | real programming languages (CDK), deep AWS integration, managed state | AWS-only |
| **Bicep** (ARM) | Azure | first-class Azure support, no state file, day-0 support for new resources | Azure-only |
| GCP Infrastructure Manager (managed Terraform) / Config Connector (K8s CRDs) | GCP | managed Terraform runs / GitOps-style | |
| Pulumi | all | general-purpose languages | smaller community |
| Crossplane | all (via Kubernetes) | platform teams building internal APIs | needs Kubernetes |

Most companies run **Terraform/OpenTofu for multi-cloud and SaaS**, sometimes with Bicep/CDK for
deep single-cloud work.

## Terraform done properly

```
infra/
├── modules/                 # reusable, versioned building blocks (vpc, service, database)
├── envs/
│   ├── dev/   main.tf  backend.hcl  terraform.tfvars
│   ├── stg/
│   └── prod/
└── .github/workflows/terraform.yml
```
- **Remote state** with locking and encryption: S3 with native lockfiles (`use_lockfile = true`),
  GCS, Azure Blob, or HCP Terraform/Spacelift/env0. Never local state for shared infra. Never
  commit state (it contains secrets).
- **One state per environment and per component** (network, data, app) to keep the blast radius small.
- Pin provider and module versions with `~>`, and commit `.terraform.lock.hcl`. Bump with Renovate/Dependabot.
- `terraform fmt`, `validate`, `tflint`, `trivy config` (security misconfig) in CI.
- **The PR workflow:** a PR runs `plan` and posts it as a comment → reviewer approves → merge →
  `apply` runs from CI with an OIDC role, never from laptops for prod.
- **Drift detection:** a scheduled `plan` that alerts when it isn't empty.
- **Secrets never go in `.tfvars`.** Let the platform generate them (e.g. RDS `manage_master_user_password`)
  or create the secret *container* in code and have a human add the value in the secret manager.
  Mark outputs `sensitive = true`.

## Policy as code

Checkov / Trivy / tfsec rules in CI, **OPA/Conftest** or Sentinel for org rules ("no public
buckets", "tags required"), plus the cloud-side guardrails from chapter 02 as the backstop.

## CI/CD for applications

```
PR: lint → unit tests → build image → scan (Trivy/Grype) → SBOM → preview environment
main: build once (tag = git SHA) → push to ECR/Artifact Registry/ACR → deploy to staging → integration/smoke tests
release: promote the SAME image to prod (approval gate) → progressive rollout (canary/blue-green) → automatic rollback on SLO breach
```
- **Build once, promote the artifact.** Never rebuild for prod.
- Sign images (cosign/Sigstore, Notation) and verify them at deploy time (Binary Authorization on
  GKE, admission policies, ECR signing).
- Deploy via native tools (ECS rolling/blue-green with CodeDeploy, Cloud Deploy, Container Apps
  revisions) or GitOps (Argo CD/Flux) for Kubernetes.

## OIDC from CI (no stored cloud keys)

| Cloud | GitHub Action | Trust is set up with |
|---|---|---|
| AWS | `aws-actions/configure-aws-credentials` | an IAM OIDC provider + a role whose trust policy limits `sub` to `repo:org/repo:environment:prod` |
| GCP | `google-github-actions/auth` | a Workload Identity Pool + provider with `attribute_condition` on the repository |
| Azure | `azure/login` | a federated credential on an app registration or user-assigned managed identity |

Ready-made versions are in `AWS/files`, `GCP/files` and `AZURE/files`.

## Exercises
1. Bootstrap remote state (AWS starter) and move a local state into it with `terraform init -migrate-state`.
2. Add a CI job that fails a PR when `trivy config` finds a public bucket.
3. Deploy an app via GitHub Actions with OIDC, and delete every stored cloud credential from the repo's secrets.
