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
MYCNF=".my.cnf"

# Verify HEALTH_BACKUP_DIR is set
if [ -z "$HEALTH_BACKUP_DIR" ]; then
  echo "Error: HEALTH_BACKUP_DIR environment variable is not set"
  exit 1
fi

# Verify backup directory exists
if [ ! -d "$HEALTH_BACKUP_DIR" ]; then
  echo "Error: HEALTH_BACKUP_DIR ($HEALTH_BACKUP_DIR) does not exist"
  exit 1
fi

# Create backup directory structure: health/YYYY-MM-DD
BACKUP_DATE=$(date +%Y-%m-%d)
BACKUP_PATH="$HEALTH_BACKUP_DIR/health/$BACKUP_DATE"
mkdir -p "$BACKUP_PATH"

# Generate backup filename
BACKUP_FILE="$BACKUP_PATH/backup.sql"

log "Starting backup to $BACKUP_FILE..."

# Perform mysqldump excluding all aggregate tables
mysqldump --defaults-extra-file="$MYCNF" \
  --single-transaction \
  --lock-tables=false \
  --ignore-table="${MYSQL_DATABASE}.metric_aggregate_day" \
  --ignore-table="${MYSQL_DATABASE}.metric_aggregate_week" \
  --ignore-table="${MYSQL_DATABASE}.metric_aggregate_month" \
  --ignore-table="${MYSQL_DATABASE}.metric_aggregate_year" \
  "${MYSQL_DATABASE}" > "$BACKUP_FILE"

log "Backup completed successfully: $BACKUP_FILE"
log "Backup size: $(du -h "$BACKUP_FILE" | cut -f1)"

# Backup the .env file
cp .env "$BACKUP_PATH/.env"
log "Environment file saved: $BACKUP_PATH/.env"
