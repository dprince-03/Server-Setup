# 05 — Networking and the Home Lab (multiple servers)

## Reference home-lab / small-office architecture

```
 Internet
    │
 [ISP modem/ONT] (bridge mode)
    │
 [Router/Firewall: OPNsense / pfSense / MikroTik / UniFi]  ← DHCP, DNS forwarder, VPN (WireGuard), firewall rules
    │  trunk (802.1Q VLANs)
 [Managed switch]
    ├── VLAN 10  MGMT     10.10.10.0/24  hypervisor UIs, IPMI, switch/AP admin   (admins only)
    ├── VLAN 20  SERVERS  10.10.20.0/24  VMs/containers providing services
    ├── VLAN 30  STORAGE  10.10.30.0/24  NAS ↔ hypervisors (jumbo frames, no internet)
    ├── VLAN 40  LAB/DMZ  10.10.40.0/24  anything exposed or experimental
    ├── VLAN 50  TRUSTED  10.10.50.0/24  your laptops/phones
    └── VLAN 60  IOT/GUEST 10.10.60.0/24 TVs, cameras, guests → internet only
```
**Firewall policy between VLANs:** default deny. Allow TRUSTED → SERVERS on service ports,
TRUSTED → MGMT only from admin devices, IOT → internet only, and SERVERS → STORAGE on NFS/SMB.
This is how offices segment networks too ("zero trust" starts here).

## Core network services

| Service | Options | Notes |
|---|---|---|
| Router/firewall | **OPNsense** / pfSense (x86 box or VM), MikroTik, UniFi | dedicated hardware is more resilient than a VM on the hypervisor it protects |
| DNS (internal) | **Pi-hole** / AdGuard Home + Unbound, or **Technitium**, or the router's Unbound | run **two** DNS servers. Use a real domain you own for internal names: `lab.example.com` (**not** `.local`, which belongs to mDNS) |
| DHCP | router, or Kea | reservations for servers |
| NTP | router or chrony on a server | |
| Reverse proxy | **Caddy**, Traefik, Nginx Proxy Manager | one entry point with TLS for all web UIs ([`files/reverse-proxy/Caddyfile`](files/reverse-proxy/Caddyfile)) |
| Certificates | Let's Encrypt **DNS-01** challenge (works for internal-only names), or an internal CA (step-ca) | DNS-01 needs an API token for your DNS provider |
| VPN / remote access | **WireGuard** (on the router), **Tailscale/Headscale**, Netbird | never port-forward admin UIs to the internet |
| Exposing services publicly | **Cloudflare Tunnel**, Tailscale Funnel, or a VPS reverse proxy over WireGuard | hides your home IP, and works behind CGNAT |

## WireGuard (hub-and-spoke)

Templates: [`files/wireguard/wg0-hub.conf.example`](files/wireguard/wg0-hub.conf.example) and
[`files/wireguard/wg0-peer.conf.example`](files/wireguard/wg0-peer.conf.example).
```bash
sudo apt install -y wireguard
wg genkey | tee privatekey | wg pubkey > publickey     # per node; chmod 600 privatekey
sudo install -m 600 wg0.conf /etc/wireguard/wg0.conf
sudo systemctl enable --now wg-quick@wg0
sudo wg show
```
For many nodes, use a mesh manager (**Tailscale/Headscale**, Netbird, or Nebula) instead of
hand-written configs. See VPS chapter 06.

## Internal DNS naming

- `pve-01.mgmt.lab.example.com`, `grafana.lab.example.com` → reverse-proxy IP
- Split-horizon: inside, names resolve to private IPs. Publicly, only what you deliberately expose
  exists.

## Remote access done right

1. VPN into the lab (WireGuard/Tailscale) → then SSH/HTTPS to internal names.
2. A bastion/jump host for SSH if VPN isn't possible: `ssh -J bastion.example.com db-01`.
3. Identity-aware access (Cloudflare Access, Tailscale ACLs, Teleport, Pomerium) for web apps.

## Exercises
1. Draw your network with VLANs and write the inter-VLAN firewall table.
2. Get a Let's Encrypt wildcard certificate for `*.lab.example.com` via DNS-01 with Caddy.
3. Reach your lab from your phone over WireGuard with **no** inbound ports except WireGuard's UDP port.
