#!/bin/bash
set -e

# Source .env file
if [ ! -f .env ]; then
  echo "Error: .env file not found"
  exit 1
fi
source .env

# Create config file for shared use
MYCNF=".my.cnf"
cat > "$MYCNF" <<EOF
[client]
host=${MYSQL_HOST}
user=${MYSQL_USER}
password=${MYSQL_PWD}
port=${MYSQL_PORT}
EOF
chmod 600 "$MYCNF"

echo "Initializing database schema..."
mysql --defaults-extra-file="$MYCNF" "${MYSQL_DATABASE}" < db/schema/schema.sql

echo "Running migrations..."
for f in db/migrations/migrate_*.sql; do
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

echo "Creating stored procedures..."
mysql --defaults-extra-file="$MYCNF" "${MYSQL_DATABASE}" < db/utilities/refresh_aggregates.sql

echo "Database schema initialized successfully"
