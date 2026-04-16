#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"

SRC="$WORKSPACE_DIR/tf2-data"
DST="$WORKSPACE_DIR/tf2-server/tf"

DIRS=("addons" "cfg" "platform")

echo "==> Syncing tf2-data -> tf2-server/tf"

for dir in "${DIRS[@]}"; do
    if [ -d "$DST/$dir" ]; then
        echo "  Removing $DST/$dir"
        rm -rf "$DST/$dir"
    fi

    if [ -d "$SRC/$dir" ]; then
        echo "  Copying $SRC/$dir -> $DST/$dir"
        cp -r "$SRC/$dir" "$DST/$dir"
    else
        echo "  WARNING: $SRC/$dir not found, skipping"
    fi
done

echo "==> Done"
