#!/usr/bin/env bash
# wg-mesh-gen.sh: generate a full-mesh WireGuard config for N servers.
# Usage: ./wg-mesh-gen.sh "web-01=203.0.113.10" "web-02=198.51.100.20" "db-01=192.0.2.30"
# Output: ./out/<name>.conf (install as /etc/wireguard/wg0.conf, mode 600) + ./out/keys/ (KEEP PRIVATE)
# Mesh subnet: 10.210.0.0/24 (node N gets 10.210.0.N in argument order). Port: UDP 51820.
# Open UDP 51820 between the nodes' public IPs in BOTH the cloud and host firewalls.
set -euo pipefail
command -v wg >/dev/null || { echo "Install wireguard-tools first" >&2; exit 1; }
[[ $# -ge 2 ]] || { sed -n '2,6p' "$0"; exit 1; }

SUBNET=${SUBNET:-10.210.0}
PORT=${PORT:-51820}
OUT=${OUT:-out}
umask 077
mkdir -p "$OUT/keys"

names=(); endpoints=()
for arg in "$@"; do names+=("${arg%%=*}"); endpoints+=("${arg#*=}"); done

for n in "${names[@]}"; do
  [[ -f "$OUT/keys/$n.key" ]] || wg genkey > "$OUT/keys/$n.key"
  wg pubkey < "$OUT/keys/$n.key" > "$OUT/keys/$n.pub"
done

for i in "${!names[@]}"; do
  me=${names[$i]}; f="$OUT/$me.conf"
  {
    echo "# $me: generated $(date -Is)"
    echo "[Interface]"
    echo "Address = $SUBNET.$((i+1))/24"
    echo "ListenPort = $PORT"
    echo "PrivateKey = $(cat "$OUT/keys/$me.key")"
    for j in "${!names[@]}"; do
      [[ $i == "$j" ]] && continue
      echo
      echo "[Peer]"
      echo "# ${names[$j]}"
      echo "PublicKey = $(cat "$OUT/keys/${names[$j]}.pub")"
      echo "Endpoint = ${endpoints[$j]}:$PORT"
      echo "AllowedIPs = $SUBNET.$((j+1))/32"
      echo "PersistentKeepalive = 25"
    done
  } > "$f"
  echo "wrote $f  ($me = $SUBNET.$((i+1)))"
done
echo "Private keys are in $OUT/keys/. Delete local copies after deploying, or store them in your secret manager."
