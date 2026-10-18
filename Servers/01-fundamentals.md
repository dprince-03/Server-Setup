# 01 — Server Fundamentals

## What makes a machine a "server"?

A server is defined by its **role**, not its hardware: it provides a service to other machines and
is expected to be **available, secure and recoverable**. Typical roles:

| Role | Examples |
|---|---|
| Compute / app | web apps, APIs, workers, CI runners |
| Data | PostgreSQL, MySQL, MongoDB, Redis, object storage (MinIO) |
| Storage | NAS / file shares (NFS, SMB), backup targets |
| Network | router/firewall, DNS, DHCP, VPN, reverse proxy, load balancer |
| Platform | hypervisor (Proxmox), container hosts, Kubernetes nodes |
| Ops | monitoring, logging, identity (LDAP/SSO), secrets, bastion/jump host |

**Industry rule:** one role per server (or VM/container). Mixing a database, a reverse proxy and a
build runner on one OS makes patching, scaling and incident response painful. In a home lab you
get the same separation cheaply with **VMs/containers on a hypervisor** (chapter 06).

## Hardware: what actually matters

| Component | Guidance |
|---|---|
| CPU | Cores > clock speed for virtualization. Check for **VT-x/AMD-V** and **VT-d/IOMMU** (PCI passthrough). Low-power chips (Intel N-series, Ryzen mobile) make great 24/7 home-lab nodes |
| RAM | The usual bottleneck. Hypervisors want 32–128 GB. **ECC** for storage servers (ZFS) when you can |
| Disks | Boot on SSD. Data on **mirrored** SSDs/HDDs. Use NAS/enterprise HDDs (CMR, not SMR) for arrays. NVMe for VM storage |
| Network | 1 GbE minimum, 2.5/10 GbE for storage and clusters. **Two NICs** let you separate management from data |
| Out-of-band | **IPMI / iDRAC / iLO / AMT** or a cheap IP-KVM (PiKVM/JetKVM) lets you fix a server that won't boot without being in the room |
| Power | A **UPS** with USB/network shutdown signalling (NUT). Measure idle watts, because 24/7 running costs add up |

Used enterprise gear (Dell R-series, HP DL-series, Lenovo ThinkSystem) is cheap but loud and
power-hungry. Mini PCs and SFF desktops are the modern home-lab sweet spot.

## Choosing the OS

| OS | Use it for | Notes |
|---|---|---|
| **Ubuntu Server LTS** | general purpose, most tutorials, cloud parity | 5 years of standard support (more with Ubuntu Pro) |
| **Debian stable** | minimal, very stable servers | base of Proxmox |
| **Rocky / AlmaLinux** | RHEL-compatible environments, enterprise skills | SELinux on by default, 10-year lifecycle |
| **Proxmox VE** | the hypervisor host itself | Debian-based. Run workloads in VMs/LXC on top |
| **TrueNAS / Unraid** | NAS-first boxes | ZFS (TrueNAS) or flexible arrays (Unraid) |
| Fedora CoreOS / Talos / Flatcar | immutable container/Kubernetes hosts | configured declaratively, auto-updating |

**Pick LTS releases for servers.** Industry teams standardise on one or two OS families so
automation, hardening baselines and skills carry across machines.

## Disk layout and RAID basics

| Level | Disks | Survives | Use |
|---|---|---|---|
| RAID 1 / mirror | 2+ | n-1 disk failures | boot, databases, small servers |
| RAID 10 / striped mirrors | 4+ | one per mirror | databases, VM storage (fast + safe) |
| RAID 5 / RAIDZ1 | 3+ | 1 disk | avoid for big HDDs (long rebuilds risk a 2nd failure) |
| RAID 6 / RAIDZ2 | 4+ | 2 disks | bulk storage / NAS |

**RAID is not a backup.** It protects against disk failure, not against deletion, ransomware,
corruption or fire. That's chapter 04.

## Server lifecycle (how industry frames it)

```
Plan → Provision → Configure → Deploy → Operate (monitor, patch, back up) → Decommission
```
- **Provision:** OS installed, network and storage set up. Automate with PXE, cloud-init, or
  Proxmox templates.
- **Configure:** the hardening baseline + role config, done with **code** (Ansible, chapter 07).
- **Operate:** monitoring, patching windows, backup verification, capacity reviews.
- **Decommission:** wipe disks (`blkdiscard`/`shred`/`nvme format`), remove DNS records, keys and
  monitoring entries.

## Naming and addressing

- Hostnames describe the role and location, never people: `pve-01`, `db-01.lab`, `nas-01`,
  `fw-01`. Avoid pet names at scale.
- Give each server a **static IP** (or a DHCP reservation) and a **DNS record**. Write it down in
  an inventory (chapter 07).

## Exercises
1. Write a one-page plan for your lab: roles, hardware, IPs, OS for each.
2. Check that virtualization is enabled: `lscpu | grep -i virtualization` and `dmesg | grep -i -e DMAR -e IOMMU`.
3. Find your server's out-of-band option. If it has none, how would you recover it remotely?
