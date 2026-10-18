# 04 — Web Server, TLS and Deploying Apps

## The standard single-VPS architecture

```
Internet ──443/80──▶ [Reverse proxy: Caddy or Nginx]  (only public listener; TLS termination)
                         ├── app.example.com  ─▶ app container   127.0.0.1:3000 / docker network
                         ├── api.example.com  ─▶ api container   :8000
                         └── example.com      ─▶ static files    /srv/www
                     [Postgres] [Redis]  ← internal docker network only, never published
```

## Reverse proxy choice

| | Caddy | Nginx | Traefik |
|---|---|---|---|
| TLS | **automatic** (ACME built in, renews itself, supports ARI renewal timing) | certbot / acme.sh | automatic |
| Config | very short Caddyfile | verbose, ubiquitous, most docs and examples | labels on containers |
| Use when | most VPS setups (default here) | you need Nginx-specific features, or a team standard | lots of dynamic containers, Swarm/K8s |

### Caddy (recommended)
```bash
# Option 1: as a container in the compose stack (files/compose/compose.yaml includes it)
# Option 2: native from Caddy's official repo
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy
sudo cp files/caddy/Caddyfile /etc/caddy/Caddyfile && sudo caddy validate --config /etc/caddy/Caddyfile && sudo systemctl reload caddy
```

### Nginx + certbot (alternative)
```bash
sudo apt install -y nginx certbot python3-certbot-nginx
sudo cp files/nginx/app.conf /etc/nginx/sites-available/app.conf && sudo ln -s ../sites-available/app.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d example.com -d www.example.com     # sets up auto-renewal (systemd timer)
sudo certbot renew --dry-run
```

## TLS facts worth knowing (2026)

- Let's Encrypt certificates are getting **shorter**: 90 days today, with an opt-in 45-day
  profile, 64 days by default from Feb 2027 and 45 days from Feb 2028. **Automate renewal
  completely** (Caddy/certbot do) and monitor expiry (the Servers ch. 08 blackbox alert).
  Let's Encrypt **no longer emails** expiry warnings, so monitoring is your job.
- Use **HSTS** once HTTPS works everywhere: `Strict-Transport-Security: max-age=31536000; includeSubDomains`.
- Wildcard certs (`*.example.com`) need the **DNS-01** challenge (an API token for your DNS host).

## Deploying an app with Docker Compose (the production-style pattern)

File: [`files/compose/compose.yaml`](files/compose/compose.yaml). There's **no `.env`**. Secrets come
from your secret manager at runtime ([`../SECRETS.md`](../SECRETS.md)).
```bash
sudo mkdir -p /opt/stacks/myapp && sudo chown deploy: /opt/stacks/myapp
scp files/compose/compose.yaml files/caddy/Caddyfile deploy@web-01:/opt/stacks/myapp/
ssh deploy@web-01
# YOU (one time): in the secret manager, create POSTGRES_PASSWORD, APP_SECRET_KEY, EMAIL_API_KEY and S3_SECRET_ACCESS_KEY,
# store the machine token with systemd-creds, and write the project ID (SECRETS.md steps 2-4):
echo "<bws-project-id>" > /opt/stacks/myapp/BWS_PROJECT_ID
sudo install -m 644 stack@.service /etc/systemd/system/ && sudo systemctl daemon-reload   # from Servers/files/secrets/
sudo systemctl enable --now stack@myapp          # bws run → docker compose up -d --wait
docker compose -f /opt/stacks/myapp/compose.yaml ps && docker compose -f /opt/stacks/myapp/compose.yaml logs -f --tail=100 app
```
Practices built into the file:
- Images come from a registry (GHCR/Docker Hub), built in CI, tagged with the **git SHA**. You don't
  build on the server.
- `healthcheck`s, so `depends_on: condition: service_healthy` orders start-up.
- DB/Redis only on an internal network. Named volumes for data. Log rotation.
- `restart: unless-stopped`, resource limits, and non-root users where the image allows.

**Zero-downtime-ish deploys on one box:** run two app replicas behind the proxy and recreate them
one by one, or use **Kamal** (chapter 07), which does blue/green container swaps for you.

## Static sites

Build locally or in CI, then `rsync -avz --delete dist/ deploy@web-01:/srv/www/example.com/`.
Caddy's `file_server` serves them. Or skip the VPS: Cloudflare Pages / Netlify / GitHub Pages.

## Exercises
1. Serve `example.com` (static) and `app.example.com` (a container) from one Caddy instance.
2. Get an A+ rating on SSL Labs and securityheaders.com.
3. Kill the app container and confirm Docker restarts it and the health check recovers.
