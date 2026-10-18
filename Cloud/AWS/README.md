# AWS Guide

| # | Chapter | Covers |
|---|---|---|
| 01 | [Account foundation](01-account-foundation.md) | Organizations, Control Tower, IAM Identity Center, root lockdown, CloudTrail, budgets, SCPs |
| 02 | [Networking](02-networking.md) | VPC layout, endpoints, Transit Gateway, Route 53, ALB/NLB, CloudFront/WAF |
| 03 | [Compute and app patterns](03-compute-app-patterns.md) | EC2/ASG, ECS Fargate, ECS Express Mode, Lambda, EKS, Amplify, Batch |
| 04 | [Data and storage](04-data-storage.md) | S3, EBS/EFS, RDS/Aurora, DynamoDB, ElastiCache, analytics, Bedrock/SageMaker |
| 05 | [Security and operations](05-security-operations.md) | GuardDuty, Security Hub, KMS, Secrets Manager, Systems Manager, CloudWatch, Backup |
| 06 | [Tools, CLI and IaC](06-tools-cli-iac.md) | AWS CLI v2 + SSO, CDK/CloudFormation, Terraform, using the starter files |

**Files** (`files/`):

| Path | What |
|---|---|
| `terraform/bootstrap-state/` | S3 bucket for Terraform state (versioned, encrypted, native locking) |
| `terraform/web-app/` | VPC (3-tier, 2 AZs) + ALB + ECS Fargate service + ECR + RDS PostgreSQL with a **Secrets Manager-managed password** + GitHub OIDC deploy role |
| `iam/github-oidc-trust-policy.json` | trust policy restricting deploys to one repo + environment |
| `scp/baseline-guardrails.json` | Service Control Policy: protect CloudTrail/GuardDuty/Config, deny leaving the org, deny root use, region allow-list |
| `github-actions/deploy-ecs.yml` | build → ECR → new task definition → ECS deploy, via OIDC |
