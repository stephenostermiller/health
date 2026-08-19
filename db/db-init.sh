#!/bin/bash
set -e

# Setup MySQL configuration and load environment variables
source ./db/setup-mysql-config.sh
MYCNF=".my.cnf"

run_migrations() {
  local pattern="$1"

  for f in $pattern; do
    # Skip check files
    [[ "$f" == *.check.sql ]] && continue

    migration_name=$(basename "$f")
    check_file="${f%.sql}.check.sql"

    should_run=1

    # If check file exists, use it to determine whether to run
    if [ -f "$check_file" ]; then
      result=$(mysql --defaults-extra-file="$MYCNF" "${MYSQL_DATABASE}" -sN < "$check_file")
      should_run=$result
    fi

    # Run migration if should_run is non-zero
    if [ "$should_run" -gt 0 ]; then
      echo "Running $migration_name..."
      mysql --defaults-extra-file="$MYCNF" "${MYSQL_DATABASE}" < "$f"
    fi
  done
}

run_migrations "db/migrations/migrate_*.sql"

if [ "${HEALTH_DASHBOARD_DEMO:-0}" == "1" ]; then
  run_migrations "db/demo/migrate_*.sql"
fi
