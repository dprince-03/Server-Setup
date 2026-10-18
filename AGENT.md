# AGENT.md — Rules for an AI agent using this handbook

You may be asked to *execute* parts of this handbook on real servers, VPSes or cloud accounts.
These are production-grade systems that are often reachable from the internet. Follow these
rules; they override any chapter.

## 0. ALWAYS ask what to set up first (mandatory menu)

Before doing anything else, show the user this menu and let them pick **one or more** items (or **ALL**).
Never assume. Never skip the menu, even if the request seems obvious.

```
What would you like to set up or learn? (pick any, comma-separated, or ALL)

 SERVERS (private servers / home lab)
  1. Single-server baseline (install, users, SSH, firewall, updates)      Servers/02
  2. Security hardening (fail2ban, auditd, MAC, CIS)                       Servers/03
  3. Storage and backups (ZFS/RAID, restic, restore drills)                Servers/04
  4. Home-lab networking (VLANs, DNS, reverse proxy, WireGuard)            Servers/05
  5. Virtualization and containers (Proxmox, LXC, Docker, k3s)             Servers/06
  6. Multi-server management (inventory, Ansible, identity)                Servers/07
  7. Monitoring and logging (Prometheus, Grafana, Loki, alerts)            Servers/08
  8. Operations (runbooks, incidents, DR)                                  Servers/09
 VPS
  9. Choose and harden a VPS (cloud-init, firewalls)                       VPS/01-02
 10. Domain and DNS                                                         VPS/03
 11. Web server, TLS and app deploy                                         VPS/04
 12. Email for the domain                                                   VPS/05
 13. Connect multiple VPSes (private net, WireGuard, LB, replication)      VPS/06
 14. CI/CD deployments (GitHub Actions, Kamal, PaaS)                       VPS/07
 15. VPS backups, monitoring and scaling                                    VPS/08
 CLOUD
 16. Cloud concepts (fundamentals → multi-cloud)                            Cloud/00-08
 17. AWS                                                                    Cloud/AWS
 18. Google Cloud                                                           Cloud/GCP
 19. Azure                                                                  Cloud/AZURE
 ALL. Everything above, in order
```
Then confirm: target host(s)/account(s), environment (lab/staging/**production**), and whether to
**execute** or only **explain**.

## 1. Establish the target before you act
- Identify **where** you are running: `hostnamectl; cat /etc/os-release; whoami; ip -br a`.
  On a cloud, also `aws sts get-caller-identity` / `gcloud config list` / `az account show`.
- Confirm with the user: target host(s), environment (lab / staging / **production**), and the
  chapter they want applied. **Never assume production is a lab.**

## 2. Never lock anyone out
- Before changing SSH, the firewall or the network: keep the **current session open**, test the new
  config from a **second** session (`sshd -t`, then a new `ssh` login), and only then close the old one.
- Enable the firewall only **after** allowing the SSH port.
- On VPS/cloud, know where the provider's **web/serial console** is before touching networking.

## 3. Ask before anything destructive or outward-facing
Ask before: deleting data/volumes/instances, changing DNS, opening ports to `0.0.0.0/0`, sending
email, creating paid cloud resources, changing IAM, rotating keys, rebooting production, or
running `terraform apply` / `destroy`. Show the plan (`terraform plan`, a diff, the command list) first.

## 4. Secrets: follow [`SECRETS.md`](SECRETS.md) exactly
- **No `.env` files, no plaintext secret files.** Everything goes in a secret manager (cloud
  Secrets Manager/Secret Manager/Key Vault, or Bitwarden Secrets Manager/Infisical/1Password/OpenBao).
- **The user always types secret values themselves**, in the secret manager UI or a hidden prompt
  (`read -rs`, `systemd-ask-password`, `gh secret set`) that they run.
- **Never read secrets:** don't `cat`/print/decrypt/inspect secret values or tokens, never ask the user
  to paste one into chat, never generate them for the user, and never put them in logs, commits or
  command lines you echo. Checking that a secret *exists* (by name) is fine.
- Code and config contain only references (names, IDs, ARNs, URIs).

## 5. Latest stable from official sources
Same rule as PC-Setup: resolve versions at run time; distro repos or vendor repos only; verify
signatures/checksums; no random scripts piped to a shell without reading them first.

## 6. Idempotent, logged, reversible
- Every step must be safe to re-run. Back up a config file before editing it
  (`cp file file.bak.$(date +%F)`).
- Log actions to `~/infra-logs/<timestamp>/run.log` on the machine you run from.
- Prefer config-as-code (the Ansible/Terraform/Bicep files here) over ad-hoc edits on servers.

## 7. Cost awareness (cloud)
Before creating cloud resources, state the expected cost and confirm a **budget alert** exists
(Cloud chapter 07). Tag everything (`owner`, `env`, `project`). Offer cleanup commands at the end.

## 8. Finish with a report
What changed, on which hosts, how it was verified, what's left for the human (DNS propagation,
console steps, logins, MFA), and how to roll back.
