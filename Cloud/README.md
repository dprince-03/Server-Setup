# Cloud Platforms: AWS, GCP, Azure

How industry teams build on the public cloud: **concepts first** (they transfer between
providers), then **platform guides** with real tooling and starter code.

## Concept chapters (read in order)

| # | Chapter | Covers |
|---|---|---|
| 00 | [Cloud fundamentals](00-cloud-fundamentals.md) | service models, shared responsibility, regions/AZs, Well-Architected, **service map across AWS/GCP/Azure** |
| 01 | [Choosing the right service per app type](01-choosing-services.md) | static sites, web apps, APIs, microservices, serverless, jobs, data, ML/GenAI, mobile, desktop, IoT, legacy |
| 02 | [Landing zones and identity](02-landing-zones-identity.md) | org/account structure, SSO, least privilege, workload identity, guardrails |
| 03 | [Cloud networking](03-networking.md) | VPC design, subnets, NAT, private endpoints, hub-and-spoke, hybrid links, load balancers, CDN/WAF |
| 04 | [IaC and CI/CD](04-iac-cicd.md) | Terraform/OpenTofu vs native IaC, state, modules, environments, OIDC from CI, policy as code |
| 05 | [Security and compliance](05-security-compliance.md) | secrets, keys, encryption, posture management, scanning, audit, frameworks |
| 06 | [Observability and reliability](06-observability-reliability.md) | logs/metrics/traces, SLOs, multi-AZ, backups, DR strategies |
| 07 | [Cost management (FinOps)](07-cost-finops.md) | budgets, tagging, rightsizing, commitments, spot, egress, cleanup |
| 08 | [Multi-cloud and hybrid](08-multi-cloud-hybrid.md) | when it's worth it, and how to do it without the pain |

## Platform guides

| Platform | Guide | Starter files |
|---|---|---|
| **AWS** | [AWS/](AWS/README.md) | Terraform state bootstrap, VPC + ECS Fargate + ALB + RDS (Secrets Manager-managed password), GitHub OIDC role, SCP guardrails, deploy workflow |
| **GCP** | [GCP/](GCP/README.md) | Terraform: Cloud Run + Artifact Registry + Secret Manager + Workload Identity Federation, org policies, deploy workflow |
| **Azure** | [AZURE/](AZURE/README.md) | Bicep: Container Apps + ACR + Key Vault + managed identity, Azure Policy, deploy workflow |

## Ground rules for every cloud exercise

1. **Budget alert first** (chapter 07), before creating anything.
2. **No long-lived access keys.** Humans use SSO, and CI uses OIDC federation.
3. **Everything as code.** The console is for learning and reading, not for making production changes.
4. **Tag everything:** `owner`, `env`, `project`, `cost-center`.
5. **Secrets only in the cloud's secret manager.** You type the values yourself. They're never in
   files, repos or chat.
6. **Clean up:** `terraform destroy` / delete the resource group / shut down the project when the
   exercise ends.
