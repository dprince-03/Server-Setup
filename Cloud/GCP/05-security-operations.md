# GCP 05 — Security and Operations

## Security

| Service | Does |
|---|---|
| **Security Command Center** | posture findings, misconfigurations, vulnerabilities, threat detection (Premium/Enterprise), compliance reports |
| **Secret Manager** | secrets with versions, rotation notifications, CMEK, regional replication |
| Cloud KMS / Cloud HSM / EKM | customer-managed keys (CMEK) |
| IAM Recommender / Policy Analyzer / PAM | least privilege, just-in-time access |
| VPC Service Controls | data-exfiltration perimeters |
| Binary Authorization | only signed/attested images run on GKE/Cloud Run |
| Artifact Analysis | container vulnerability scanning |
| Cloud Armor / reCAPTCHA Enterprise | WAF, DDoS, bot defence |
| Sensitive Data Protection | discover and mask PII |

### Secrets: you type the values

```bash
gcloud secrets create api-key --replication-policy=automatic        # the container (Terraform does this in the starter)
gcloud secrets versions add api-key --data-file=-                   # type the value, then press Ctrl-D. Nothing is stored in history or files
gcloud secrets add-iam-policy-binding api-key --member=serviceAccount:app-runtime@PROJECT.iam.gserviceaccount.com --role=roles/secretmanager.secretAccessor
gcloud run services update app --set-secrets=API_KEY=api-key:latest  # Cloud Run injects it at start
```

## Operations

| Need | Service |
|---|---|
| Logs | **Cloud Logging** (Log Analytics with SQL; sinks to BigQuery/GCS/Pub/Sub; exclusion filters to control cost) |
| Metrics, uptime checks, alerting, SLOs | **Cloud Monitoring** (built-in SLO monitoring for Cloud Run/GKE services) |
| Traces / profiling | Cloud Trace, Cloud Profiler (OpenTelemetry supported) |
| Error grouping | Error Reporting |
| VM fleet ops | VM Manager (OS patch management, inventory, OS policies) |
| Backups | Backup and DR service, Cloud SQL automated backups + PITR, GCS versioning + Object Retention Lock |
| Incidents / status | Personalized Service Health |

Turn on alerts for: budget thresholds, SCC high/critical findings, IAM policy changes on the org/folders,
service-account key creation (should be blocked anyway), and Cloud Run 5xx/latency SLO burn.
