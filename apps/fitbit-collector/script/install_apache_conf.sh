#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
TEMPLATE="$DIR/apache/fitbit-spoof.conf"
TARGET="/etc/apache2/sites-available/fitbit-spoof.conf"
TARGET_MODE="644"
CGI_SCRIPT="$DIR/htdocs/index.cgi"
CGI_MODE="755"

if [ ! -f "$TEMPLATE" ]; then
	echo "Template not found: $TEMPLATE" >&2
	exit 1
fi

if [ ! -d "$(dirname -- "$TARGET")" ]; then
	echo "Target directory not found: $(dirname -- "$TARGET")" >&2
	exit 1
fi

if [ ! -f "$CGI_SCRIPT" ]; then
	echo "CGI script not found: $CGI_SCRIPT" >&2
	exit 1
fi

TMP_TARGET=$(mktemp)
trap 'rm -f "$TMP_TARGET"' EXIT HUP INT TERM

sed "s|FITBIT_SPOOF_DIR|$DIR|g" "$TEMPLATE" > "$TMP_TARGET"


CGI_MODE_OK=0
if [ "$(stat -c %a "$CGI_SCRIPT")" = "$CGI_MODE" ]; then
	CGI_MODE_OK=1
fi

if [ -f "$TARGET" ]; then
	CURRENT_MODE=$(stat -c %a "$TARGET")
	if [ "$CURRENT_MODE" = "$TARGET_MODE" ] && [ "$CGI_MODE_OK" -eq 1 ] && cmp -s "$TMP_TARGET" "$TARGET"; then
		echo "No changes for $TARGET"
		exit 0
	fi
fi

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root to install: $TARGET" >&2
	exit 1
fi

mv "$TMP_TARGET" "$TARGET"
chmod "$TARGET_MODE" "$TARGET"
chmod "$CGI_MODE" "$CGI_SCRIPT"
echo "Wrote $TARGET"

a2ensite fitbit-spoof.conf
apache2ctl -t
service apache2 reload
echo "Enabled site fitbit-spoof.conf and reloaded Apache"
