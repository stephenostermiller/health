#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
DATA_DIR="${DATA_DIR:-$DIR/data}"
APACHE_USER="${APACHE_USER:-www-data}"
APACHE_GROUP="${APACHE_GROUP:-www-data}"
TARGET_MODE="2775"

if ! id "$APACHE_USER" >/dev/null 2>&1; then
	echo "User not found: $APACHE_USER" >&2
	exit 1
fi

if ! getent group "$APACHE_GROUP" >/dev/null 2>&1; then
	echo "Group not found: $APACHE_GROUP" >&2
	exit 1
fi

if [ -d "$DATA_DIR" ]; then
	CURRENT_OWNER=$(stat -c %U "$DATA_DIR")
	CURRENT_GROUP=$(stat -c %G "$DATA_DIR")
	CURRENT_MODE=$(stat -c %a "$DATA_DIR")

	if [ "$CURRENT_OWNER" = "$APACHE_USER" ] && [ "$CURRENT_GROUP" = "$APACHE_GROUP" ] && [ "$CURRENT_MODE" = "$TARGET_MODE" ]; then
		echo "No changes for $DATA_DIR"
		exit 0
	fi
fi

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root" >&2
	exit 1
fi

mkdir -p "$DATA_DIR"
chown "$APACHE_USER:$APACHE_GROUP" "$DATA_DIR"
chmod "$TARGET_MODE" "$DATA_DIR"

echo "Configured $DATA_DIR for $APACHE_USER:$APACHE_GROUP"
