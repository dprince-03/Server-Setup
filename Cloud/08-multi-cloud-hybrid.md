# 08 — Multi-Cloud and Hybrid

## When multi-cloud is worth it

| Good reasons | Weak reasons |
|---|---|
| Regulators/customers require a specific provider or residency | "Avoid lock-in" with no concrete exit plan |
| Best-of-breed service (BigQuery analytics + AWS apps; Azure for Microsoft 365/Entra integration) | Hoping for a cheaper bill (egress and duplicated tooling usually cost more) |
| An acquisition brought in another cloud | Running the same app actively on two clouds "for resilience" (multi-region on one cloud is usually enough) |
| Edge/on-prem data must stay local (hybrid) | |

Most companies are "**multi-cloud by accident**". The goal is to **govern** that, not to make every
app portable.

## How to do it well

- **One identity plane:** a single IdP with SSO into every cloud. Workload identity federation across
  clouds (AWS ↔ GCP ↔ Azure all support OIDC federation, so no keys get swapped).
- **One IaC and pipeline standard:** Terraform/OpenTofu + the same CI patterns and policies everywhere.
- **Portable runtime where it matters:** containers + Kubernetes (EKS/GKE/AKS), with Helm/Argo CD the
  same everywhere. Use each cloud's managed DBs behind a clear interface.
- **Central observability and security:** OpenTelemetry → one backend; CSPM/SIEM covering all clouds.
- **Network:** private interconnects/VPNs between clouds, non-overlapping IPAM, centralised DNS.
- **Unified cost view:** FOCUS-format billing exports into one dashboard.

## Hybrid (cloud + your own servers)

| Need | Options |
|---|---|
| Manage on-prem servers from the cloud | **Azure Arc**, AWS Systems Manager (hybrid activations), Google Distributed Cloud / GKE Enterprise |
| Run cloud services on-prem | AWS Outposts, Azure Local (formerly Azure Stack HCI), Google Distributed Cloud |
| Connect | Site-to-site VPN → Direct Connect / ExpressRoute / Interconnect |
| Burst / DR to the cloud | replicate VMs (AWS Elastic Disaster Recovery, Azure Site Recovery), or back up to cloud object storage |
| Home lab ↔ cloud | WireGuard/Tailscale to a small cloud VM, or the provider's VPN gateway (Servers ch. 05) |

## Exercises
1. Federate GitHub Actions into all three clouds from one repo, with no stored keys.
2. Connect your home lab (Servers section) to a cloud VPC over WireGuard, and reach a private database from it.
