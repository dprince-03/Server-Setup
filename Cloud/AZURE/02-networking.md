# Azure 02 — Networking

## Hub-and-spoke (or Virtual WAN)

```
Hub VNet (sub-connectivity) 10.100.0.0/22
  ├── AzureFirewallSubnet  → Azure Firewall (egress filtering, east-west inspection)
  ├── GatewaySubnet        → VPN / ExpressRoute gateway
  ├── AzureBastionSubnet   → Azure Bastion (RDP/SSH from the browser, no public IPs on VMs)
  └── DNS Private Resolver
        ▲ peering                          ▲ peering
Spoke VNet app-a-prod 10.110.0.0/20      Spoke VNet app-b-prod 10.111.0.0/20
  ├── snet-app (delegated to Container Apps / App Service VNet integration)
  ├── snet-data → Private Endpoints (SQL, Storage, Key Vault, Redis)
  └── NSGs + route table (0.0.0.0/0 → Azure Firewall)
```
**Virtual WAN** is the managed alternative for many regions/branches.

## Key practices

- **Private Endpoints + Private DNS zones** (`privatelink.database.windows.net` etc., linked to the hub)
  for every PaaS data service, with **public network access disabled**.
- **Explicit outbound:** NAT Gateway or Azure Firewall. Default outbound access for VMs is being
  retired (new VNets get private subnets by default), so don't depend on it.
- NSGs on subnets + **Application Security Groups** for role-based rules. NSG flow logs / VNet flow
  logs → Traffic Analytics.
- Plan the address space centrally (Azure Virtual Network Manager IPAM can help).

## Ingress and edge

| Need | Use |
|---|---|
| Global HTTP(S), CDN, WAF, anycast | **Azure Front Door** (Standard/Premium; Premium supports Private Link to origins) |
| Regional L7 + WAF inside the VNet | **Application Gateway** (WAF v2), also as AKS ingress (Application Gateway for Containers) |
| L4 | Azure Load Balancer (Standard) |
| DDoS | DDoS Network/IP Protection for public IPs |
| DNS | Azure DNS public zones; Private DNS zones; DNS Private Resolver for hybrid |

## Hybrid

VPN Gateway (site-to-site, point-to-site) → ExpressRoute (private circuit) → Virtual WAN for global
transit. **Azure Arc** extends management (Policy, Defender, Update Manager) to on-prem/home-lab servers.
