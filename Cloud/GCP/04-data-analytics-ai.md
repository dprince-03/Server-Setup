# GCP 04 — Data, Analytics and AI

## Storage and databases

| Service | Use | Best practices |
|---|---|---|
| Cloud Storage | objects, static assets, data lake, backups | uniform bucket-level access; public access prevention; Autoclass; object versioning + retention lock for backups |
| **Cloud SQL** (PostgreSQL/MySQL/SQL Server) | standard relational | private IP; HA (regional) in prod; PITR; **IAM database authentication** (no passwords); Cloud SQL Auth Proxy/connectors |
| **AlloyDB** (PostgreSQL-compatible) | high-performance Postgres, HTAP, vector search | |
| **Spanner** | global, horizontally scalable, strongly consistent SQL | |
| Firestore | document DB for mobile/web/serverless | security rules; composite indexes |
| Bigtable | wide-column, huge throughput (time series, IoT) | |
| Memorystore | Valkey/Redis/Memcached | |

## Analytics

**BigQuery** is GCP's flagship: a serverless warehouse; partition and cluster the tables; use
capacity reservations or on-demand pricing; BigQuery ML; BI Engine; data sharing with Analytics
Hub. Around it: Pub/Sub (streaming ingest), Dataflow (Beam), Dataproc (Spark/Hadoop), Cloud
Composer (Airflow), Dataform (SQL pipelines), Looker / Looker Studio (BI), and Dataplex
(governance/catalog).

Cost control: set **maximum bytes billed** per query, require partition filters, and use
`--dry_run` to estimate.

## AI and ML

| Need | Service |
|---|---|
| Foundation models (Gemini; Claude and open models via **Model Garden**) | **Vertex AI** (generative AI APIs, Agent Builder / Agent Engine) |
| RAG / search | Vertex AI Search, Vector Search, AlloyDB/pgvector |
| Custom training / MLOps | Vertex AI Training, Pipelines, Model Registry, Endpoints, Feature Store |
| Notebooks | Vertex AI Workbench, Colab Enterprise |
| Accelerators | GPUs, and **TPUs** for large training jobs |

Authenticate to Vertex AI with service accounts/ADC. There are no API keys to store.
