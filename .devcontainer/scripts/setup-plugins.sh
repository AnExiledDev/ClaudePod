#!/bin/bash
# Install official Anthropic plugins

echo "[setup-plugins] Installing official Anthropic plugins..."

# Note: typescript-lsp and pyright-lsp are installed by setup-lsp.sh
PLUGINS=(
    "frontend-design@claude-plugins-official"
)

for plugin in "${PLUGINS[@]}"; do
    echo "[setup-plugins] Installing $plugin..."
    if claude plugin install "$plugin" 2>/dev/null; then
        echo "[setup-plugins] Installed: $plugin"
    else
        echo "[setup-plugins] Warning: Failed to install $plugin (may already exist)"
    fi
done

echo "[setup-plugins] Plugin installation complete"
