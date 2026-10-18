# 04 — Storage and Backups

## Storage options

| Tech | What it gives you | When |
|---|---|---|
| **LVM** | resizable volumes, snapshots | default for general servers (Ubuntu installer) |
| **mdadm** | software RAID | simple mirrors under LVM/ext4 |
| **ZFS** | RAID + checksums (detects/repairs bit rot) + snapshots + send/receive replication + compression | NAS, Proxmox, anything holding important data |
| **Btrfs** | snapshots, checksums, compression | single-disk/mirror setups; RAID5/6 is still not recommended |
| **Ceph** | distributed block/file/object storage | 3+ node clusters (Proxmox HCI), at scale |
| NFS / SMB | network file shares | NAS → clients/VMs |
| MinIO / Garage | S3-compatible object storage | backups, app storage in labs |

ZFS essentials:
```bash
sudo apt install -y zfsutils-linux
sudo zpool create -o ashift=12 tank mirror /dev/disk/by-id/ata-DISK1 /dev/disk/by-id/ata-DISK2
sudo zfs set compression=lz4 atime=off tank
sudo zfs create tank/data
sudo zpool scrub tank           # schedule monthly (Ubuntu installs a scrub timer)
zpool status -x                 # "all pools are healthy"
```
Always reference disks by `/dev/disk/by-id/`, never `/dev/sdX`.

Disk health: `smartctl -a /dev/sda`, with `smartd` enabled to send email/alerts.

## The 3-2-1(-1-0) backup rule

- **3** copies of data, on **2** different media, **1** off-site,
- **1** immutable/offline copy (ransomware can't delete it),
- **0** errors on restore tests.

| What | How |
|---|---|
| Files/app data | **restic** or **borg** → local repo + off-site (S3/B2/Wasabi/Hetzner Storage Box) |
| Databases | logical dumps (`pg_dump`, `mysqldump`, `mongodump`) **plus** PITR for important DBs (pgBackRest/WAL-G for Postgres) |
| VMs/containers | **Proxmox Backup Server** (dedup, incremental, verify jobs) |
| ZFS datasets | snapshots (sanoid) + `zfs send` replication (syncoid) to another box |
| Config | it's in Git (Ansible) and doesn't need a separate backup, *if* you really manage it as code |

**Snapshots aren't backups.** They live on the same disks.

## restic setup (files in `files/backups/`)

There's **no secrets file**. The repository password and storage keys live in your secret manager
and are injected at runtime ([`../SECRETS.md`](../SECRETS.md)).
```bash
sudo apt install -y restic
sudo install -d -m 755 /etc/restic
sudo install -m 644 files/backups/backup.conf.example /etc/restic/backup.conf   # edit: repo URL, paths, project ID (no secrets)
sudo install -m 750 files/backups/restic-backup.sh /usr/local/sbin/restic-backup
sudo install -m 644 files/backups/restic-backup.{service,timer} /etc/systemd/system/
# YOU: create RESTIC_PASSWORD, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY in the secret manager project,
#      and store the machine token once with systemd-creds (SECRETS.md, step 3).
sudo systemctl daemon-reload
# Initialise the repository once, with secrets injected (nothing gets written to disk):
sudo systemd-run --expand-environment=no --pipe --wait -p LoadCredentialEncrypted=bws-token:/etc/credstore.encrypted/bws-token \
  /bin/bash -c '. /etc/restic/backup.conf; BWS_ACCESS_TOKEN=$(cat "$CREDENTIALS_DIRECTORY/bws-token") bws run --project-id "$BWS_PROJECT_ID" -- restic init'
sudo systemctl enable --now restic-backup.timer
systemctl list-timers restic-backup.timer
```
The script dumps databases first, backs up the paths, applies a retention policy
(`--keep-daily 7 --keep-weekly 4 --keep-monthly 12`), and runs `restic check`. Keep a second copy
of the repository password in your **personal password manager**, because without it the backup
is useless.

Immutability: use an S3 bucket with **Object Lock** (compliance/governance mode), or a backup
server that pulls (the client can't delete), or `rest-server --append-only`.

## Restore drills (the part everyone skips)

Monthly, or after big changes:
```bash
restic snapshots
restic restore latest --target /tmp/restore-test --include /etc
restic dump latest /var/backups/db/app.sql.gz | gunzip | head
```
For databases: restore into a **scratch instance** and run a query. Record the time it took. That's
your real **RTO** (recovery time objective). How old the backup was is your **RPO**.

## Exercises
1. Build a ZFS mirror in a VM using two virtual disks, fail one (`zpool offline`), and replace it.
2. Set up restic to a local disk *and* an S3-compatible bucket, then restore a deleted file.
3. Time a full database restore and write it into a runbook.
