# GCP 03 — Compute and Application Patterns

| Service | Use it for | Notes |
|---|---|---|
| **Cloud Run services** | containerised web apps and APIs (the default choice on GCP) | scale to zero, request- or instance-based billing, GPUs available, multi-container sidecars |
| **Cloud Run jobs** | batch tasks, migrations, scheduled work (with Cloud Scheduler) | parallel tasks, retries |
| **Cloud Run functions** (formerly Cloud Functions) | event handlers (Eventarc, Pub/Sub, GCS, HTTP) | source-based deploys built on Cloud Run |
| **GKE Autopilot** | Kubernetes without node management; many services; platform teams | pay per pod; GKE Standard for full node control |
| Compute Engine + MIGs | VMs: legacy, custom OS, GPUs/TPUs, licences | instance templates + managed instance groups + autohealing |
| App Engine | classic PaaS (existing apps) | new projects usually pick Cloud Run |
| **Firebase** | mobile/web backends: Auth, Firestore, Hosting, App Hosting (Next.js/Angular), FCM, Remote Config | same project as GCP; Firebase App Check for abuse protection |
| Batch | HPC and batch job queues | spot VMs |

## Pattern: web app on Cloud Run (the starter files)

```
Domain → Global external ALB + Cloud Armor + Cloud CDN → Cloud Run service (min instances ≥ 1 in prod, in the region of the users)
                                                     ├── Cloud SQL / AlloyDB (private IP via Direct VPC egress; IAM DB auth)
                                                     ├── Memorystore (Valkey/Redis)
                                                     └── Cloud Storage (uploads; signed URLs)
Secrets: Secret Manager → `--set-secrets` / env value_source · Identity: dedicated runtime service account
Async: Pub/Sub → push to Cloud Run, Cloud Tasks for rate-limited queues · Cron: Cloud Scheduler → Cloud Run job
CI/CD: GitHub Actions (WIF) or Cloud Build → Artifact Registry → Cloud Run revisions (traffic splitting for canaries)
```
Traffic splitting gives you canaries:
`gcloud run services update-traffic app --to-revisions app-00042-abc=10` (then promote it to 100).

## Pattern: microservices

Cloud Run services that talk over HTTPS with **service-to-service IAM auth** (the `run.invoker`
role, ID tokens), or GKE + Cloud Service Mesh. Use Pub/Sub/Eventarc for events and Workflows for
orchestration.

## Pattern: data and ML apps

Pub/Sub → Dataflow (Apache Beam) → BigQuery; scheduled transformations with Dataform/dbt;
Vertex AI pipelines for ML; serve models on Vertex AI endpoints or Cloud Run with GPUs.

## Pattern: mobile app

Firebase Auth + Firestore (with security rules!) + Cloud Run functions + FCM push. Add Cloud Run APIs
for heavier logic, and protect them with App Check.
