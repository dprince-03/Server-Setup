# Secrets Policy and How-To (applies to the whole handbook)

## The rules

1. **No `.env` files and no plaintext secret files.** Secrets live in a **secret manager**.
2. **The human types every secret value themselves**, into the secret manager's UI or a hidden prompt.
   Agents and scripts never generate, see, print, log, copy or commit a secret value.
3. Code, compose files, Terraform and CI configs contain **references** (names/IDs/ARNs/URIs), never values.
4. Secrets are injected **at runtime** into the process that needs them, and nothing persists on disk.
5. Prefer **no secret at all**: identity-based access (cloud IAM roles, managed identities, OIDC
   from CI, IAM database auth) beats any password.

## Choose a secret manager

| Where | Recommended | Why |
|---|---|---|
| AWS / GCP / Azure workloads | **Secrets Manager / Secret Manager / Key Vault** | native IAM, audit logs, rotation (Cloud ch. 05) |
| VPS / home-lab servers | **Bitwarden Secrets Manager** (`bws` CLI; free tier; open source), **Infisical** (self-hostable), **1Password** (`op`), **OpenBao/HashiCorp Vault** (self-hosted, for larger setups) | machine access tokens, a `run` command that injects env vars, audit logs |
| CI/CD | GitHub Actions **Environment secrets** (for the few that remain), OIDC for clouds | |
| Your workstation | the OS keychain (Windows Credential Manager / libsecret / macOS Keychain) or your password manager's CLI | |

Examples below use **Bitwarden Secrets Manager (`bws`)**. Infisical (`infisical run --`) and
1Password (`op run --`) work the same way.

## Pattern for servers (VPS / home lab)

```
Secret manager project "myapp-prod"  ←  YOU add POSTGRES_PASSWORD, APP_SECRET_KEY, ... in the web UI
        ▲  machine access token (read-only, scoped to that project)
        │  stored ENCRYPTED on the server with systemd-creds (you type it once)
systemd unit stack@myapp.service  →  bws run --project-id <id> -- docker compose up -d
        └─ compose passes each secret into the container as a file under /run/secrets/<name>
```

### One-time server setup (the human runs these; the agent may *prepare* the commands only)

```bash
# 1. Install the bws CLI (newest release from github.com/bitwarden/sdk-sm/releases, checksum verified)
# 2. In the Bitwarden Secrets Manager web app: create the project + secrets (you type the values),
#    then a machine account with READ access to that project → create an access token.
# 3. Store the token on the server, encrypted with the machine's TPM/host key. You paste it at the hidden prompt:
sudo install -d -m 700 /etc/credstore.encrypted
sudo systemd-ask-password -n "BWS access token:" | sudo systemd-creds encrypt --name=bws-token - /etc/credstore.encrypted/bws-token
# 4. Record the (non-secret) project ID for the stack:
echo "<bws-project-id>" | sudo tee /opt/stacks/myapp/BWS_PROJECT_ID >/dev/null
# 5. Install the unit and start the stack:
sudo install -m 644 Servers/files/secrets/stack@.service /etc/systemd/system/stack@.service
sudo systemctl daemon-reload && sudo systemctl enable --now stack@myapp
```

### Compose side: secrets become files, not env vars

```yaml
services:
  db:
    image: postgres:latest
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password   # most official images support *_FILE
    secrets: [postgres_password]
secrets:
  postgres_password:
    environment: POSTGRES_PASSWORD      # value comes from the environment set up by `bws run`
```
Apps read `/run/secrets/<name>` (or `*_FILE` variables). That's safer than environment variables,
which show up in `docker inspect` and crash dumps.

## Pattern for the cloud

Terraform/Bicep creates the **empty secret container** and the IAM binding. You add the value:
```bash
read -rsp "Value: " V; aws secretsmanager put-secret-value --secret-id myapp/prod/x --secret-string "$V" >/dev/null; unset V   # AWS
gcloud secrets versions add myapp-x --data-file=-        # GCP: type, then Ctrl-D
read -rsp "Value: " V; az keyvault secret set --vault-name kv-x --name x --value "$V" -o none; unset V                         # Azure
```
The workload reads it by reference (ECS `secrets.valueFrom`, Cloud Run `secret_key_ref`, Key Vault references).

## Pattern for CI

- Cloud access: **OIDC**, so there's nothing to store.
- Remaining secrets (e.g. an SSH deploy key): the human sets them with the CLI, reading from their
  own file or a prompt: `gh secret set SSH_PRIVATE_KEY --env production < ~/.ssh/deploy_ci`.
  `gh secret set NAME` with no input prompts for the value.

## What an agent may and may not do

| Allowed | Not allowed |
|---|---|
| Create empty secret containers, IAM bindings, references in code | Generate secret values (`openssl rand` into a config, etc.) |
| Write commands with **hidden prompts** for the human to run | Read, `cat`, echo, grep, decrypt or print any secret or token |
| Check that a secret **exists** (`aws secretsmanager describe-secret`, `bws secret list` showing names only) | Put secret values in files, command lines in logs, commits, issues or chat |
| Restart services that read secrets at runtime | Ask the user to paste a secret into the chat |
