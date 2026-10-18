# 09 — Operations: Maintenance, Incidents and Documentation

## Routine operations calendar

| Frequency | Task |
|---|---|
| Daily (automated) | security updates, backups, backup-success check, alerts reviewed |
| Weekly | review dashboards and logs for anomalies, apply non-security updates in a window (staging first) |
| Monthly | **restore test**, ZFS scrub results, disk SMART review, user/access review, reboot for kernels |
| Quarterly | DR drill (rebuild one server from code + backups), capacity planning, firmware/BIOS updates, rotate keys |
| Yearly | hardware lifecycle review, OS major-release planning (LTS N → N+1), architecture review |

## Change management (lightweight version for small teams)

1. Write down the change: what, why, risk, rollback, maintenance window.
2. Make it in Git (Ansible/Terraform/compose). A teammate reviews the PR.
3. Dry run (`--check`, `plan`), apply in staging, then production.
4. Verify, and record it in the change log.

## Incident response

1. **Detect.** An alert or a user report.
2. **Triage.** Who's affected? How badly? Declare an incident, and name **one incident commander**.
3. **Mitigate first, fix later.** Roll back, fail over, scale up, or block the bad traffic.
4. **Communicate.** Status updates on a schedule (status page / chat channel).
5. **Resolve and verify.** The monitoring is green and users confirm.
6. **Postmortem.** Blameless, within a week: [`files/docs/postmortem-template.md`](files/docs/postmortem-template.md).

### First 5 minutes on a sick Linux server

```bash
uptime                                  # load averages
dmesg -T | tail -30                     # kernel errors, OOM kills, disk errors
journalctl -p err -b --since "1 hour ago"
systemctl --failed
df -h; df -i                            # space AND inodes
free -m; vmstat 1 5                     # memory, swap, CPU wait
top -o %CPU   # or htop / btop
iostat -xz 1 3                          # disk saturation (sysstat)
ss -tulpn                               # what's listening
ss -s                                   # connection counts
tail -f /var/log/syslog                 # or journalctl -f
```

## Documentation that teams actually keep

- **README per system:** purpose, owners, architecture diagram, dependencies, how to deploy.
- **Runbooks** for every alert and routine task: [`files/docs/runbook-template.md`](files/docs/runbook-template.md).
- **Network diagram + IP plan** (draw.io / NetBox).
- **Architecture Decision Records (ADRs):** why you chose X over Y.
- **Access register:** who has access to what, and who reviewed it.

Keep docs in Git next to the code (Markdown), or in a wiki (BookStack, Outline, Wiki.js).

## Disaster recovery (DR) planning

| Term | Meaning | Example target |
|---|---|---|
| RPO | the maximum data loss you can accept | 1 h (hourly backups / WAL shipping) |
| RTO | the maximum downtime you can accept | 4 h to rebuild from code + restore |

Test DR for real: wipe a lab VM and rebuild it only from Git + backups, and time it.

## Exercises
1. Write runbooks for "disk almost full" and "service down".
2. Run a game day: a friend breaks something in your lab, and you handle it as an incident and
   write the postmortem.
