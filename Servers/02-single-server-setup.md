# 02 — Setting Up a Single Server (the baseline)

This is the baseline **every** server gets: physical, VM, VPS or cloud instance. Automated
version: [`files/scripts/bootstrap-server.sh`](files/scripts/bootstrap-server.sh). Fleet version:
[`files/ansible/playbooks/baseline.yml`](files/ansible/playbooks/baseline.yml).

## Step 1 — Install the OS

- Download the newest **LTS** ISO from the official site and **verify the checksum**
  (`sha256sum -c SHA256SUMS`, and the GPG signature of SHA256SUMS).
- Installer choices: minimal install, **OpenSSH server = yes**, LVM (Ubuntu) so you can grow
  volumes later, encrypted disk (LUKS) if the server holds sensitive data and someone can type
  or remotely provide the passphrase at boot (look at Clevis/Tang for unattended unlock).
- Use a static IP, or a DHCP reservation on your router.

## Step 2 — Users and sudo

```bash
adduser deploy                       # a named admin user, never shared
usermod -aG sudo deploy              # Debian/Ubuntu (RHEL family: wheel)
```
Rules: **no shared accounts**, **no direct root login**, one account per human, service
accounts with no login shell (`useradd -r -s /usr/sbin/nologin svc-app`).

## Step 3 — SSH keys, then lock down SSH

On your workstation:
```bash
ssh-keygen -t ed25519 -C "you@workstation"
ssh-copy-id deploy@server
ssh deploy@server        # must work with the key BEFORE you disable passwords
```
On the server, drop in [`files/configs/sshd/99-hardening.conf`](files/configs/sshd/99-hardening.conf):
```bash
sudo install -m 644 99-hardening.conf /etc/ssh/sshd_config.d/99-hardening.conf
sudo sshd -t && sudo systemctl reload ssh      # (RHEL: sshd)
# Test a NEW session before closing the current one!
```
Changing the SSH port isn't real security, but it does cut log noise. Key-only auth is what matters.

## Step 4 — Firewall (default deny inbound)

```bash
sudo apt install -y ufw
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow from 192.168.10.0/24 to any port 22 proto tcp   # SSH only from your admin network if you can
sudo ufw enable && sudo ufw status verbose
```
RHEL family: `firewalld` (`firewall-cmd --permanent --add-service=ssh`). On many hosts, prefer
plain **nftables** rules managed by Ansible.

## Step 5 — Updates

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y unattended-upgrades needrestart
sudo install -m 644 files/configs/apt/52unattended-upgrades-local /etc/apt/apt.conf.d/
```
Policy used by most teams: **security updates automatically, everything else in a scheduled
maintenance window**, with reboots planned (chapter 09). RHEL: `dnf-automatic` with
`upgrade_type = security`.

## Step 6 — Time, hostname, locale

```bash
sudo hostnamectl set-hostname app-01
sudo timedatectl set-timezone UTC        # servers run UTC; convert at display time
timedatectl status                       # "System clock synchronized: yes" (systemd-timesyncd or chrony)
```
Correct time is required for TLS, Kerberos, TOTP, log correlation and databases.

## Step 7 — Kernel and network hardening

Install [`files/configs/sysctl/99-server-hardening.conf`](files/configs/sysctl/99-server-hardening.conf)
→ `sudo sysctl --system`.

## Step 8 — Intrusion prevention, auditing, basics

```bash
sudo apt install -y fail2ban auditd rsyslog logrotate htop iotop ncdu curl jq
sudo install -m 644 files/configs/fail2ban/jail.local /etc/fail2ban/jail.local && sudo systemctl enable --now fail2ban
```

## Step 9 — Monitoring and backups from day one

- Install `prometheus-node-exporter` (or Grafana Alloy) and register the server in your
  monitoring (chapter 08).
- Add the server to the backup schedule (chapter 04) **before** it holds data.

## Baseline checklist (copy this into your runbook)

- [ ] OS is LTS, fully patched, and has automatic security updates
- [ ] Named admin user with sudo; root login disabled; password SSH disabled
- [ ] Firewall: default deny inbound; only the required ports open, sources restricted
- [ ] Time in sync (UTC); hostname + DNS record set
- [ ] fail2ban and auditd running; logs forwarded centrally (chapter 08)
- [ ] Monitored (metrics + uptime + disk-space alert)
- [ ] Backed up, **with a tested restore**
- [ ] Entered in the inventory (chapter 07) and documented

## Exercises
1. Run `bootstrap-server.sh` in a fresh VM, then audit it with `sudo lynis audit system`.
2. Break SSH on purpose in a VM (bad config) and recover through the console. That's why you test
   from a second session.
