#!/bin/bash
# Install plugins: official Anthropic + local devs-marketplace

echo "[setup-plugins] Installing plugins..."

# --- Official Anthropic Plugins ---
OFFICIAL_PLUGINS=(
    "frontend-design@claude-plugins-official"
)

for plugin in "${OFFICIAL_PLUGINS[@]}"; do
    echo "[setup-plugins] Installing $plugin..."
    if claude plugin install "$plugin" 2>/dev/null; then
        echo "[setup-plugins] Installed: $plugin"
    else
        echo "[setup-plugins] Warning: Failed to install $plugin (may already exist)"
    fi
done

# --- Local Marketplace Plugins ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE_PATH="${SCRIPT_DIR}/../plugins/devs-marketplace"

# Add local marketplace (if not already added)
if ! claude plugin marketplace list 2>/dev/null | grep -q "devs-marketplace"; then
    echo "[setup-plugins] Adding devs-marketplace..."
    claude plugin marketplace add "$MARKETPLACE_PATH" 2>/dev/null || {
        echo "[setup-plugins] WARNING: Failed to add marketplace"
    }
fi

# Install ALL plugins from marketplace.json (dynamic discovery)
MARKETPLACE_JSON="$MARKETPLACE_PATH/.claude-plugin/marketplace.json"
if [ -f "$MARKETPLACE_JSON" ]; then
    PLUGINS=$(jq -r '.plugins[].name' "$MARKETPLACE_JSON" 2>/dev/null)

    if [ -z "$PLUGINS" ]; then
        echo "[setup-plugins] WARNING: No plugins found in marketplace.json"
    else
        for plugin in $PLUGINS; do
            echo "[setup-plugins] Installing $plugin from devs-marketplace..."
            if claude plugin install "${plugin}@devs-marketplace" 2>/dev/null; then
                echo "[setup-plugins] Installed: $plugin"
            else
                echo "[setup-plugins] WARNING: Failed to install $plugin (may already be installed)"
            fi
        done
    fi
else
    echo "[setup-plugins] WARNING: marketplace.json not found at $MARKETPLACE_JSON"
fi

echo "[setup-plugins] Plugin installation complete"
