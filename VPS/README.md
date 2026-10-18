# VPS: Virtual Private Servers, Domains, Email and Multi-VPS

From "I rented a VPS" to "my apps run on several VPSes in different regions, with my own domain,
HTTPS, working email, CI/CD deploys, backups and monitoring." Read Servers 02–03 first: every
VPS gets that baseline.

| # | Chapter | Covers |
|---|---|---|
| 01 | [Choosing a VPS](01-choosing-a-vps.md) | providers, sizing, regions, pricing traps, what "managed" means |
| 02 | [First boot and hardening](02-first-boot-hardening.md) | cloud-init, provider firewall, baseline, snapshots |
| 03 | [Domain and DNS](03-domain-dns.md) | registrars, DNS records, nameservers, Cloudflare, TTLs, reverse DNS |
| 04 | [Web server, TLS and deploying apps](04-web-tls-deploy.md) | Caddy/Nginx, Let's Encrypt, Docker Compose stacks, zero-downtime basics |
| 05 | [Email for your domain](05-email.md) | hosted vs transactional vs self-hosted, MX/SPF/DKIM/DMARC/PTR, deliverability |
| 06 | [Connecting multiple VPSes](06-multi-vps-networking.md) | private networks, WireGuard mesh, Tailscale/Headscale, bastions, load balancing, DB replication, clusters |
| 07 | [CI/CD and deployments](07-cicd-deployments.md) | GitHub Actions over SSH, Kamal, Coolify/Dokploy, rollbacks |
| 08 | [Backups, monitoring and scaling](08-backups-monitoring-scaling.md) | provider snapshots vs real backups, uptime, vertical → horizontal scaling, when to move to the cloud |

**Files** (`files/`):

| Path | What it is |
|---|---|
| `cloud-init/user-data.yaml` | paste into the provider's "user data" box. Creates a secure server on first boot |
| `caddy/Caddyfile` | automatic HTTPS reverse proxy for several apps/domains |
| `nginx/app.conf` | Nginx alternative (with certbot) |
| `compose/compose.yaml` | production-style app + Postgres + Redis + Caddy stack. Secrets are injected from the secret manager as `/run/secrets/*` files (no `.env`) |
| `kamal/secrets` | Kamal secrets file that **fetches** from a secret manager (contains no values) |
| `dns/zone.example.txt` | a complete DNS zone (web + email + security records) in BIND format |
| `email/dns-records.example.txt` | the email-authentication record set explained line by line |
| `email/mta-sts.txt` | MTA-STS policy file |
| `wireguard/wg-mesh-gen.sh` | generates full-mesh WireGuard configs for N VPSes |
| `github-actions/deploy-ssh.yml` | build → push image → deploy over SSH, with health check |
| `kamal/deploy.yml` | Kamal 2 deploy config (zero-downtime Docker deploys to any VPS) |
| `haproxy/haproxy.cfg` | load balancer in front of several app VPSes |
