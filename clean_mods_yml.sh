#!/usr/bin/env bash

# Backward compatibility wrapper for clean_mods_yml.sh
# This script calls the new location in scripts/standalone/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STANDALONE_SCRIPT="$SCRIPT_DIR/scripts/standalone/clean_mods_yml.sh"

if [ ! -f "$STANDALONE_SCRIPT" ]; then
    echo "Error: Standalone script not found at $STANDALONE_SCRIPT"
    exit 1
fi

# Pass all arguments to the standalone script
exec "$STANDALONE_SCRIPT" "$@"
