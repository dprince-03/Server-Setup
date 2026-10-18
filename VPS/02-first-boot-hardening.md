# 02 — First Boot and Hardening

## Option A (best): secure from the first second with cloud-init

When creating the server:
1. Choose the newest **Ubuntu LTS** or **Debian stable** image.
2. Add **your SSH public key** in the provider UI (never use password login).
3. Paste [`files/cloud-init/user-data.yaml`](files/cloud-init/user-data.yaml) into **User data**
   (edit the username and key first). It creates the admin user, disables root and password SSH,
   enables the firewall, fail2ban and automatic security updates, and installs Docker.
4. Attach the provider's **cloud firewall**: inbound 22 (from your IP/VPN only, if possible), 80
   and 443. Everything else is denied.
5. Enable a **private network** if you'll run more than one server (chapter 06).

Check progress after boot: `ssh deploy@IP 'cloud-init status --wait; sudo tail -n 50 /var/log/cloud-init-output.log'`

## Option B: an existing server

```bash
scp -r ../Servers/files root@IP:/root/server-files
ssh -t root@IP "bash /root/server-files/scripts/bootstrap-server.sh --user deploy --pubkey '$(cat ~/.ssh/id_ed25519.pub)' --hostname web-01"
# NEW terminal, before closing the root session:
ssh deploy@IP
```

## Two firewalls (defence in depth)

| Layer | Example | Why |
|---|---|---|
| Provider cloud firewall | Hetzner Firewall / DO Cloud Firewall / AWS SG | filters before traffic reaches the VM. It survives OS mistakes, and Docker can't bypass it |
| Host firewall | ufw / nftables | protects inside private networks, and the policy lives in code |

**Docker gotcha:** `ports: "8080:8080"` publishes past UFW. Publish app ports on `127.0.0.1` only,
and let the reverse proxy be the only thing on 80/443.

## SSH config on your laptop (`~/.ssh/config`)

```
Host web-01
  HostName 203.0.113.10
  User deploy
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes

Host db-01
  HostName 10.0.0.3          # private IP
  User deploy
  ProxyJump web-01           # or a dedicated bastion
```

## Snapshot after baseline

Take a provider snapshot named `baseline-YYYY-MM-DD`. It's a quick rollback point, *not* a backup
strategy (chapter 08).

## Checklist
- [ ] Key-only SSH as a non-root user; root login disabled
- [ ] Cloud firewall + host firewall; only 22 (restricted), 80 and 443 open
- [ ] Automatic security updates on; the timezone is UTC; the hostname is set
- [ ] Reverse DNS (PTR) set to the hostname (required for mail, nice for everything else)
- [ ] Monitoring agent + uptime check added (chapter 08)
