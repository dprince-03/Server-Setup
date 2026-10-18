# Server-Setup: The Infrastructure Handbook

A **handbook, guide and course in one** for running your own infrastructure the way industry
teams do: from a single box under your desk to fleets of VPSes and multi-account cloud platforms.

Every chapter explains **why** (concepts and the trade-offs pros weigh), shows **how** (exact
commands and config files you can copy), and ends with **checks** and **exercises**.
Coding agents can follow it too. See [`AGENT.md`](AGENT.md).

```
Server-Setup/
├── AGENT.md                 rules for an AI agent executing these guides (starts with a "what to set up" menu, incl. ALL)
├── SECRETS.md               secrets policy: secret managers only, no .env, humans type the values
├── Servers/                 bare-metal / private servers / home labs (single → many)
│   └── files/               scripts, Ansible, monitoring stack, backup units, WireGuard...
├── VPS/                     rented virtual servers: domain, TLS, email, deploys, multi-VPS
│   └── files/               cloud-init, Caddy/Nginx, compose stacks, DNS zones, CI/CD...
└── Cloud/                   AWS, GCP, Azure: concepts first, then each platform
    ├── AWS/   (+ files/)    Terraform, IAM/SCP policies, GitHub OIDC deploys
    ├── GCP/   (+ files/)
    └── AZURE/ (+ files/)
```

## Learning path

| Stage | Read | You'll be able to |
|---|---|---|
| 1. Foundations | Servers 01–03 | install, secure and operate one Linux server properly |
| 2. Data safety | Servers 04 | design storage and **tested** backups (3-2-1) |
| 3. Going public | VPS 01–04 | rent a VPS, point a domain at it, serve apps over HTTPS |
| 4. Email | VPS 05 | run a domain's email correctly (and know when *not* to self-host) |
| 5. Many machines | Servers 05–08, VPS 06–08 | network, automate (Ansible), monitor and deploy across a fleet |
| 6. Cloud | Cloud 00–08 | reason about cloud architecture, IAM, networking, cost and security |
| 7. Platforms | Cloud/AWS, GCP, AZURE | build a proper landing zone and run real workloads on each |
| 8. Operations | Servers 09 | run on-call, handle incidents, write runbooks and postmortems |

## Core principles (they come up in every chapter)

1. **Cattle, not pets.** Anything you can't rebuild from code and backups is a liability.
2. **Least privilege.** Every human, service and machine gets only the access it needs.
3. **Defence in depth.** Firewall *and* SSH keys *and* updates *and* monitoring, never just one.
4. **Automate the second time.** Do it by hand once to learn it, then script it (bash → Ansible →
   Terraform).
5. **Backups don't exist until a restore has been tested.**
6. **Observe everything.** Metrics, logs, alerts: if you can't see it, you can't run it.
7. **Write it down.** Runbooks, diagrams, decision records. Your future self is a new team member.
8. **Secrets live in a secret manager only.** No `.env` files. You type the values yourself, and they're
   injected at runtime ([`SECRETS.md`](SECRETS.md)).

## Using it with an AI agent

Open your coding agent in this folder and say:
> Read `AGENT.md` and follow it. Show me the setup menu first.

The agent will list every option (Servers, VPS and Cloud topics, plus **ALL**), confirm the target and
environment, and then explain or carry out the chapters you picked.

## Conventions used

- Commands assume **Ubuntu Server LTS** or **Debian stable** unless stated. RHEL-family
  (Rocky/Alma) differences are noted.
- `example.com`, `203.0.113.10` (public), `10.0.0.0/8` / `192.168.x.x` (private) and `you@` are
  placeholders.
- Files referenced as `files/...` sit in the `files/` folder of that section.
- **Versions are never pinned in the prose.** Install the latest stable release, as in PC-Setup.
