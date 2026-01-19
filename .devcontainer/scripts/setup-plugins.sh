#!/bin/bash
# Install official Anthropic plugins

echo "[setup-plugins] Installing official Anthropic plugins..."

# Note: typescript-lsp and pyright-lsp are installed by setup-lsp.sh
PLUGINS=(
    "frontend-design@claude-plugins-official"
    "code-review@claude-plugins-official"
    "commit-commands@claude-plugins-official"
    "pr-review-toolkit@claude-plugins-official"
)

for plugin in "${PLUGINS[@]}"; do
    echo "[setup-plugins] Installing $plugin..."
    if claude plugin install "$plugin" 2>/dev/null; then
        echo "[setup-plugins] Installed: $plugin"
    else
        echo "[setup-plugins] Warning: Failed to install $plugin (may already exist)"
    fi
done

# code-simplifier requires npx method (not available via native CLI)
echo "[setup-plugins] Installing code-simplifier (via npx)..."
if npx -y claude-plugins install "@anthropics/claude-plugins-official/code-simplifier" 2>/dev/null; then
    echo "[setup-plugins] Installed: code-simplifier"
else
    echo "[setup-plugins] Warning: Failed to install code-simplifier (may already exist)"
fi

echo "[setup-plugins] Plugin installation complete"
