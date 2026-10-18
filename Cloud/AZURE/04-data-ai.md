# Azure 04 — Data and AI

## Storage and databases

| Service | Use | Best practices |
|---|---|---|
| Storage accounts (Blob, Files, Queues, Tables) | objects, file shares, simple queues | disable shared-key access and use Entra RBAC; no public blob access; soft delete + versioning; immutability policies for backups; lifecycle tiers (hot/cool/cold/archive) |
| **Azure SQL Database / Managed Instance** | SQL Server workloads | Entra-only authentication; zone redundancy; PITR + long-term retention; auto-failover groups for DR |
| **Azure Database for PostgreSQL / MySQL Flexible Server** | open-source relational | private access (VNet/Private Endpoint); zone-redundant HA; Entra authentication |
| **Cosmos DB** | global multi-model NoSQL (NoSQL, MongoDB vCore, Cassandra, Gremlin, Table APIs) | choose the partition key carefully; autoscale RU/s; serverless for dev |
| Azure Managed Redis / Azure Cache for Redis | cache, sessions | private endpoint; Entra auth |
| Azure Data Explorer | logs/telemetry analytics (KQL) | |

## Analytics

**Microsoft Fabric** (OneLake, Data Factory, Data Engineering/Spark, Warehouse, Real-Time
Intelligence, Power BI) is Microsoft's unified analytics platform. Azure Databricks is the main
alternative. Purview handles governance. Synapse is still supported, but new projects usually pick Fabric.

## AI

| Need | Service |
|---|---|
| Foundation models (OpenAI GPT models, plus Llama, Mistral and others) | **Azure AI Foundry** (Azure OpenAI in Foundry Models) |
| Agents | Foundry Agent Service |
| RAG / search | **Azure AI Search** (vector + hybrid search) |
| Prebuilt AI | Document Intelligence, Speech, Vision, Translator, Content Safety |
| Custom ML / MLOps | Azure Machine Learning |

Use **managed identity** to call Azure OpenAI/AI Search (RBAC: *Cognitive Services OpenAI User*)
instead of API keys, and disable key-based auth where possible.
