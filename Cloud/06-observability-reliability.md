# 06 — Observability and Reliability

## Observability stack choices

| Option | When |
|---|---|
| **Native** (CloudWatch + X-Ray / Cloud Monitoring + Logging + Trace / Azure Monitor + Log Analytics + App Insights) | single cloud, least setup. Good defaults for managed services |
| **OpenTelemetry → a vendor or self-hosted** (Grafana Cloud/LGTM, Datadog, New Relic, Honeycomb, Elastic) | multi-cloud, one pane of glass, richer APM |

Instrument apps with **OpenTelemetry SDKs** either way, so changing backends doesn't mean
re-instrumenting.

What to collect: request rate, **errors** and **latency** (RED) per service; saturation for
resources (USE); structured JSON logs with a request/trace ID; traces across service boundaries;
and business metrics (sign-ups, orders).

Alert on SLO burn rates (fast and slow burn), not raw CPU. See Servers ch. 08 for SLO basics.

## Designing for failure

| Failure | Design response |
|---|---|
| Instance/container dies | multiple instances + health checks + autoscaling (min ≥ 2 in prod) |
| AZ outage | spread across ≥ 2–3 AZs; Multi-AZ databases; zone-redundant services |
| Region outage | DR strategy (below) |
| Dependency slow/down | timeouts, retries with backoff + jitter, circuit breakers, queues to absorb spikes |
| Bad deploy | progressive delivery + auto-rollback + feature flags |
| Data corruption / deletion | PITR backups, versioned buckets with object lock, cross-account backup copies |

## Backups in the cloud

AWS Backup / GCP Backup and DR / Azure Backup. Centralise the policies, **copy to another
account/project and region**, enable vault lock (immutability), and **test restores** on a schedule.
Managed DBs: turn on point-in-time recovery, and know the restore procedure (it often creates a *new* instance).

## DR strategies (cheapest → fastest)

| Strategy | RTO / RPO | How |
|---|---|---|
| Backup and restore | hours / hours | backups copied cross-region; rebuild from IaC |
| Pilot light | tens of minutes / minutes | data replicated; minimal core running in the DR region; scale up on failover |
| Warm standby | minutes / seconds | a scaled-down full copy running in the DR region |
| Multi-site active/active | ~0 / ~0 | both regions serve traffic; global DB (Aurora Global, Spanner, Cosmos DB) |

Pick per workload from its business impact. Practise failover (game days), because an untested DR
plan is a guess.

## Exercises
1. Instrument a service with OpenTelemetry and view one trace end to end.
2. Define an SLO and a burn-rate alert in your cloud's native monitoring.
3. Restore a managed database to a point in time 10 minutes ago, and time it.
