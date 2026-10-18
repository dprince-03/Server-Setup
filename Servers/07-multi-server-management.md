# 07 — Managing Many Servers (Config as Code)

Past ~3 servers, hand-configuring them causes **configuration drift**: every box ends up slightly
different, and nobody knows why. Industry answer: an **inventory**, **configuration as code**, and
**central identity**.

## 1. Inventory (single source of truth)

Start simple: a Git repo with an Ansible inventory ([`files/ansible/inventory.example.ini`](files/ansible/inventory.example.ini)).
Grow into **NetBox** (DCIM/IPAM: racks, IPs, VLANs, cables) when you have real hardware and networks.

Record per host: name, role, IP(s), OS, location, owner, backup policy, monitoring status.

## 2. Ansible (agentless, over SSH)

```bash
# on your control machine (laptop or a management VM)
uv tool install --with-executables-from ansible-core ansible   # or: pipx install --include-deps ansible
cd files/ansible
cp inventory.example.ini inventory.ini        # edit hosts
ansible all -m ping                           # connectivity
ansible-playbook playbooks/baseline.yml --check --diff   # dry run: see what would change
ansible-playbook playbooks/baseline.yml       # apply the chapter 02/03 baseline everywhere
ansible-playbook playbooks/docker.yml -l docker_hosts
ansible-playbook playbooks/patch.yml          # rolling, one host at a time, with reboot if needed
```
Structure used in industry:
```
ansible/
├── ansible.cfg
├── inventory.ini                # or inventories/{prod,staging}/hosts.yml
├── group_vars/all.yml           # shared settings
├── host_vars/<host>.yml
├── roles/<role>/{tasks,handlers,templates,defaults}/
└── playbooks/*.yml
```
- Secrets are **looked up at run time from the secret manager**. They're never stored in the repo,
  not even encrypted. Use lookup plugins: `community.general.bitwarden_secrets_manager`,
  `community.general.onepassword`, `community.hashi_vault.vault_kv2_get`, or the AWS/GCP/Azure lookups.
  Example: `db_password: "{{ lookup('community.general.bitwarden_secrets_manager', '<secret-id>').value }}"`
  plus `no_log: true` on the tasks that use it. Your machine token comes from your own session (`export BWS_ACCESS_TOKEN` typed at a hidden prompt).
- Lint with `ansible-lint`. Test roles with **Molecule**.
- Every change goes through Git → PR → review → `--check` → apply. That's change management.

Alternatives: Salt, Puppet, Chef (agent-based, common in large enterprises), **NixOS** (fully
declarative OS).

## 3. Provisioning vs configuration

| Concern | Tool |
|---|---|
| Create VMs/networks/DNS records | **Terraform/OpenTofu** (Proxmox, cloud, Cloudflare providers) |
| First boot | **cloud-init** (user, SSH key, packages) |
| Configure the OS and apps | **Ansible** |
| Deploy apps | Compose/Kamal (VPS ch. 07), Kubernetes + GitOps |

## 4. Central identity and access

| Scale | Approach |
|---|---|
| A few admins | SSH keys distributed by Ansible (`authorized_key` module), one account per person |
| Team / many servers | **SSH certificates** (step-ca / Vault / Teleport): short-lived, no key sprawl |
| Organisation | **FreeIPA** (LDAP + Kerberos + sudo rules + HBAC) or AD, plus **SSO** (Authentik / Keycloak / Entra ID) for web apps |

Off-boarding a person must be **one action** (remove from the group/IdP), not editing 40 servers.

## 5. Secrets management

Vault / **OpenBao** (open-source Vault fork), Infisical, Bitwarden Secrets Manager, or a cloud
secret manager. Apps fetch secrets at start-up. Nothing sensitive lives in Git unencrypted.

## 6. Patching a fleet

- Stage it: lab → staging → production. Let canary hosts run a day first.
- `serial: 1` (or a percentage) in Ansible for rolling updates, so services stay up.
- Use `needrestart -r l` / `/var/run/reboot-required` to decide reboots.
  [`files/ansible/playbooks/patch.yml`](files/ansible/playbooks/patch.yml) does this.

## Exercises
1. Put three VMs in the inventory and apply `baseline.yml`. Change one setting by hand on a server,
   then rerun with `--check --diff` and watch Ansible detect the drift.
2. Put a secret in your secret manager (typed by you), read it in a playbook with a lookup plugin and
   `no_log: true`, and confirm it never shows up in the output.
3. Add a user via Ansible to all servers, then remove them, both in one command.
