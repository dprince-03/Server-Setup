# 06 — Virtualization and Containers

## Why virtualize?

One physical box becomes many isolated servers: one role per VM/container, snapshots before
changes, easy rebuilds, and live migration between hosts. This is how both data centres and home
labs run.

| Layer | Tool | Use |
|---|---|---|
| Hypervisor (type 1) | **Proxmox VE** (KVM + LXC, free, web UI, clustering, ZFS/Ceph) | home labs and SMBs. The industry alternatives are VMware vSphere (expensive since Broadcom), Hyper-V, XCP-ng, Nutanix |
| System containers | **LXC** (in Proxmox), Incus | lightweight "VMs" for Linux services |
| App containers | **Docker** / Podman + Compose | packaging and running applications |
| Orchestration | **k3s** / Talos / kubeadm, Docker Swarm (simple) | many containers across many nodes |

## Proxmox VE: single node → cluster

Install from the official ISO (newest release). Afterwards:
```bash
# On the Proxmox host (Debian-based)
# 1. Repos: use the no-subscription repo for labs (or buy a subscription for production support)
#    via the GUI: Node → Updates → Repositories. Then:
apt update && apt full-upgrade -y
# 2. Storage: a ZFS mirror for VMs (local-zfs), plus NFS/SMB from the NAS for ISOs and backups
# 3. Networking: a Linux bridge vmbr0 that's VLAN-aware (tag VMs into the VLANs from chapter 05)
```

**VM templates (the professional way to create servers):**
```bash
# Ubuntu cloud image → template with cloud-init (the same mechanism VPS providers use)
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img   # use the newest LTS codename
qm create 9000 --name ubuntu-tpl --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 noble-server-cloudimg-amd64.img local-zfs
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-9000-disk-0 --ide2 local-zfs:cloudinit \
  --boot order=scsi0 --serial0 socket --vga serial0 --agent enabled=1
qm template 9000
qm clone 9000 101 --name app-01 --full && qm set 101 --ipconfig0 ip=10.10.20.11/24,gw=10.10.20.1 --sshkeys ~/.ssh/id_ed25519.pub
qm start 101
```
Automate this with **Terraform (bpg/proxmox provider)** or Ansible once you're comfortable.

**Clustering (3+ nodes):**
- `pvecm create lab` on node 1, then `pvecm add <node1-ip>` on the others. Quorum needs an **odd**
  number of votes. With 2 nodes, add a QDevice (a tiny vote-only box).
- Shared or replicated storage enables HA/live migration: **Ceph** (3+ nodes, 10 GbE), ZFS
  replication (cheap, async), or NFS from a NAS.
- Back up everything with **Proxmox Backup Server** (a separate machine, or at least separate disks).

## Docker on servers

Install from Docker's official repo (see PC-Setup `Linux/Ubuntu/09-devops-cloud.md`, or
[`files/ansible/playbooks/docker.yml`](files/ansible/playbooks/docker.yml)). Conventions:
- One directory per stack (`/opt/stacks/<app>/compose.yaml`), kept in Git, and **no `.env` files**.
  Run it as `stack@<app>.service` ([`files/secrets/stack@.service`](files/secrets/stack@.service)),
  which injects secrets from the secret manager ([`../SECRETS.md`](../SECRETS.md)).
- Bind services to `127.0.0.1` or an internal network. Expose only the reverse proxy.
- Docker-published ports **bypass UFW**. Firewall with `DOCKER-USER` chain rules, or don't publish.
- Updates: pull + recreate in a maintenance window (or Renovate/Diun notifications). Avoid
  unattended Watchtower on anything important.

## Kubernetes in the lab (k3s)

```bash
# server (control plane)
curl -sfL https://get.k3s.io -o /tmp/k3s.sh && sudo sh /tmp/k3s.sh
sudo cat /var/lib/rancher/k3s/server/node-token
# agents
curl -sfL https://get.k3s.io -o /tmp/k3s.sh && sudo K3S_URL=https://10.10.20.10:6443 K3S_TOKEN=<token> sh /tmp/k3s.sh
```
Use 3 control-plane nodes (embedded etcd) for HA. Learn GitOps with **Argo CD** or **Flux**: the
cluster state lives in Git, and that's how industry teams run Kubernetes.

## When to use which

| Need | Choose |
|---|---|
| A service with a few containers | Docker Compose on one VM |
| Different OS / kernel / Windows | VM |
| Many Linux services, low overhead | LXC |
| Many apps, self-healing, scaling, multi-node | Kubernetes (k3s) |
| Learning cloud-native careers | Kubernetes + GitOps |

## Exercises
1. Build a Proxmox cloud-init template and clone three VMs from it in under 5 minutes.
2. Form a 3-node Proxmox cluster (nested virtualization works for learning) and live-migrate a VM.
3. Install k3s on three VMs and deploy an app with Argo CD from a Git repo.
