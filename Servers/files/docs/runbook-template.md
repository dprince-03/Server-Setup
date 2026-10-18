# Runbook: <Alert or task name>

| Field | Value |
|---|---|
| Service / system | |
| Owner / on-call | |
| Severity | critical / warning |
| Linked alert | `AlertName` |
| Last reviewed | YYYY-MM-DD |

## What this means
One or two sentences: what's broken, and how users feel it.

## Quick checks (first 5 minutes)
```bash
# commands to confirm the problem and its scope
```

## Mitigation
1. Step that restores service fastest (rollback / failover / restart / scale).
2. How to confirm it worked (dashboard link, command).

## Root-cause investigation
- Logs to look at (Grafana/Loki query):
- Common causes, and how to tell them apart:

## Escalation
Who to contact, and when (after X minutes, or if Y).

## Follow-up
- [ ] Ticket created
- [ ] Postmortem needed? (user impact > N minutes, or data loss)
