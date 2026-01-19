#!/bin/bash
# Install LSP plugins for Claude Code

echo "[setup-lsp] Installing Claude Code LSP plugins..."

# Install Python LSP plugin
if claude plugin install pyright-lsp@claude-plugins-official 2>/dev/null; then
    echo "[setup-lsp] Installed: pyright-lsp"
else
    echo "[setup-lsp] WARNING: Failed to install pyright-lsp (may already be installed)"
fi

# Install TypeScript LSP plugin
if claude plugin install typescript-lsp@claude-plugins-official 2>/dev/null; then
    echo "[setup-lsp] Installed: typescript-lsp"
else
    echo "[setup-lsp] WARNING: Failed to install typescript-lsp (may already be installed)"
fi

echo "[setup-lsp] LSP plugin installation complete"
