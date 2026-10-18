# 00 — Cloud Fundamentals

## Service models

| Model | You manage | Provider manages | Examples |
|---|---|---|---|
| IaaS | OS, runtime, app, data | hardware, virtualization, network | EC2, Compute Engine, Azure VMs |
| CaaS | containers, app, data | cluster/servers (partly) | ECS Fargate, Cloud Run, Azure Container Apps, EKS/GKE/AKS |
| PaaS | app + data | runtime, scaling, OS | Elastic Beanstalk, App Engine, Azure App Service |
| FaaS / serverless | functions + data | everything else, scale-to-zero | Lambda, Cloud Run functions, Azure Functions |
| SaaS | configuration + data | all of it | Microsoft 365, Google Workspace |

The higher up you go, the less you operate and the less you can control. Industry default
today: **managed containers or serverless for apps, managed databases for data, VMs only when
you need them** (legacy software, special OS/kernel, licensing, steady heavy compute).

## Shared responsibility

The provider secures **the cloud** (data centres, hardware, hypervisor, managed-service internals).
You secure **what's in the cloud**: identities, IAM policies, network exposure, data, encryption
choices, OS patching (IaaS), app code and secrets. **Most cloud breaches are customer
misconfiguration** (public buckets, leaked keys, over-broad IAM), not provider failures.

## Geography

- **Region:** a geographic area (e.g. `eu-west-1`, `europe-west1`, `westeurope`). Choose it for
  latency to users, data-residency law, service availability and price.
- **Availability zone (AZ):** isolated data centres within a region. **Production spans ≥ 2 AZs.**
- **Edge locations:** CDN/DNS points of presence (CloudFront, Cloud CDN, Azure Front Door).

## Well-Architected frameworks (same ideas, different names)

| AWS Well-Architected (6 pillars) | Azure Well-Architected (5) | Google Cloud Architecture Framework |
|---|---|---|
| Operational excellence | Operational excellence | Operational excellence |
| Security | Security | Security, privacy, compliance |
| Reliability | Reliability | Reliability |
| Performance efficiency | Performance efficiency | Performance optimisation |
| Cost optimisation | Cost optimisation | Cost optimisation |
| Sustainability | | Sustainability |

Use the free review tools (AWS WA Tool, Azure Advisor/WAF assessments) on real workloads.

## Service map: the same thing on each cloud

| Need | AWS | GCP | Azure |
|---|---|---|---|
| Virtual machines | EC2 | Compute Engine | Virtual Machines |
| Autoscaling VM groups | Auto Scaling Groups | Managed Instance Groups | VM Scale Sets |
| Managed containers (serverless) | ECS on Fargate (ECS Express Mode for simple web apps) | **Cloud Run** | **Container Apps** |
| Kubernetes | EKS (Auto Mode) | GKE (Autopilot) | AKS (Automatic) |
| Functions | Lambda | Cloud Run functions | Azure Functions |
| PaaS web apps | Elastic Beanstalk, Amplify Hosting | App Engine, Firebase App Hosting | App Service, Static Web Apps |
| Object storage | S3 | Cloud Storage | Blob Storage |
| Block / file storage | EBS / EFS, FSx | Persistent Disk, Hyperdisk / Filestore | Managed Disks / Azure Files, NetApp Files |
| Relational DB | RDS, Aurora | Cloud SQL, AlloyDB, Spanner | Azure SQL, Database for PostgreSQL/MySQL Flexible Server |
| NoSQL | DynamoDB, DocumentDB | Firestore, Bigtable | Cosmos DB |
| Cache | ElastiCache (Valkey/Redis), MemoryDB | Memorystore | Azure Cache for Redis / Azure Managed Redis |
| Data warehouse | Redshift | **BigQuery** | Synapse / Microsoft Fabric |
| Streaming / queues | Kinesis, MSK, SQS, SNS, EventBridge | Pub/Sub, Managed Kafka, Eventarc, Cloud Tasks | Event Hubs, Service Bus, Event Grid, Storage Queues |
| Workflow / orchestration | Step Functions, MWAA (Airflow) | Workflows, Cloud Composer | Logic Apps, Durable Functions, Data Factory |
| ML platform / GenAI | SageMaker AI, **Bedrock** | **Vertex AI** (Gemini, Model Garden) | Azure Machine Learning, **Azure AI Foundry** (Azure OpenAI) |
| Identity (workforce) | IAM Identity Center | Cloud Identity / Google Workspace | Microsoft Entra ID |
| Secrets | Secrets Manager, SSM Parameter Store | Secret Manager | Key Vault |
| Keys / HSM | KMS, CloudHSM | Cloud KMS, Cloud HSM | Key Vault (keys), Managed HSM |
| Network | VPC | VPC (global) | Virtual Network (VNet) |
| Load balancing | ALB / NLB / GWLB | Cloud Load Balancing | Application Gateway / Load Balancer / Front Door |
| DNS | Route 53 | Cloud DNS | Azure DNS |
| CDN / WAF | CloudFront / AWS WAF, Shield | Cloud CDN / Cloud Armor | Front Door, Azure CDN / WAF, DDoS Protection |
| Private connectivity | VPN, Direct Connect, PrivateLink | Cloud VPN, Interconnect, Private Service Connect | VPN Gateway, ExpressRoute, Private Link |
| Monitoring / logs | CloudWatch, X-Ray | Cloud Monitoring, Logging, Trace | Azure Monitor, Log Analytics, App Insights |
| Audit trail | CloudTrail | Cloud Audit Logs | Activity Log / Entra audit logs |
| Security posture | Security Hub, GuardDuty, Inspector | Security Command Center | Defender for Cloud, Sentinel (SIEM) |
| Policy guardrails | SCPs/RCPs, Config, Control Tower | Organization Policy | Azure Policy, management groups |
| Native IaC | CloudFormation, CDK | Infrastructure Manager (Terraform), Config Connector | ARM/**Bicep** |
| Container registry | ECR | Artifact Registry | Azure Container Registry |
| CI/CD | CodePipeline/CodeBuild | Cloud Build, Cloud Deploy | Azure DevOps Pipelines |
| Cost | Cost Explorer, Budgets | Billing reports, Budgets | Cost Management + Budgets |

> **Service lifecycle check (2026):** providers retire services. Examples: **AWS App Runner
> closed to new customers on 30 Apr 2026** (AWS recommends ECS Express Mode); AWS CodeCommit and
> Cloud9 closed to new customers in 2024; GCP Container Registry was replaced by Artifact Registry.
> Before you adopt a service, check its status page/docs for "maintenance" or "closed to new
> customers" notices.

## Exercises
1. Choose a region for a product with users in Lagos and London. Justify it on latency,
   residency and price.
2. For one app you know, write which layers *you* would secure under IaaS vs CaaS vs FaaS.
