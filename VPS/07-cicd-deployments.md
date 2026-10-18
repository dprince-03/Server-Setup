# 07 — CI/CD and Deployments to VPSes

## The pipeline teams use

```
git push → CI: lint + test → build Docker image (tag = git SHA) → push to registry (GHCR)
        → CD: deploy to staging → smoke tests → (approval) → deploy to production → health check → done / auto-rollback
```
Never `git pull && build` on production servers. Servers only **pull a tested image**.

## Option 1 — GitHub Actions + SSH + Compose (simple, transparent)

[`files/github-actions/deploy-ssh.yml`](files/github-actions/deploy-ssh.yml) → `.github/workflows/deploy.yml` in your app repo.

Setup:
1. Create a **deploy key** just for CI: `ssh-keygen -t ed25519 -f deploy_ci -C ci@github`. Put the
   public key in `~deploy/.ssh/authorized_keys` on the server, ideally restricted:
   `from="<github-actions-ip-ranges or bastion>",no-agent-forwarding,no-port-forwarding,no-pty ssh-ed25519 AAAA...`
   (or deploy over Tailscale with an ephemeral auth key, so SSH isn't public at all).
2. Create a GitHub **Environment** `production` (with required reviewers). **You** add the one secret
   from your own terminal, so the agent never handles it:
   `gh secret set SSH_PRIVATE_KEY --env production < ~/.ssh/deploy_ci` (then delete the local private key
   copy, or keep it in your password manager). Add the non-secret **Variables** `SSH_HOST`, `SSH_USER` and
   `SSH_KNOWN_HOSTS` (`ssh-keyscan -t ed25519 host`).
3. On the server, the stack runs as `stack@myapp.service` (secrets come from the secret manager, see
   [`../SECRETS.md`](../SECRETS.md)), and the deploy user may only restart that unit (a sudoers rule shown in the workflow header).
4. The workflow builds and pushes `ghcr.io/<owner>/<app>:<sha>`, writes the tag to `RELEASE`, restarts the
   unit (`docker compose up -d --wait` waits for the health checks), and rolls back to the previous tag if it fails.
   For private GHCR images, log in on the server **yourself** with a read-only token, using a credential helper
   (`docker-credential-pass`/`secretservice`) so the token isn't stored in plain text.

## Option 2 — Kamal 2 (zero-downtime, many hosts, from 37signals)

```bash
gem install kamal           # or: docker run ghcr.io/basecamp/kamal
kamal init                  # creates config/deploy.yml and .kamal/secrets
# use files/kamal/deploy.yml as a starting point, and files/kamal/secrets as .kamal/secrets
# (it FETCHES values from your secret manager; no values are ever written to the file)
kamal setup                 # installs Docker on the hosts, boots kamal-proxy (with TLS) and accessories (DB/Redis)
kamal deploy                # build, push, then a blue/green swap on every host
kamal rollback <version>    # instant rollback to a previous image
kamal app logs -f
```
Kamal-proxy handles Let's Encrypt and zero-downtime switching, so no separate Caddy is needed.

## Option 3 — Self-hosted PaaS: Coolify / Dokploy / CapRover

A Heroku-like web UI on your own VPS(es): Git push to deploy, previews, databases, backups, TLS.
Good for small teams. Remember the panel itself is now critical infrastructure: back it up and
keep it patched.

## Option 4 — GitOps on k3s (Argo CD / Flux)

The CI pipeline updates the image tag in a Git "deploy repo". Argo CD syncs the cluster to
match. That's the standard for Kubernetes teams (Servers ch. 06).

## Deployment strategies

| Strategy | What | Needs |
|---|---|---|
| Recreate | stop old → start new | brief downtime. Fine for internal tools |
| Rolling | replace instances one at a time | 2+ instances behind an LB |
| **Blue/green** | start the new version next to the old one, then switch traffic | a proxy that can switch (Kamal, Caddy/Traefik) |
| Canary | send a small % of traffic to the new version first | LB weights, metrics to judge it |

**Database migrations:** make them backward-compatible (expand → deploy → contract), run them
as a separate step before the switch, and never drop a column in the same release that stops using it.

## Secrets in CI/CD

Follow [`../SECRETS.md`](../SECRETS.md): OIDC for cloud access; GitHub Environment secrets only for
what's left, set by a human with `gh secret set`; app secrets in the secret manager, injected at runtime.
Never in the repo, `.env` files or image layers. Rotate the deploy keys when people leave.

## Exercises
1. Wire up `deploy-ssh.yml` for a demo app, break the health check on purpose, and watch the
   automatic rollback.
2. Deploy the same app to two VPSes with Kamal and confirm zero failed requests during
   `kamal deploy` (run `hey`/`oha` against it while deploying).
