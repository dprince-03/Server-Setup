# 01 — Choosing the Right Service for Each Type of App

Decision order the industry uses: **managed/serverless first → containers → Kubernetes → VMs**,
moving down only when a requirement forces you to.

```
Is it static (HTML/JS/assets)?            → object storage + CDN / static hosting
Is it event-driven, spiky, short tasks?    → functions
Is it a containerised HTTP service/API?    → serverless containers (Cloud Run / Container Apps / ECS Fargate)
Many services, a platform team, portability, custom networking? → Kubernetes (GKE Autopilot / AKS Automatic / EKS Auto Mode)
Needs a specific OS, kernel, GPU driver control, licensed software, Windows desktop apps? → VMs (+ autoscaling groups)
```

## Recommendations by workload

| Workload | AWS | GCP | Azure | Notes |
|---|---|---|---|---|
| **Static site / SPA** | S3 + CloudFront (or Amplify Hosting) | Cloud Storage + Cloud CDN / Firebase Hosting | Static Web Apps / Storage + Front Door | add a WAF for public apps |
| **Monolith web app** (Django, Rails, Laravel, Spring, .NET, Node) | ECS Fargate (+ALB) or ECS Express Mode; Elastic Beanstalk | **Cloud Run** | **Container Apps** or App Service | managed DB + cache next to it |
| **REST/GraphQL API** | ECS Fargate / Lambda + API Gateway | Cloud Run (+ API Gateway/Apigee) | Container Apps / Functions + API Management | serverless for spiky APIs, containers for steady ones |
| **Microservices** | ECS (service connect) or EKS | Cloud Run or GKE Autopilot | Container Apps (Dapr) or AKS | each service owns its data. Use async messaging |
| **Event-driven / serverless** | Lambda + EventBridge/SQS/SNS | Cloud Run functions + Eventarc/Pub/Sub | Functions + Event Grid/Service Bus | make handlers idempotent; add dead-letter queues |
| **Background jobs / workers** | ECS services/tasks, SQS consumers, AWS Batch | Cloud Run jobs, Cloud Tasks, Batch | Container Apps jobs, Functions, Azure Batch | |
| **Scheduled / cron** | EventBridge Scheduler → Lambda/ECS task | Cloud Scheduler → Cloud Run job | Container Apps jobs (cron) / Functions timer | |
| **Real-time** (websockets, chat, games) | ALB + ECS, API Gateway WebSocket, AppSync | Cloud Run (websockets), Firebase RTDB/Firestore | Web PubSub, SignalR Service | sticky sessions or pub/sub fan-out |
| **Mobile backend** | Amplify (Cognito, AppSync, S3) or API on ECS/Lambda | **Firebase** (Auth, Firestore, FCM, Functions) | App Service/Functions + Entra External ID + Notification Hubs | push notifications via FCM/APNs |
| **Desktop app backend** (updates, licensing, telemetry, sync) | S3 + CloudFront for updates; API on Lambda/ECS | Cloud Storage + CDN; Cloud Run | Blob + Front Door; Functions | sign the binaries; serve updates from the CDN |
| **Data warehouse / analytics** | Redshift, Athena + S3 (lakehouse), Glue | **BigQuery** | Fabric / Synapse, Databricks | ELT with dbt; orchestrate with Airflow |
| **Streaming data** | Kinesis / MSK | Pub/Sub, Managed Kafka, Dataflow | Event Hubs, Stream Analytics | |
| **ML training** | SageMaker AI, EC2 GPU, HyperPod | Vertex AI Training, GKE + GPU/TPU | Azure ML, GPU VMs | track experiments; use spot/preemptible capacity |
| **ML inference** | SageMaker endpoints, ECS/EKS GPU, Lambda (small models) | Vertex AI endpoints, Cloud Run with GPUs | Azure ML online endpoints, Container Apps GPU | autoscale on concurrency |
| **GenAI apps** (LLMs, RAG, agents) | **Bedrock** (Claude and others) + Knowledge Bases, OpenSearch/pgvector | **Vertex AI** (Gemini, Claude via Model Garden) + Vector Search/AlloyDB | **AI Foundry** (OpenAI, others) + AI Search | keep keys in the secret manager; log prompts responsibly |
| **IoT** | IoT Core + Greengrass v2 | partner platforms + Pub/Sub (IoT Core retired in 2023) | IoT Hub, IoT Operations | |
| **Lift-and-shift VMs / legacy** | EC2 + ASG, Application Migration Service | Compute Engine + MIG, Migrate to VMs | VMs + VMSS, Azure Migrate | modernise later; start with rehosting |
| **Windows / .NET Framework** | EC2 Windows, Elastic Beanstalk .NET | Compute Engine Windows | **App Service**, Azure VMs, AVD | Azure is strongest for the Microsoft stack |
| **Virtual desktops** | WorkSpaces | (partners) | Azure Virtual Desktop | |
| **HPC / batch compute** | AWS Batch, ParallelCluster | Batch, HPC Toolkit | Azure Batch, CycleCloud | |
| **Internal tools / low-code** | (third-party) | AppSheet | Power Apps | |

## Picking the database

| Data shape / need | Choose |
|---|---|
| Relational, transactions, most apps | **PostgreSQL** managed (RDS/Aurora, Cloud SQL/AlloyDB, Azure Database for PostgreSQL) |
| MySQL ecosystem | RDS/Aurora MySQL, Cloud SQL MySQL, Azure Database for MySQL |
| Global, strongly consistent at huge scale | Spanner, Aurora DSQL, Cosmos DB |
| Key-value / document, serverless scale | DynamoDB, Firestore, Cosmos DB |
| MongoDB API | MongoDB Atlas (on any cloud), DocumentDB (compatible), Cosmos DB for MongoDB |
| Cache / sessions / rate limits | ElastiCache/Memorystore/Azure Managed Redis (Valkey/Redis) |
| Search | OpenSearch, Elastic Cloud, Azure AI Search, Vertex AI Search |
| Vectors (RAG) | pgvector in managed Postgres first; dedicated vector services at large scale |
| Time series | Timestream / Bigtable / Azure Data Explorer, or TimescaleDB |

## Exercises
1. For your current project, fill in the table: workload → service on each cloud → why → monthly cost estimate.
2. Deploy the same container to Cloud Run, Container Apps and ECS Express Mode, and compare the time
   to first deploy, the cold starts and the cost.
