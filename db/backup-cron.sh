#!/bin/bash
set -e

# Load environment variables
if [ ! -f .env ]; then
  echo "Error: .env file not found" >&2
  exit 1
fi
set -a
source .env
set +a

# Change to project directory for relative paths to work
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

# Run backup and cleanup (silent unless errors occur)
db/backup.sh --quiet
db/cleanup-backups.sh --quiet
