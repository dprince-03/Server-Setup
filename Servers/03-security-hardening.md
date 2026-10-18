# 03 — Security Hardening

## Start with a threat model (5 minutes, saves hours)

Ask: *What am I protecting? From whom? What happens if it's lost, leaked or down?*

| Threat | Typical defence |
|---|---|
| Internet scanners and brute force | key-only SSH, firewall, fail2ban, no exposed admin panels |
| Vulnerable software | patching, minimal packages, containers with least privilege |
| Stolen credentials | MFA on everything (SSO, cloud, registrar, email), short-lived certs/keys |
| Insider / mistake | least privilege, audit logs, backups, change review (Git + PRs) |
| Ransomware / deletion | **immutable / off-site backups**, separate backup credentials |
| Physical theft | disk encryption, locked rack, BIOS password |

## Layers (defence in depth)

1. **Network:** expose nothing by default. Admin access only over a **VPN** (WireGuard/Tailscale)
   or a **bastion**. Segment with VLANs (chapter 05).
2. **Access:** SSH keys (ed25519), ideally on a **hardware key** (`ssh-keygen -t ed25519-sk`),
   or **SSH certificates** from a CA (step-ca, Teleport, Vault, Smallstep) at scale. Central
   identity (FreeIPA/LDAP/SSO) once you have more than a few servers.
3. **OS:** the baseline from chapter 02 + this chapter.
4. **Application:** run services as dedicated users, read-only filesystems where possible, secrets
   outside the code, TLS everywhere.
5. **Detection:** auditd, central logs, alerts on suspicious events (new sudoers, SSH from new
   locations, unexpected listening ports).
6. **Recovery:** backups and rebuild-from-code.

## SSH hardening (what's in `files/configs/sshd/99-hardening.conf`)

- `PermitRootLogin no`, `PasswordAuthentication no`, `KbdInteractiveAuthentication no`
- `AllowGroups ssh-users` (only members can log in), `MaxAuthTries 3`, `LoginGraceTime 20`
- No agent forwarding or X11 forwarding by default
- Modern algorithms only (OpenSSH defaults are already good; don't copy-paste ancient cipher lists)

Use `ssh -J bastion host` (ProxyJump) instead of agent forwarding.

## Mandatory access control

- **AppArmor** (Ubuntu/Debian) or **SELinux** (RHEL family). **Keep it enforcing.** When something
  is blocked, read the denial (`journalctl -k | grep apparmor` / `ausearch -m avc`) and fix the
  policy or labels. Never disable MAC as a "fix".

## Auditing and integrity

```bash
sudo apt install -y auditd lynis aide
sudo lynis audit system                      # hardening score + suggestions
sudo aideinit && sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db   # file integrity baseline
```
Example audit rules (`/etc/audit/rules.d/50-admin.rules`):
```
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers
-w /etc/ssh/sshd_config -p wa -k sshd
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
```
`sudo augenrules --load`. Search with `ausearch -k sudoers`.

## Benchmarks and compliance

- **CIS Benchmarks** (Ubuntu, Debian, RHEL, Docker, Kubernetes) are the industry checklist.
  Ubuntu Pro ships `usg` to apply/audit CIS automatically. OpenSCAP does the same on RHEL.
- **DISA STIG** for government-grade environments.
- Apply a benchmark **in a test VM first**, because some items break workloads.

## Secrets on servers

- **Policy: [`../SECRETS.md`](../SECRETS.md).** No `.env` or plaintext secret files, ever. Values
  live in a **secret manager** (Bitwarden Secrets Manager, Infisical, 1Password, OpenBao/Vault, or a
  cloud secret manager), and **humans type the values themselves**.
- Servers hold only an encrypted machine token (**systemd-creds**, `LoadCredentialEncrypted=`), and
  services get their secrets injected at start ([`files/secrets/stack@.service`](files/secrets/stack@.service)).
- Containers receive secrets as files (`/run/secrets/*`, `*_FILE` variables), not env vars.
- Rotate on staff changes and after any suspected leak. The secret manager's audit log shows who
  read what.

## Container security quick list

Run containers as non-root (`user:`), drop capabilities (`cap_drop: [ALL]`), use read-only root FS
where possible, never mount `/var/run/docker.sock` into untrusted containers, pin image digests in
production, and scan images (Trivy/Grype).

## Exercises
1. Run `lynis` before and after the chapter 02 baseline and compare the scores.
2. Set up a WireGuard-only SSH path (chapter 05) and close port 22 to the internet.
3. Generate a hardware-backed SSH key (`ed25519-sk`) and use it for one server.
