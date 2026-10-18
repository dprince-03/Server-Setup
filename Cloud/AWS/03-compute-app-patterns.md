# AWS 03 — Compute and Application Patterns

## Choosing compute on AWS

| Service | Use it for | Notes |
|---|---|---|
| **ECS on Fargate** | most containerised web apps, APIs and workers | no servers or clusters to patch; per-task IAM roles; the starter in `files/terraform/web-app` |
| **ECS Express Mode** | the simplest path from container image to HTTPS URL | AWS's recommended successor for App Runner users (App Runner closed to new customers on 30 Apr 2026) |
| **Lambda** | event-driven, spiky, short (≤ 15 min) work; glue; APIs with API Gateway or function URLs | pay per request; watch cold starts, concurrency limits and VPC needs |
| **EKS** (Auto Mode) | Kubernetes platforms, many teams, portability | Auto Mode manages nodes/add-ons; still the most operations-heavy |
| **EC2 + Auto Scaling Groups** | custom OS/AMI, GPUs, licensed software, steady heavy compute | bake AMIs (EC2 Image Builder/Packer); patch with SSM Patch Manager |
| Elastic Beanstalk | quick PaaS for classic apps | aging, but still supported |
| Amplify Hosting | front-end/SSR web apps (Next.js) with Git-based CI | |
| AWS Batch | containerised batch/HPC queues, spot-friendly | |
| Lightsail | VPS-style simple servers at a fixed price | good for VPS-like needs inside AWS |

## Pattern: containerised web app (ECS Fargate)

```
Route 53 → CloudFront (+WAF) → ALB (public subnets) → ECS service (private subnets, ≥2 tasks over 2 AZs)
                                                          ├── RDS PostgreSQL Multi-AZ (database subnets)
                                                          ├── ElastiCache (Valkey) for cache/sessions
                                                          └── S3 for uploads (VPC gateway endpoint)
Secrets: Secrets Manager → task definition `secrets` · Logs: CloudWatch Logs / FireLens · Deploys: GitHub OIDC → ECS rolling (circuit breaker + auto-rollback)
```
Autoscaling: target tracking on CPU, memory or **ALB requests per target**. Use **Fargate Spot**
for workers.

## Pattern: serverless API

```
API Gateway (HTTP API) or Lambda function URL → Lambda (one function per route group) → DynamoDB / Aurora Serverless v2 (via RDS Proxy)
Async: SQS (+DLQ) / EventBridge → Lambda consumers · Orchestration: Step Functions
```
Tooling: AWS SAM, the CDK, the Serverless Framework, or SST. Use Powertools for AWS Lambda for
logging, tracing and idempotency.

## Pattern: event-driven microservices

Services publish domain events to **EventBridge** (routing/filtering) or **SNS → SQS** (fan-out),
and consumers process them idempotently with dead-letter queues. Each service owns its own datastore.

## Pattern: static + SPA front end

S3 (private, Origin Access Control) → CloudFront with a cache policy → WAF. CI deploys with
`aws s3 sync` + a CloudFront invalidation, or Amplify Hosting.

## Pattern: ML / GenAI

- **Amazon Bedrock**: managed foundation models (Anthropic Claude, Amazon Nova, Llama, Mistral...),
  Knowledge Bases (RAG), Agents and Guardrails. Access is through IAM, so no API keys are stored.
- **SageMaker AI**: training jobs, endpoints, pipelines and notebooks. HyperPod for large-scale training.
- GPU EC2 (G/P families), or Inferentia/Trainium for cost-optimised inference and training.

## Ops essentials for compute

- **No SSH keys:** use SSM Session Manager (`aws ssm start-session --target i-...`) and ECS Exec for containers.
- SSM Patch Manager + maintenance windows for EC2; Image Builder pipelines for AMIs.
- Graviton (ARM) instances/Fargate are usually 20–40 % cheaper per unit of performance.
