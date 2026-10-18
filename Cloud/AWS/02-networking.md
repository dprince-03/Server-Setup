# AWS 02 — Networking

## VPC per environment (the starter does this)

- `/16` per VPC, 2–3 AZs, with **public / private / database** subnets per AZ
  ([`files/terraform/web-app/main.tf`](files/terraform/web-app/main.tf) uses the community
  `terraform-aws-modules/vpc` module).
- **NAT Gateway:** one per AZ in prod (HA), a single one in dev to save money. Each NAT Gateway
  costs per hour **plus per GB**.
- **VPC endpoints:** gateway endpoints for S3 and DynamoDB (free), and interface endpoints for ECR,
  Secrets Manager, CloudWatch Logs and SSM, so private workloads don't need NAT for AWS APIs.
- **VPC Flow Logs** → CloudWatch/S3 for forensics.
- IPv6: dual-stack VPCs avoid paying for public IPv4 addresses (AWS charges for every public IPv4).

## Security groups as identity

```
alb-sg:  443 from 0.0.0.0/0 (and ::/0)
app-sg:  container port from alb-sg only
db-sg:   5432 from app-sg only
```
Reference SGs, not CIDRs. NACLs stay at the defaults unless you need explicit subnet-level denies.

## Multi-VPC and hybrid

| Need | Use |
|---|---|
| Hub-and-spoke for many VPCs/accounts | **Transit Gateway** in the Network account, shared via RAM; centralised egress/inspection VPC |
| Global WAN across regions | AWS Cloud WAN |
| Office/home lab | Site-to-Site VPN (to TGW or a VGW); Client VPN for users |
| Data centre | Direct Connect (+ VPN as backup) |
| Expose a service to other VPCs/accounts privately | PrivateLink (endpoint services); VPC Lattice for service-to-service |
| Share subnets with app accounts | VPC sharing via RAM |

## DNS: Route 53

Public hosted zones for internet names; **alias records** to ALB/CloudFront (free, apex-capable);
health checks + failover/latency/geolocation routing; private hosted zones for internal names;
Resolver endpoints for hybrid DNS. Turn on DNSSEC signing for public zones.

## Load balancers and edge

| | Use |
|---|---|
| ALB | HTTP/HTTPS, path/host routing, OIDC/Cognito auth, WAF integration, gRPC |
| NLB | TCP/UDP/TLS, static IPs, PrivateLink, extreme throughput |
| CloudFront | CDN + TLS at the edge + origin shielding; put it in front of ALB/S3 even for APIs |
| AWS WAF | managed rule groups (Core, Known Bad Inputs, IP reputation, Bot Control) on CloudFront/ALB/API Gateway |
| Shield | Standard is automatic. Advanced is for high-risk targets (cost + DDoS response team) |

Certificates: **ACM**, free, with auto-renewal (CloudFront needs the cert in `us-east-1`).
