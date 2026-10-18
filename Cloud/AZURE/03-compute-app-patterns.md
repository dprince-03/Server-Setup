# Azure 03 — Compute and Application Patterns

| Service | Use it for | Notes |
|---|---|---|
| **Container Apps** | containerised web apps, APIs, microservices, workers, jobs | serverless (scale to zero, KEDA scaling), revisions + traffic splitting, Dapr, GPUs; the starter file |
| **App Service** | web apps (.NET, Java, Node, Python, PHP) and containers; strongest for .NET | deployment slots (blue/green), VNet integration, Easy Auth |
| **Functions** | event-driven code (Flex Consumption plan) | Durable Functions for workflows |
| **AKS** (Automatic or Standard) | Kubernetes platforms | Workload Identity, KEDA, Azure CNI Overlay |
| **Static Web Apps** | SPAs/static sites + serverless APIs | free tier, preview environments per PR |
| VMs + **VM Scale Sets** | legacy, Windows workloads, custom software, GPUs | Azure Update Manager for patching; Bastion for access |
| Azure Virtual Desktop | virtual desktops / Windows app streaming | |
| Azure Batch | HPC / batch | spot VMs |
| Azure Spring Apps | **being retired**: move to Container Apps or AKS | check the lifecycle notices before adopting any service |

## Pattern: web app on Container Apps (the starter Bicep)

```
Front Door (WAF) → Container App (external ingress, min replicas ≥ 1 in prod)
                     identity: user-assigned managed identity
                     ├── pulls images from ACR (AcrPull role; no registry passwords)
                     ├── secrets: Key Vault references (Key Vault Secrets User role)
                     ├── Azure Database for PostgreSQL Flexible Server (private endpoint, Entra auth)
                     └── Azure Managed Redis / Storage (private endpoints)
Logs: Log Analytics + Application Insights (OpenTelemetry) · Deploys: GitHub OIDC → new revision → traffic split
```

## Pattern: classic .NET / Java enterprise app

App Service (Premium v3/v4) with **deployment slots**: deploy to staging → warm-up → swap. Use VNet
integration + Private Endpoints to Azure SQL, and Entra ID authentication. Run in an App Service
Environment for full isolation.

## Pattern: event-driven / integration

Event Grid (events) / Service Bus (enterprise messaging with sessions, dead-letter queues) / Event Hubs
(streaming) → Functions or Container Apps (KEDA scalers). Logic Apps for low-code integrations
(Microsoft 365, SaaS connectors). API Management in front of the APIs.

## Pattern: Microsoft-stack desktop and mobile backends

Entra ID / Entra External ID for sign-in; App Service/Functions APIs; Notification Hubs for push;
Blob + Front Door to distribute desktop app updates (MSIX/installer files).
