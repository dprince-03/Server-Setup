# 03 — Cloud Networking

## VPC/VNet design (the standard 3-tier layout)

```
VPC 10.20.0.0/16 (per environment, non-overlapping with on-prem/other VPCs)
├── Public subnets   (one per AZ)  → load balancers, NAT gateways, bastion (if any)
├── Private subnets  (one per AZ)  → app containers/VMs (outbound via NAT, no public IPs)
└── Data subnets     (one per AZ)  → databases/caches (no internet route at all)
```
- **Plan CIDRs company-wide** (an IPAM: AWS VPC IPAM, NetBox, a spreadsheet). Overlapping ranges
  block peering and VPNs later.
- Leave room: a /16 per VPC with /20–/24 subnets is common. GCP VPCs are **global** with regional
  subnets. Azure VNets are regional.
- **Nothing in private/data subnets gets a public IP.** Inbound traffic arrives only through load balancers.
- Egress: NAT gateway (AWS/GCP Cloud NAT/Azure NAT Gateway). Don't rely on Azure's default outbound
  access, which is being retired. Use an explicit NAT Gateway.
- **Private access to cloud services:** S3/DynamoDB gateway endpoints and interface endpoints
  (AWS), Private Google Access / Private Service Connect (GCP), Private Endpoints (Azure). Traffic
  stays off the internet, and you save NAT costs.

## Firewalling

| AWS | GCP | Azure |
|---|---|---|
| Security groups (stateful, per ENI; reference other SGs) + NACLs (stateless, per subnet) | VPC firewall rules / network firewall policies (by tag or service account) | NSGs (subnet/NIC) + Azure Firewall + ASGs |

Pattern: LB SG allows 443 from the internet → app SG allows the app port **only from the LB SG** →
DB SG allows 5432 **only from the app SG**. Reference identities and groups, not IP lists.

## Connecting networks

| Need | AWS | GCP | Azure |
|---|---|---|---|
| VPC ↔ VPC (few) | VPC peering | VPC Network Peering | VNet peering |
| Many VPCs (hub-and-spoke) | **Transit Gateway** / Cloud WAN | Network Connectivity Center / Shared VPC | **Hub VNet** / Virtual WAN |
| Office/on-prem (internet) | Site-to-Site VPN | HA VPN | VPN Gateway |
| Dedicated link | Direct Connect | Cloud Interconnect | ExpressRoute |
| Expose a service privately to other orgs | PrivateLink | Private Service Connect | Private Link Service |

**Shared VPC (GCP) / a networking account with RAM sharing (AWS) / a hub VNet (Azure):** a central
network team owns the networking, and app teams deploy into shared subnets. That's how enterprises
run it.

## Load balancing and edge

| Layer | Use |
|---|---|
| L7 HTTP(S) | ALB / Google external Application LB / Application Gateway or Front Door: TLS, path routing, WAF |
| L4 TCP/UDP | NLB / Network LB / Azure Load Balancer: non-HTTP, static IPs, extreme throughput |
| Global anycast | CloudFront + Global Accelerator / Google global LB (anycast built in) / Front Door |
| WAF + DDoS | AWS WAF + Shield / Cloud Armor / Azure WAF + DDoS Protection |

Certificates come from ACM / Google-managed certs / Key Vault or App Service certificates. They auto-renew.

## DNS

Public zones (Route 53 / Cloud DNS / Azure DNS) for internet names, and **private zones** for
internal service discovery. Hybrid DNS resolvers (Route 53 Resolver endpoints, Cloud DNS
forwarding, Azure DNS Private Resolver) connect on-prem DNS.

## Exercises
1. Design CIDRs for dev/stg/prod VPCs in two regions plus an office network, with no overlaps.
2. Build the 3-tier VPC with Terraform (AWS starter in `AWS/files/terraform/web-app`), and prove
   the DB has no route to the internet.
3. Replace the NAT path to object storage with a private endpoint, and measure the NAT bytes before and after.
