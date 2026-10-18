# 08 — Backups, Monitoring and Scaling VPSes

## Backups: snapshots aren't enough

| Mechanism | Protects against | Doesn't protect against |
|---|---|---|
| Provider snapshots/backups | a botched upgrade, a quick rollback | provider account loss/suspension, region outage, silent corruption, ransomware with API access |
| **restic/borg to off-site storage** (another provider) | all of the above | (test restores!) |
| DB dumps + PITR | logical errors ("someone ran DELETE") | |

Use the restic setup from Servers ch. 04 (`Servers/files/backups/`). Target a bucket at a
**different provider** from your VPS, with Object Lock where available.

## Monitoring a VPS fleet

- **External uptime checks** from outside your infrastructure: Uptime Kuma on a VPS at *another*
  provider, or a SaaS (Better Stack, UptimeRobot, Healthchecks.io for cron/backup heartbeats).
- **Metrics/logs:** the Prometheus/Grafana/Loki stack from Servers ch. 08 on one small "ops" VPS,
  scraping the others over the private network/WireGuard. Or a hosted option (Grafana Cloud free
  tier, Better Stack, Netdata).
- Alert on: down, 5xx rate, p95 latency, disk/memory, cert expiry, backup staleness, plus **provider
  status pages** and bandwidth quota usage.

## Scaling path

1. **Measure first.** Find what's actually saturated (CPU, RAM, disk IO, DB connections, network).
2. **Optimise:** caching (Redis, HTTP cache/CDN), DB indexes, fixing N+1 queries, static assets on a CDN.
3. **Scale vertically:** a bigger VPS. It's cheap, takes minutes, and has no code changes.
4. **Split roles:** separate the DB server from the app servers. Add a managed DB if HA matters.
5. **Scale horizontally:** stateless app servers × N behind a load balancer (ch. 06), plus
   background workers on separate nodes.
6. **Multi-region** only when users or availability truly need it. It multiplies complexity
   (data replication, latency, failover).

## When to move from VPS to the cloud (or a managed platform)

- Compliance needs (SOC 2/ISO/PCI audits want IAM, audit trails, managed encryption).
- You need managed services (queues, autoscaling, global databases, ML) more than you need low cost.
- On-call for databases/HA is eating your team's time.
- Spiky traffic that autoscaling handles more cheaply than idle VPSes.

That's the **Cloud** section of this handbook.

## Monthly VPS review checklist
- [ ] Restore test passed (and how long it took)
- [ ] Resource trends: right-size up or down
- [ ] Bandwidth vs included quota
- [ ] Patches applied, reboots done, OS still in support
- [ ] Users/keys/API tokens reviewed (provider, registrar, DNS, CI)
- [ ] Costs vs budget
