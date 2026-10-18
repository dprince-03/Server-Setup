# Servers: Private Servers and Home Labs

For physical machines you own: a single server, a rack in an office, or a home lab with several
nodes. The same practices apply to VMs; the VPS and Cloud sections build on this one.

| # | Chapter | Covers |
|---|---|---|
| 01 | [Fundamentals](01-fundamentals.md) | server roles, hardware, OS choice, IPMI, RAID, how industry thinks about servers |
| 02 | [Single-server setup](02-single-server-setup.md) | install → users → SSH → firewall → updates → time → the baseline checklist |
| 03 | [Security hardening](03-security-hardening.md) | threat model, SSH, fail2ban, MAC, auditing, CIS benchmarks |
| 04 | [Storage and backups](04-storage-backups.md) | RAID/ZFS/LVM, 3-2-1, restic, restore drills |
| 05 | [Networking and the home lab](05-networking-homelab.md) | VLANs, router/firewall, DNS, reverse proxy, VPN, remote access |
| 06 | [Virtualization and containers](06-virtualization-containers.md) | Proxmox clusters, LXC, Docker, k3s |
| 07 | [Managing many servers](07-multi-server-management.md) | inventory, Ansible, config-as-code, secrets, identity |
| 08 | [Monitoring and logging](08-monitoring-logging.md) | Prometheus, Grafana, Loki, alerting, uptime checks |
| 09 | [Operations and runbooks](09-operations-runbooks.md) | maintenance, patching, incidents, postmortems, documentation |

**Files** (`files/`):

| Path | What it is |
|---|---|
| `scripts/bootstrap-server.sh` | idempotent first-boot hardening script (Ubuntu/Debian/Rocky) |
| `configs/sshd/99-hardening.conf` | drop-in SSH hardening |
| `configs/fail2ban/jail.local` | sensible fail2ban jails |
| `configs/sysctl/99-server-hardening.conf` | kernel/network hardening |
| `configs/apt/52unattended-upgrades-local` | security auto-updates config |
| `ansible/` | `ansible.cfg`, example inventory, group vars, `baseline.yml`, `docker.yml`, `patch.yml` playbooks |
| `monitoring/` | Docker Compose stack: Prometheus, Alertmanager, Grafana, Loki, Alloy, node-exporter, Uptime Kuma |
| `backups/` | restic backup script + systemd service/timer + non-secret config example (secrets come from the secret manager) |
| `secrets/stack@.service` | systemd unit that runs any compose stack with secrets injected from the secret manager (no `.env`) |
| `wireguard/` | hub and peer config templates |
| `reverse-proxy/Caddyfile` | internal services behind HTTPS with Caddy |
| `docs/runbook-template.md`, `docs/postmortem-template.md` | ops documentation templates |
