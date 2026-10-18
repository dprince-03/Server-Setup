# 08 — Monitoring, Logging and Alerting

## The three pillars + uptime

| Signal | Question it answers | Tool (open-source standard) |
|---|---|---|
| **Metrics** | Is it healthy? Is it trending toward trouble? | **Prometheus** + exporters (node_exporter, cAdvisor, postgres_exporter...) |
| **Logs** | What exactly happened? | **Loki** (+ Grafana Alloy as the collector), or the ELK/OpenSearch stack |
| **Traces** | Where is the request slow? | OpenTelemetry → Tempo/Jaeger |
| **Uptime / synthetic** | Can users reach it? | **Uptime Kuma**, Blackbox exporter, Gatus |
| Dashboards | One place to look | **Grafana** |
| Alerts | Wake someone only when it matters | **Alertmanager** → email/Telegram/Slack/ntfy/PagerDuty |

All-in-one alternatives: Zabbix, Netdata, Checkmk (popular with traditional ops teams).

## Deploy the stack (`files/monitoring/`)

```bash
sudo mkdir -p /opt/stacks/monitoring && sudo cp -r files/monitoring/. /opt/stacks/monitoring/
# edit prometheus/prometheus.yml → your hosts' IPs, and alertmanager/alertmanager.yml → your SMTP host
# YOU: create GRAFANA_ADMIN_PASSWORD and ALERTMANAGER_SMTP_PASSWORD in the secret manager project,
#      and write the project ID to /opt/stacks/monitoring/BWS_PROJECT_ID (see ../SECRETS.md)
sudo systemctl enable --now stack@monitoring     # Servers/files/secrets/stack@.service injects the secrets
```
- Grafana: `http://<monitor-host>:3000` (put it behind the reverse proxy + SSO)
- Prometheus: `:9090` · Alertmanager: `:9093` · Uptime Kuma: `:3001` · Loki: `:3100`
- Install node_exporter on **every** server: `sudo apt install prometheus-node-exporter`, or let
  Ansible do it. Allow port 9100 **only from the monitoring host**.
- Import Grafana dashboards: "Node Exporter Full" (ID 1860) and others from grafana.com.

## What to alert on (start with these, then tune)

From [`files/monitoring/prometheus/alerts.yml`](files/monitoring/prometheus/alerts.yml):
- Host down (scrape fails for 2+ min)
- Disk will fill within 24 h (`predict_linear`), or is over 85 %
- Memory available under 10 %, sustained high load
- systemd unit failed
- TLS certificate expiring within 14 days (blackbox exporter)
- Backup didn't run in 26 h (push a metric from the backup script, or use a heartbeat check in Uptime Kuma)

**Good alerting practice:** alert on **symptoms users feel** (down, slow, errors) plus things that
will become outages (disk, certs, backups). Every alert must be actionable and link to a runbook
(chapter 09). Noisy alerts get ignored. Delete or fix them.

## Logging

- Ship journald + `/var/log/*` + container logs to Loki with **Grafana Alloy** (the successor to
  Promtail).
- Retention: 14–30 days hot, longer in object storage if compliance needs it.
- Sensitive data: never log secrets, tokens or full card numbers. Scrub PII where you can.

## SLIs, SLOs and error budgets (how SRE teams think)

- **SLI:** measured indicator (e.g. % of successful requests, p95 latency).
- **SLO:** the target (99.9 % monthly availability ≈ 43 minutes of downtime/month).
- **Error budget:** 100 % − SLO. Spend it on releases and experiments. When it's gone, focus on reliability.

## Exercises
1. Deploy the stack and get three servers' metrics in Grafana.
2. Fill a disk in a VM (`fallocate -l 5G /fill`) and watch the alert fire and resolve.
3. Define one SLO for a service you run and build its Grafana panel.
