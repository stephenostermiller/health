#!/bin/bash
set -e

# Setup MySQL configuration and load environment variables
source ./db/setup-mysql-config.sh
MYCNF=".my.cnf"

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

# Parse command line options
RESTORE_DB="$MYSQL_DATABASE"
RESTORE_DATE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--database)
      RESTORE_DB="$2"
      shift 2
      ;;
    -t|--date)
      RESTORE_DATE="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  -d, --database DB_NAME    Restore to different database (default: $MYSQL_DATABASE)"
      echo "  -t, --date YYYY-MM-DD     Restore from specific date (default: most recent)"
      echo "  -h, --help                Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                                 # Restore latest backup to current database"
      echo "  $0 --database health_test          # Restore latest backup to health_test database"
      echo "  $0 --date 2026-08-20               # Restore 2026-08-20 backup to current database"
      echo "  $0 --database health_test --date 2026-08-20  # Restore specific date to different database"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# If no date specified, find the most recent backup
if [ -z "$RESTORE_DATE" ]; then
  RESTORE_DATE=$(ls -1 "$BACKUP_BASE" | sort -r | head -1)
  if [ -z "$RESTORE_DATE" ]; then
    echo "Error: No backups found in $BACKUP_BASE"
    exit 1
  fi
  echo "Using most recent backup: $RESTORE_DATE"
fi

# Verify the backup exists
BACKUP_FILE="$BACKUP_BASE/$RESTORE_DATE/backup.sql"
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file not found: $BACKUP_FILE"
  exit 1
fi

# Check if database has existing tables
TABLE_COUNT=$(mysql --defaults-extra-file="$MYCNF" "$RESTORE_DB" -sN -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$RESTORE_DB';" 2>/dev/null || echo "0")

if [ "$TABLE_COUNT" -gt 0 ]; then
  echo "Error: Database '$RESTORE_DB' already contains $TABLE_COUNT table(s)"
  echo "Cannot restore to a database with existing tables to prevent data loss"
  echo ""
  echo "Options:"
  echo "  1. Drop all tables in the database:"
  echo "     mysql --defaults-extra-file=.my.cnf -e \"SELECT CONCAT('DROP TABLE ', GROUP_CONCAT(TABLE_NAME)) AS stmt FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='$RESTORE_DB'\" | tail -1 | mysql --defaults-extra-file=.my.cnf $RESTORE_DB"
  echo ""
  echo "  2. Drop and recreate the database:"
  echo "     mysql --defaults-extra-file=.my.cnf -e \"DROP DATABASE $RESTORE_DB; CREATE DATABASE $RESTORE_DB;\""
  echo ""
  echo "  3. Restore to a different database:"
  echo "     db/restore.sh --database <new_db_name> --date $RESTORE_DATE"
  exit 1
fi

# Show restore details
echo ""
echo "=========================================="
echo "Database Restore Configuration"
echo "=========================================="
echo "Backup file:  $BACKUP_FILE"
echo "File size:    $(du -h "$BACKUP_FILE" | cut -f1)"
echo "Restore to:   $RESTORE_DB"
echo ""
echo "Starting restore..."

# Restore the backup
mysql --defaults-extra-file="$MYCNF" "$RESTORE_DB" < "$BACKUP_FILE"

echo ""
echo "=========================================="
echo "Restore completed successfully!"
echo "=========================================="
