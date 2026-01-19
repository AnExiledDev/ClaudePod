#!/bin/bash
set -euo pipefail

echo "[mcp-reasoner] Registering Reasoner MCP server with Claude Code..."

# Determine user
USERNAME="${USERNAME:-vscode}"
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    for CURRENT_USER in vscode node codespace; do
        if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
fi

# Check if reasoner is installed
REASONER_PATH="/home/${USERNAME}/mcp-reasoner/dist/index.js"
if [ ! -f "$REASONER_PATH" ]; then
    echo "[mcp-reasoner] WARNING: Reasoner not found at $REASONER_PATH, skipping registration"
    exit 0
fi

# Ensure settings.json exists
SETTINGS_FILE="/workspaces/.claude/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "[mcp-reasoner] ERROR: $SETTINGS_FILE not found"
    exit 1
fi

# Check if jq is available
if ! command -v jq &>/dev/null; then
    echo "[mcp-reasoner] ERROR: jq not available"
    exit 1
fi

# Build the server configuration
SERVER_CONFIG=$(jq -n \
    --arg cmd "node" \
    --arg path "$REASONER_PATH" \
    '{
        command: $cmd,
        args: [$path]
    }')

# Update settings.json - add or update reasoner server
# Create temporary file for atomic update
TEMP_FILE=$(mktemp)
jq --argjson server "$SERVER_CONFIG" \
    '.mcpServers.reasoner = $server' \
    "$SETTINGS_FILE" > "$TEMP_FILE"

# Verify the JSON is valid
if jq empty "$TEMP_FILE" 2>/dev/null; then
    mv "$TEMP_FILE" "$SETTINGS_FILE"
    echo "[mcp-reasoner] ✓ Reasoner MCP server registered in Claude Code settings"
else
    echo "[mcp-reasoner] ERROR: Generated invalid JSON"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Set proper permissions
chmod 644 "$SETTINGS_FILE"
chown vscode:vscode "$SETTINGS_FILE" 2>/dev/null || true

echo "[mcp-reasoner] ✓ Configuration complete"
