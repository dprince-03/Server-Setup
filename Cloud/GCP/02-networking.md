# GCP 02 — Networking

## What's different on GCP

- **VPCs are global.** Subnets are regional. One VPC can span every region with private routing
  between them, with no peering needed.
- **Shared VPC:** a host project (owned by the network team) shares subnets with service
  projects (app teams). That's the enterprise standard.
- **Firewall rules target network tags or service accounts.** Prefer service accounts, since they're
  identity-based. Hierarchical firewall policies apply at the org/folder level.

## Baseline design

```
Host project: net-prod                     Host project: net-nonprod
  VPC prod (custom mode, no default network)
    subnet europe-west1  10.30.0.0/20  (+ secondary ranges for GKE pods/services)
    subnet us-central1   10.30.16.0/20
  Cloud Router + Cloud NAT per region (egress for private workloads)
  Private Google Access ON (reach Google APIs without public IPs)
  Private Service Connect / Private Services Access (Cloud SQL, AlloyDB, Memorystore private IPs)
```
- Delete the auto-created `default` network (and block it with the `compute.skipDefaultNetworkCreation` org policy).
- Use **VPC Service Controls** perimeters around sensitive data projects (BigQuery/GCS exfiltration
  protection).
- **Serverless → VPC:** Cloud Run uses *Direct VPC egress* to reach private IPs (Cloud SQL private
  IP, Memorystore, internal services).

## Load balancing and edge

| Need | Use |
|---|---|
| Global HTTP(S), one anycast IP, CDN | **Global external Application Load Balancer** + Cloud CDN + Google-managed certs |
| WAF / DDoS / bot protection | **Cloud Armor** policies on the LB (OWASP preconfigured rules, rate limiting) |
| Regional / internal HTTP | regional or internal Application LB |
| TCP/UDP | Network LB (passthrough or proxy) |
| Identity-aware access to internal apps | **IAP** (Identity-Aware Proxy): no VPN needed for admin tools, and SSH to VMs without public IPs (`gcloud compute ssh --tunnel-through-iap`) |

Cloud Run services can sit behind the global LB with serverless NEGs (for a custom domain plus
Cloud Armor + CDN), or use Cloud Run's built-in URL / domain mapping for simple cases.

## Hybrid

HA VPN (99.99 % SLA with two tunnels) → Cloud Interconnect (Dedicated/Partner) → Network
Connectivity Center for hub-and-spoke. Use Cloud DNS forwarding/peering zones for hybrid name resolution.
