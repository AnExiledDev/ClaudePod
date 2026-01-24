#!/bin/bash
# Master setup script for ClaudePod devcontainer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVCONTAINER_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$DEVCONTAINER_DIR/.env"

# Load configuration
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Apply defaults for any unset variables
: "${CLAUDE_CONFIG_DIR:=/workspaces/.claude}"
: "${CONFIG_SOURCE_DIR:=$DEVCONTAINER_DIR/config}"
: "${SETUP_CONFIG:=true}"
: "${SETUP_ALIASES:=true}"
: "${OVERWRITE_CONFIG:=false}"
: "${SETUP_PLUGINS:=true}"

export CLAUDE_CONFIG_DIR CONFIG_SOURCE_DIR SETUP_CONFIG SETUP_ALIASES OVERWRITE_CONFIG SETUP_PLUGINS


echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ClaudePod Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_script() {
    local script="$1"
    local enabled="$2"
    local name="$(basename $script .sh)"

    if [ "$enabled" = "true" ]; then
        if [ -f "$script" ]; then
            echo "Running $name..."
            bash "$script"
            echo ""
        else
            echo "WARNING: $script not found, skipping"
        fi
    else
        echo "Skipping $name (disabled)"
    fi
}

run_script "$SCRIPT_DIR/setup-config.sh" "$SETUP_CONFIG"
run_script "$SCRIPT_DIR/setup-aliases.sh" "$SETUP_ALIASES"
run_script "$SCRIPT_DIR/setup-plugins.sh" "$SETUP_PLUGINS"
run_script "$SCRIPT_DIR/setup-irie-claude.sh" "true"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
