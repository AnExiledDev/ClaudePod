#!/bin/bash
# Install ALL plugins from local devs-marketplace

echo "[setup-local-plugins] Setting up local marketplace plugins..."

MARKETPLACE_PATH="${containerWorkspaceFolder:-.}/.devcontainer/plugins/devs-marketplace"

# Add local marketplace (if not already added)
if ! claude plugin marketplace list 2>/dev/null | grep -q "devs-marketplace"; then
    echo "[setup-local-plugins] Adding devs-marketplace..."
    claude plugin marketplace add "$MARKETPLACE_PATH" 2>/dev/null || {
        echo "[setup-local-plugins] WARNING: Failed to add marketplace"
    }
fi

# Install ALL plugins from marketplace.json (dynamic discovery)
MARKETPLACE_JSON="$MARKETPLACE_PATH/.claude-plugin/marketplace.json"
if [ -f "$MARKETPLACE_JSON" ]; then
    # Extract plugin names from marketplace.json
    PLUGINS=$(jq -r '.plugins[].name' "$MARKETPLACE_JSON" 2>/dev/null)

    if [ -z "$PLUGINS" ]; then
        echo "[setup-local-plugins] WARNING: No plugins found in marketplace.json (jq may not be installed)"
    else
        for plugin in $PLUGINS; do
            echo "[setup-local-plugins] Installing $plugin..."
            if claude plugin install "${plugin}@devs-marketplace" 2>/dev/null; then
                echo "[setup-local-plugins] Installed: $plugin"
            else
                echo "[setup-local-plugins] WARNING: Failed to install $plugin (may already be installed)"
            fi
        done
    fi
else
    echo "[setup-local-plugins] WARNING: marketplace.json not found at $MARKETPLACE_JSON"
fi

echo "[setup-local-plugins] Local plugin setup complete"
