#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
FIXTURE="$PROJECT_DIR/t/fixtures/request_data.bin"

if [ ! -r "$FIXTURE" ]; then
	echo "Fixture not found: $FIXTURE" >&2
	exit 1
fi

PAYLOAD=$(cat "$FIXTURE")
PAYLOAD_SIZE=${#PAYLOAD}

QUERY_STRING='' \
REQUEST_METHOD='POST' \
REQUEST_URI='/scale/upload' \
HTTP_HOST='www.fitbit.com' \
CONTENT_LENGTH="$PAYLOAD_SIZE" \
CONTENT_TYPE='application/octet-stream' \
perl "$PROJECT_DIR/htdocs/index.cgi" <"$FIXTURE" >/tmp/fitbit-collector-smoke.txt 2>&1

grep -q 'OK' /tmp/fitbit-collector-smoke.txt
echo "Collector smoke test passed"
