# 06 — Connecting Multiple VPSes

Once there's more than one server, you need: **private connectivity** between them, **one way in**
for admins, **traffic distribution** for users, and **data replication** for the state.

## 1. Choose how servers talk privately

| Method | When | Notes |
|---|---|---|
| **Provider private network / VPC** | all servers at the **same provider + region** | free, fast, no encryption overhead. Still firewall it. Hetzner Networks, DO VPC, Linode VLAN/VPC, Vultr VPC |
| **WireGuard mesh** (hand-rolled) | across providers/regions, a few nodes | kernel-fast, encrypted. [`files/wireguard/wg-mesh-gen.sh`](files/wireguard/wg-mesh-gen.sh) generates the configs |
| **Tailscale** (or self-hosted **Headscale**) / **Netbird** | many nodes, laptops too, NAT traversal, ACLs, SSO | easiest mesh. A coordination server + WireGuard data plane. `tailscale up --ssh` |
| **Nebula** | large overlay networks with a certificate-based identity | from Slack. Self-hosted |
| Site-to-site IPsec | connecting to corporate/cloud VPN gateways | strongSwan/libreswan. Cloud providers speak IPsec |

**Rule:** databases, caches, internal APIs and monitoring listen **only** on private/overlay IPs.
The public interface exposes only the load balancer/reverse proxy (80/443) and maybe SSH.

### WireGuard full mesh in 3 commands
```bash
cd files/wireguard
./wg-mesh-gen.sh "web-01=203.0.113.10" "web-02=198.51.100.20" "db-01=192.0.2.30"   # node=public endpoint
ls out/        # web-01.conf web-02.conf db-01.conf (each one lists the other nodes as peers)
scp out/web-01.conf deploy@203.0.113.10:/tmp/wg0.conf && ssh deploy@203.0.113.10 'sudo install -m600 /tmp/wg0.conf /etc/wireguard/wg0.conf && sudo systemctl enable --now wg-quick@wg0'
# repeat per node, then open UDP 51820 between the nodes in both firewalls; test with: ping 10.210.0.2
```

### Tailscale (fastest)
```bash
curl -fsSL https://tailscale.com/install.sh -o /tmp/ts.sh && sh /tmp/ts.sh
sudo tailscale up --ssh --advertise-tags=tag:server     # authenticate once (or use an auth key)
tailscale status
```
Write **ACLs** (Tailnet policy file) so `tag:web` can reach `tag:db:5432` and nothing else.

## 2. One way in for admins

- **Bastion/jump host**: one hardened VPS with SSH open (ideally only from your IP/VPN). Every
  other server allows SSH only from the bastion's private IP. `ssh -J bastion db-01`.
- Or **no public SSH anywhere**: admins reach servers only over Tailscale/WireGuard (better).
- Log and record admin sessions at scale (Teleport, or auditd + central logs).

## 3. Distributing user traffic

| Pattern | How |
|---|---|
| DNS round-robin | multiple A records. Simple, but there's no health checking (clients may hit dead nodes) |
| **Provider load balancer** | Hetzner LB / DO LB / Linode NodeBalancer, with health checks + TLS. Easiest |
| **Your own LB** | HAProxy/Caddy/Nginx on 1–2 small VPSes ([`files/haproxy/haproxy.cfg`](files/haproxy/haproxy.cfg)). For HA, pair two with keepalived + a floating IP |
| Global / multi-region | Cloudflare Load Balancing, or GeoDNS (Route 53 latency/geo routing) |

```
               ┌──────────────── Cloudflare / DNS ────────────────┐
               ▼                                                    ▼
        [LB fra-01 (HAProxy)]                              [LB nyc-01]          (public 443)
          │      │   private net / WireGuard                 │     │
      [web-01] [web-02]                                   [web-03][web-04]      (app, stateless)
          └──────┴──────────▶ [db-primary] ──replication──▶ [db-replica] ◀──────┘
                              [redis]                        (other region)
```
**Make app servers stateless:** sessions in Redis/DB, uploads in object storage (S3/R2/B2/MinIO),
and config from env/secrets. Then any node can serve any request, and scaling means adding a node.

## 4. Data across servers

| Data | Approach |
|---|---|
| PostgreSQL | streaming replication (primary → replica). Automated failover with **Patroni** + etcd, or a managed DB. Back up the primary with pgBackRest |
| MySQL | replication / Group Replication / Galera (MariaDB) |
| Redis | replica + Sentinel, or Valkey/Redis Cluster |
| Files | object storage (preferred), or a shared NFS/GlusterFS (avoid when you can) |

Database HA is hard. Many teams use **managed databases** (DO/Linode/Aiven/cloud RDS) even when
their app runs on VPSes.

## 5. Orchestrating many VPSes

| Tool | Fit |
|---|---|
| Ansible (Servers ch. 07) | configure every VPS the same way. The baseline for any fleet |
| **Kamal** (ch. 07) | deploy containers to N hosts with zero downtime, no orchestrator |
| **Docker Swarm** | simple multi-node container clustering (`docker swarm init`, overlay networks) |
| **k3s** | lightweight Kubernetes across VPSes (3 servers for HA), run over the private network/WireGuard |
| Nomad | HashiCorp's simpler scheduler |
| Coolify / Dokploy | self-hosted PaaS UI managing several servers |

## Exercises
1. Connect three VPSes at two providers with WireGuard, and run Postgres on one, reachable only over the mesh.
2. Put HAProxy in front of two app servers, take one down, and watch the health checks drain it.
3. Set up a Postgres streaming replica, promote it, and measure how long your app was down.
