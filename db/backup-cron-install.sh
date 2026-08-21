#!/bin/bash
set -e

# Parse command line options
TEST_MODE=false
if [ "$1" = "--test" ] || [ "$1" = "-t" ]; then
  TEST_MODE=true
fi

# Find the project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check if HEALTH_BACKUP_DIR is set
if [ ! -f "$PROJECT_DIR/.env" ] || ! grep -q "HEALTH_BACKUP_DIR" "$PROJECT_DIR/.env"; then
  echo "Warning: HEALTH_BACKUP_DIR not configured in .env"
  echo "Cannot install cron job without backup directory configured"
  exit 0
fi

# Get the current user (handles both direct execution and sudo)
CURRENT_USER="${SUDO_USER:-$USER}"

# Verify we're in the right place
if [ ! -f "$PROJECT_DIR/db/backup.crontab" ]; then
  echo "Error: backup.crontab not found in $PROJECT_DIR/db/"
  exit 1
fi

if [ ! -x "$PROJECT_DIR/db/backup-cron.sh" ]; then
  echo "Error: backup-cron.sh is not executable"
  exit 1
fi

CRON_FILE="/etc/cron.d/healthbackup"

# Create temporary file with substitutions
TEMP_FILE=$(mktemp)
sed -e "s|{{PROJECT_DIR}}|$PROJECT_DIR|g" -e "s|{{USER}}|$CURRENT_USER|g" "$PROJECT_DIR/db/backup.crontab" > "$TEMP_FILE"

if [ "$TEST_MODE" = true ]; then
  echo "Test mode - This crontab would be installed:"
  echo ""
  cat "$TEMP_FILE"
  echo ""
  echo "To install: db/install-backup-cron.sh"
  rm "$TEMP_FILE"
else
  # Check if cron file exists and compare
  if [ -f "$CRON_FILE" ] && cmp -s "$TEMP_FILE" "$CRON_FILE"; then
    echo "✓ Cron job already installed and up-to-date"
    echo "✓ User: $CURRENT_USER"
    echo "✓ Schedule: Daily at 2:08 AM"
    echo "✓ Location: $CRON_FILE"
    rm "$TEMP_FILE"
  else
    # Install to /etc/cron.d/ using sudo
    echo "Installing backup cron job to $CRON_FILE..."
    sudo install -m 644 "$TEMP_FILE" "$CRON_FILE"
    rm "$TEMP_FILE"

    echo "✓ Cron job installed"
    echo "✓ User: $CURRENT_USER"
    echo "✓ Schedule: Daily at 2:08 AM"
    echo "✓ Location: $CRON_FILE"
  fi
  echo ""
  echo "To verify: cat $CRON_FILE"
  echo "To remove: sudo rm $CRON_FILE"
fi
