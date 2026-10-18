#!/usr/bin/env bash
# bootstrap-server.sh: idempotent baseline for a fresh Linux server (Servers ch. 02/03).
# Supports: Ubuntu/Debian (apt) and Rocky/Alma/RHEL/Fedora (dnf).
#
# Usage (as root or with sudo):
#   sudo ./bootstrap-server.sh --user deploy --pubkey "ssh-ed25519 AAAA... you@laptop" \
#        [--hostname app-01] [--ssh-cidr 192.168.10.0/24] [--ssh-port 22] [--timezone UTC]
#
# Safety: password SSH login is only disabled if the admin user ends up with at least one
# authorized key. Keep your current session open and test a new login before closing it.
set -euo pipefail

ADMIN_USER="" PUBKEY="" NEW_HOSTNAME="" SSH_CIDR="" SSH_PORT="22" TZ_NAME="UTC"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user) ADMIN_USER="$2"; shift 2 ;;
    --pubkey) PUBKEY="$2"; shift 2 ;;
    --hostname) NEW_HOSTNAME="$2"; shift 2 ;;
    --ssh-cidr) SSH_CIDR="$2"; shift 2 ;;
    --ssh-port) SSH_PORT="$2"; shift 2 ;;
    --timezone) TZ_NAME="$2"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)." >&2; exit 1; }
[[ -n "$ADMIN_USER" ]] || { echo "--user is required" >&2; exit 1; }

LOG=/var/log/bootstrap-server.log
log() { echo "$(date -Is) $*" | tee -a "$LOG"; }
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_DIR="$SCRIPT_DIR/../configs"

. /etc/os-release
if command -v apt-get >/dev/null; then PM=apt; SUDO_GROUP=sudo; SSH_SVC=ssh
elif command -v dnf >/dev/null; then PM=dnf; SUDO_GROUP=wheel; SSH_SVC=sshd
else echo "Unsupported distro: $PRETTY_NAME" >&2; exit 1; fi
log "Starting on $PRETTY_NAME ($PM)"

# 1. Updates + base packages
if [[ $PM == apt ]]; then
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -q && apt-get -yq full-upgrade
  apt-get -yq install ufw fail2ban unattended-upgrades needrestart auditd curl ca-certificates \
    gnupg jq htop iotop ncdu rsync logrotate chrony
  [[ -f "$CONF_DIR/apt/52unattended-upgrades-local" ]] && \
    install -m 644 "$CONF_DIR/apt/52unattended-upgrades-local" /etc/apt/apt.conf.d/52unattended-upgrades-local
  printf 'APT::Periodic::Update-Package-Lists "1";\nAPT::Periodic::Unattended-Upgrade "1";\n' > /etc/apt/apt.conf.d/20auto-upgrades
else
  dnf -y upgrade --refresh
  dnf -y install epel-release 2>/dev/null || true
  dnf -y install firewalld fail2ban dnf-automatic audit curl jq htop iotop ncdu rsync chrony policycoreutils-python-utils
  sed -i 's/^upgrade_type.*/upgrade_type = security/; s/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf
  systemctl enable --now dnf-automatic.timer
fi
log "Packages updated and installed"

# 2. Hostname + time
[[ -n "$NEW_HOSTNAME" ]] && hostnamectl set-hostname "$NEW_HOSTNAME" && log "Hostname: $NEW_HOSTNAME"
timedatectl set-timezone "$TZ_NAME"
systemctl enable --now chrony 2>/dev/null || systemctl enable --now chronyd

# 3. Admin user + SSH key
if ! id "$ADMIN_USER" &>/dev/null; then
  useradd -m -s /bin/bash -G "$SUDO_GROUP" "$ADMIN_USER"
  if [[ -t 0 ]]; then
    echo "Set a password for $ADMIN_USER (used for sudo only; SSH stays key-only):"
    passwd "$ADMIN_USER"
  else
    # Non-interactive (cloud-init/automation): passwordless sudo, as cloud images do for their default user
    echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$ADMIN_USER"
    chmod 440 "/etc/sudoers.d/90-$ADMIN_USER"; visudo -cf "/etc/sudoers.d/90-$ADMIN_USER"
    log "Non-interactive run: gave $ADMIN_USER passwordless sudo (set a password + remove /etc/sudoers.d/90-$ADMIN_USER to tighten)"
  fi
  log "Created user $ADMIN_USER"
