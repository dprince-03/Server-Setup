# 01 — Choosing a VPS

## VPS vs dedicated vs cloud vs PaaS

| Option | You manage | Good for |
|---|---|---|
| **VPS** (Hetzner, DigitalOcean, Linode/Akamai, Vultr, OVHcloud, Contabo, Scaleway, UpCloud) | OS and up | predictable cost, full control, small/medium apps, learning |
| Dedicated / bare metal | hardware choice + OS and up | heavy, steady workloads, large databases |
| Cloud IaaS (AWS EC2, GCP Compute Engine, Azure VMs) | OS and up, plus a huge ecosystem | enterprise integration, compliance, autoscaling, managed services |
| PaaS (Render, Fly.io, Railway, Heroku, Vercel/Netlify for frontends) | just your code | speed and small teams, at a higher price per resource |

Industry reality: startups often begin on PaaS or VPS, move core workloads to the cloud as
compliance and scale demand, and keep VPSes for cost-sensitive steady workloads.

## How to compare providers

| Factor | What to check |
|---|---|
| CPU | **shared vs dedicated vCPU** (shared is cheap but noisy). Check the CPU generation |
| RAM / disk | NVMe SSD. Can volumes be attached and resized? |
| Network | included **traffic** (TB/month), per-TB price beyond that, port speed, IPv6 included, IPv4 cost |
| Regions | close to your users, plus data-residency needs (GDPR/NDPA) |
| Private networking | free private network/VPC between servers in a region (needed for chapter 06) |
| Firewall | a provider-level (cloud) firewall in front of the VM |
| Snapshots / backups | price and frequency (these are *not* your only backup) |
| API / Terraform provider | lets you automate everything |
| SMTP policy | many providers **block outbound port 25** by default (chapter 05) |
| Support / SLA / abuse handling | read the terms. Some suspend fast on abuse complaints |

## Sizing starting points

| Workload | Start with |
|---|---|
| Static site / small blog | 1 vCPU, 1–2 GB |
| One web app + Postgres + Redis (Docker Compose) | 2 vCPU, 4 GB |
| Several apps / small SaaS | 4 vCPU, 8 GB (or split app and DB servers) |
| Self-hosted mail server | 2 vCPU, 4 GB minimum (spam filtering is RAM-hungry) |

Watch real usage (chapter 08) and resize. Vertical scaling (bigger VPS) is a two-minute reboot
at most providers.

## Pricing traps
- Egress traffic over the included quota, and paid IPv4 addresses.
- Backups/snapshots priced as a % of the server.
- Cheap "unlimited" plans with oversold CPUs.
- Long-term prepay on an unknown provider. Start monthly.

## Exercises
1. Shortlist 3 providers for your region. Compare 4 GB plans on vCPU type, traffic, private
   network, firewall and port-25 policy.
2. Install the provider's CLI (`hcloud`, `doctl`, `linode-cli`, `vultr-cli`) and create and
   destroy a server from it.
