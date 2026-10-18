# AWS 04 — Data and Storage

## Storage

| Service | Use | Best practices |
|---|---|---|
| **S3** | objects, static sites, data lake, backups | Block Public Access on; bucket-owner-enforced ownership; SSE-S3/KMS by default; versioning + lifecycle; Object Lock for backups/audit logs; access via VPC endpoint + bucket policy |
| EBS | VM disks | gp3 by default; encrypted; snapshots via AWS Backup |
| EFS | shared POSIX files (NFS) | for apps that truly need shared files; lifecycle to IA |
| FSx | Windows File Server, Lustre (HPC), NetApp ONTAP, OpenZFS | lift-and-shift file servers |

## Databases

| Service | When |
|---|---|
| **RDS PostgreSQL/MySQL/MariaDB/SQL Server/Oracle** | standard relational; Multi-AZ for prod; automated backups + PITR |
| **Aurora** (PostgreSQL/MySQL) | higher scale/availability, fast failover, Global Database, Serverless v2 |
| Aurora DSQL | serverless, distributed, active-active SQL |
| **DynamoDB** | key-value/document at any scale; design around access patterns (single-table design); on-demand capacity; PITR on |
| ElastiCache (Valkey/Redis OSS/Memcached), MemoryDB | cache, sessions, queues; MemoryDB when you need durability |
| DocumentDB | MongoDB-compatible API (check compatibility, or use MongoDB Atlas on AWS) |
| OpenSearch Service | search, logs, vector search |
| Neptune / Timestream / Keyspaces | graph / time series / Cassandra |

**Credentials:** `manage_master_user_password = true` (RDS/Aurora). AWS generates the password,
stores it in Secrets Manager and rotates it, so nobody ever sees it. The starter uses this. Better
still, use **IAM database authentication** or RDS Proxy with IAM.

## Analytics and data platforms

S3 data lake + Glue Data Catalog + **Athena** (SQL on S3) → Redshift (Serverless) for warehousing
→ QuickSight for BI; Kinesis/MSK/Firehose for streaming; Lake Formation for fine-grained access;
MWAA (managed Airflow) or Step Functions for orchestration; EMR / Glue for Spark.

## AI

Bedrock (models, Knowledge Bases → OpenSearch Serverless/Aurora pgvector/S3 Vectors),
SageMaker AI, and Amazon Q Developer for coding help.

## Backup

**AWS Backup** with org-wide backup policies: daily/weekly rules, cross-region + **cross-account copy**
to a backup account, Vault Lock (compliance mode), and restore testing (AWS Backup restore testing).
