#!/bin/bash
set -e

# Create .my.cnf config file from environment variables
if [ ! -f .env ]; then
  echo "Error: .env file not found"
  exit 1
fi
set -a
source .env
set +a

MYCNF=".my.cnf"
cat > "$MYCNF" <<EOF
[client]
host=${MYSQL_HOST}
user=${MYSQL_USER}
password=${MYSQL_PWD}
port=${MYSQL_PORT}
EOF
chmod 600 "$MYCNF"
