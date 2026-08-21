#!/bin/bash
set -e

QUIET=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -q|--quiet)
      QUIET=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

log() {
  if [ "$QUIET" = false ]; then
    echo "$@"
  fi
}

# Setup MySQL configuration and load environment variables
source ./db/setup-mysql-config.sh

# Verify HEALTH_BACKUP_DIR is set
if [ -z "$HEALTH_BACKUP_DIR" ]; then
  echo "Error: HEALTH_BACKUP_DIR environment variable is not set"
  exit 1
fi

BACKUP_BASE="$HEALTH_BACKUP_DIR/health"

# Verify backup directory exists
if [ ! -d "$BACKUP_BASE" ]; then
  echo "Error: Backup directory ($BACKUP_BASE) does not exist"
  exit 1
fi

deleted_count=0
kept_count=0
recent_count=0
recent_month_first_count=0
declare -A jan_first_years

# For all backup date directories sorted in reverse chronological order (newest first)
for backup_date in $(ls -1 "$BACKUP_BASE" | sort -r); do
  backup_dir="$BACKUP_BASE/$backup_date"

  # 1. Keep the first 10 (most recent, since sorted in reverse)
  if [ $recent_count -lt 10 ]; then
    log "Keeping (recent): $backup_date"
    recent_count=$((recent_count + 1))
    kept_count=$((kept_count + 1))
    continue
  fi

  # 2. Keep backups from 1st of month (up to 12)
  if [[ $backup_date =~ -01$ ]] && [ $recent_month_first_count -lt 12 ]; then
    log "Keeping (1st of month): $backup_date"
    recent_month_first_count=$((recent_month_first_count + 1))
    kept_count=$((kept_count + 1))
    continue
  fi

  # 3. Keep backups from Jan 1st (one per year)
  if [[ $backup_date =~ -01-01$ ]]; then
    year=${backup_date:0:4}
    if [ -z "${jan_first_years[$year]}" ]; then
      log "Keeping (Jan 1st): $backup_date"
      jan_first_years[$year]=1
      kept_count=$((kept_count + 1))
      continue
    fi
  fi

  # Delete everything else
  log "Deleting: $backup_date"
  rm -rf "$backup_dir"
  deleted_count=$((deleted_count + 1))
done

log ""
log "Cleanup complete: kept $kept_count, deleted $deleted_count backup(s)"
