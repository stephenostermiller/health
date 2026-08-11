#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

QUERY_STRING='metric=weight&granularity=day' \
	perl "$PROJECT_DIR/htdocs/api/series.cgi" >/tmp/health-dashboard-series.json

grep -q '"metric":"weight"' /tmp/health-dashboard-series.json
echo "Dashboard API smoke test passed"
