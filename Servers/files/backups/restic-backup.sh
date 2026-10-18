#!/usr/bin/env bash
# restic-backup.sh: dump databases, back up paths, prune with a retention policy, verify,
# and publish a Prometheus metric. Installed as /usr/local/sbin/restic-backup; run by restic-backup.timer.
# Non-secret config: /etc/restic/backup.conf (see backup.conf.example).
# Secrets (RESTIC_PASSWORD, AWS_*, MYSQL_BACKUP_PASSWORD, MONGO_BACKUP_URI) are injected as environment
# variables by the secret manager. restic-backup.service runs:  bws run --project-id <id> -- restic-backup
# This script never prints secret values.
set -euo pipefail

CONF_FILE=${CONF_FILE:-/etc/restic/backup.conf}
set -a; . "$CONF_FILE"; set +a

: "${RESTIC_REPOSITORY:?}" "${BACKUP_PATHS:?}"
: "${RESTIC_PASSWORD:?RESTIC_PASSWORD missing: run via the secret manager (bws run ...)}"
DUMP_DIR=${DUMP_DIR:-/var/backups/db}
TEXTFILE_DIR=${TEXTFILE_DIR:-/var/lib/prometheus/node-exporter}
HOST=$(hostname -s)

log() { echo "$(date -Is) $*"; }
mkdir -p "$DUMP_DIR"; chmod 700 "$DUMP_DIR"

# 1. Database dumps (only the engines that are configured)
if [[ -n "${PG_DATABASES:-}" ]]; then
  for db in $PG_DATABASES; do
    log "pg_dump $db"
    sudo -u postgres pg_dump --format=custom "$db" > "$DUMP_DIR/pg-$db.dump"
  done
fi
if [[ -n "${MYSQL_DATABASES:-}" ]]; then
  for db in $MYSQL_DATABASES; do
    log "mysqldump $db"
    # password is passed through an anonymous pipe (never on disk or in the process list)
    mysqldump --defaults-extra-file=<(printf '[client]\nuser=%s\npassword=%s\n' "$MYSQL_BACKUP_USER" "$MYSQL_BACKUP_PASSWORD") \
      --single-transaction --routines "$db" | gzip > "$DUMP_DIR/mysql-$db.sql.gz"
  done
fi
if [[ "${MONGO_BACKUP:-no}" == yes ]]; then
  log "mongodump"
  mongodump --config=<(printf 'uri: %s\n' "$MONGO_BACKUP_URI") --archive="$DUMP_DIR/mongo.archive.gz" --gzip
fi
# Docker-hosted Postgres example:  docker exec pg pg_dump -U postgres -Fc app > "$DUMP_DIR/pg-app.dump"

# 2. Backup
log "restic backup: $BACKUP_PATHS $DUMP_DIR"
# shellcheck disable=SC2086
restic backup $BACKUP_PATHS "$DUMP_DIR" \
  --host "$HOST" --tag scheduled \
  --exclude-caches ${RESTIC_EXCLUDE_FILE:+--exclude-file "$RESTIC_EXCLUDE_FILE"}

# 3. Retention
log "restic forget/prune"
restic forget --host "$HOST" --prune \
  --keep-daily "${KEEP_DAILY:-7}" --keep-weekly "${KEEP_WEEKLY:-4}" --keep-monthly "${KEEP_MONTHLY:-12}"

# 4. Verify (reads 5% of the data each run, so the whole repo is checked over time)
log "restic check"
restic check --read-data-subset=5%

# 5. Metric for alerting (BackupStale rule)
if [[ -d "$TEXTFILE_DIR" ]]; then
  printf 'backup_last_success_timestamp_seconds %s\n' "$(date +%s)" > "$TEXTFILE_DIR/backup.prom.$$"
  mv "$TEXTFILE_DIR/backup.prom.$$" "$TEXTFILE_DIR/backup.prom"
fi
# Optional heartbeat (Uptime Kuma push monitor / healthchecks.io)
[[ -n "${HEARTBEAT_URL:-}" ]] && curl -fsS -m 10 --retry 3 "$HEARTBEAT_URL" >/dev/null || true

log "backup OK"
