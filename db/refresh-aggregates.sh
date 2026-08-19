#!/bin/bash
set -e

# Setup MySQL configuration and load environment variables
source ./db/setup-mysql-config.sh
MYCNF=".my.cnf"

echo "Refreshing metric aggregates..."
mysql --defaults-extra-file="$MYCNF" "${MYSQL_DATABASE}" < db/utilities/refresh_aggregates.sql

echo "Metric aggregates refreshed successfully"
