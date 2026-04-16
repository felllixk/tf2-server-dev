#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"

PLUGIN_SRC="$1"

if [ -z "$PLUGIN_SRC" ]; then
    echo "Usage: $0 <plugin_name.sp>"
    exit 1
fi

SOURCE_SCRIPTS_DIR="$WORKSPACE_DIR/tf2-data/addons/sourcemod/scripting"

# Если файл не найден как есть — ищем в папке scripting
if [ ! -f "$PLUGIN_SRC" ]; then
    if [ -f "$SOURCE_SCRIPTS_DIR/$PLUGIN_SRC" ]; then
        PLUGIN_SRC="$SOURCE_SCRIPTS_DIR/$PLUGIN_SRC"
    else
        echo "Error: File '$PLUGIN_SRC' not found (also checked $SOURCE_SCRIPTS_DIR/$PLUGIN_SRC)."
        exit 1
    fi
fi

PLUGIN_NAME="$(basename "$PLUGIN_SRC" .sp)"

SCRIPTING_DIR="$WORKSPACE_DIR/tf2-server/tf/addons/sourcemod/scripting"
PLUGINS_DIR="$WORKSPACE_DIR/tf2-data/addons/sourcemod/plugins"

mkdir -p "$SCRIPTING_DIR"
mkdir -p "$PLUGINS_DIR"

echo "==> Copying $PLUGIN_SRC -> $SCRIPTING_DIR/${PLUGIN_NAME}.sp"
cp "$PLUGIN_SRC" "$SCRIPTING_DIR/${PLUGIN_NAME}.sp"

echo "==> Compiling ${PLUGIN_NAME}.sp..."
docker compose -f "$WORKSPACE_DIR/docker-compose.yml" run --rm tf2 \
    /home/steam/tf-dedicated/tf/addons/sourcemod/scripting/spcomp64 \
    /home/steam/tf-dedicated/tf/addons/sourcemod/scripting/${PLUGIN_NAME}.sp \
    -o /home/steam/tf-dedicated/tf/addons/sourcemod/plugins/${PLUGIN_NAME}.smx

echo "==> Copying compiled plugin -> $PLUGINS_DIR/${PLUGIN_NAME}.smx"
cp "$WORKSPACE_DIR/tf2-server/tf/addons/sourcemod/plugins/${PLUGIN_NAME}.smx" \
   "$PLUGINS_DIR/${PLUGIN_NAME}.smx"

echo "==> Done! Plugin compiled: $PLUGINS_DIR/${PLUGIN_NAME}.smx"