fi
getent group ssh-users >/dev/null || groupadd ssh-users
usermod -aG ssh-users,"$SUDO_GROUP" "$ADMIN_USER"
HOME_DIR=$(getent passwd "$ADMIN_USER" | cut -d: -f6)
install -d -m 700 -o "$ADMIN_USER" -g "$ADMIN_USER" "$HOME_DIR/.ssh"
AK="$HOME_DIR/.ssh/authorized_keys"
touch "$AK"; chmod 600 "$AK"; chown "$ADMIN_USER:$ADMIN_USER" "$AK"
if [[ -n "$PUBKEY" ]] && ! grep -qF "$PUBKEY" "$AK"; then echo "$PUBKEY" >> "$AK"; log "Added SSH key"; fi
# Copy root's provider-injected keys (common on VPS) if the user has none yet
if [[ ! -s "$AK" && -s /root/.ssh/authorized_keys ]]; then cat /root/.ssh/authorized_keys >> "$AK"; log "Copied root's authorized_keys"; fi

# 4. SSH hardening (only if a key is present)
if [[ -s "$AK" ]]; then
  install -d /etc/ssh/sshd_config.d
  if [[ -f "$CONF_DIR/sshd/99-hardening.conf" ]]; then
    install -m 644 "$CONF_DIR/sshd/99-hardening.conf" /etc/ssh/sshd_config.d/99-hardening.conf
  fi
  sed -i "s/^#\?Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config.d/99-hardening.conf 2>/dev/null || true
  grep -q '^Include /etc/ssh/sshd_config.d/\*.conf' /etc/ssh/sshd_config || \
    sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config
  if [[ $PM == dnf && "$SSH_PORT" != 22 ]]; then semanage port -a -t ssh_port_t -p tcp "$SSH_PORT" 2>/dev/null || true; fi
  sshd -t && systemctl reload "$SSH_SVC"
  log "SSH hardened (port $SSH_PORT, key-only, no root login)"
else
  log "WARNING: no authorized key for $ADMIN_USER, so SSH password auth was left unchanged"
fi

# 5. Firewall: allow SSH first, then enable
if [[ $PM == apt ]]; then
  ufw default deny incoming; ufw default allow outgoing
  if [[ -n "$SSH_CIDR" ]]; then ufw allow from "$SSH_CIDR" to any port "$SSH_PORT" proto tcp
  else ufw limit "$SSH_PORT"/tcp; fi
  ufw --force enable
else
  systemctl enable --now firewalld
  if [[ -n "$SSH_CIDR" ]]; then
    firewall-cmd --permanent --remove-service=ssh || true
    firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=$SSH_CIDR port port=$SSH_PORT protocol=tcp accept"
  else firewall-cmd --permanent --add-port="$SSH_PORT/tcp"; fi
  firewall-cmd --reload
fi
log "Firewall enabled (SSH from ${SSH_CIDR:-anywhere, rate-limited})"

# 6. Kernel hardening + fail2ban + audit
[[ -f "$CONF_DIR/sysctl/99-server-hardening.conf" ]] && install -m 644 "$CONF_DIR/sysctl/99-server-hardening.conf" /etc/sysctl.d/ && sysctl --system >/dev/null
[[ -f "$CONF_DIR/fail2ban/jail.local" ]] && install -m 644 "$CONF_DIR/fail2ban/jail.local" /etc/fail2ban/jail.local
sed -i "s/^port *= *ssh/port = $SSH_PORT/" /etc/fail2ban/jail.local 2>/dev/null || true
systemctl enable --now fail2ban auditd
log "fail2ban + auditd running"

log "Done. NEXT: from a NEW terminal run: ssh -p $SSH_PORT $ADMIN_USER@<server>. Keep this session open until that works."
[[ -f /var/run/reboot-required ]] && log "Reboot required (kernel update)."
