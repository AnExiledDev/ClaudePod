#!/bin/bash
# Setup claude/cc functions for claude with local system prompt support

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:?CLAUDE_CONFIG_DIR not set}"

echo "[setup-aliases] Configuring Claude aliases..."

# Shared function for claude with local config (used by both cc and claude)
CLAUDE_FUNCTION='_claude_with_config() {
    local LOCAL_PROMPT=".claude/system-prompt.md"
    local DEFAULT_PROMPT="/workspaces/.devcontainer/config/main-system-prompt.md"
    local LOCAL_SETTINGS=".claude/settings.json"
    local DEFAULT_SETTINGS="/workspaces/.devcontainer/config/settings.json"

    mkdir -p .claude

    if [ ! -f "$LOCAL_PROMPT" ]; then
        cp "$DEFAULT_PROMPT" "$LOCAL_PROMPT"
        echo "[claude] Created $LOCAL_PROMPT from default"
    fi

    if [ ! -f "$LOCAL_SETTINGS" ]; then
        cp "$DEFAULT_SETTINGS" "$LOCAL_SETTINGS"
        echo "[claude] Created $LOCAL_SETTINGS from default"
    fi

    command claude --system-prompt-file "$LOCAL_PROMPT" --dangerously-skip-permissions "$@"
}

# cc: shorthand for claude with config
cc() { _claude_with_config "$@"; }

# claude: override to use config (use ccraw for vanilla)
claude() { _claude_with_config "$@"; }

# ccraw: vanilla claude without any config
alias ccraw="command claude"'

for rc in ~/.bashrc ~/.zshrc; do
    if [ -f "$rc" ]; then
        # Remove old cc alias/function if present
        if grep -q "alias cc=" "$rc" 2>/dev/null; then
            sed -i '/alias cc=/d' "$rc"
            echo "[setup-aliases] Removed old cc alias from $(basename $rc)"
        fi
        if grep -q "^cc()" "$rc" 2>/dev/null; then
            # Remove old cc function (multi-line)
            sed -i '/^cc() {/,/^}/d' "$rc"
            echo "[setup-aliases] Removed old cc function from $(basename $rc)"
        fi
        # Remove old specwright alias if present
        if grep -q "alias specwright=" "$rc" 2>/dev/null; then
            sed -i '/alias specwright=/d' "$rc"
            echo "[setup-aliases] Removed specwright alias from $(basename $rc)"
        fi
        # Remove old _claude_with_config function if present
        if grep -q "^_claude_with_config()" "$rc" 2>/dev/null; then
            sed -i '/^_claude_with_config() {/,/^}/d' "$rc"
        fi
        # Remove old claude function override if present
        if grep -q "^claude() {" "$rc" 2>/dev/null; then
            sed -i '/^claude() { _claude_with_config/d' "$rc"
        fi
        # Remove old ccraw alias if present
        if grep -q "alias ccraw=" "$rc" 2>/dev/null; then
            sed -i '/alias ccraw=/d' "$rc"
        fi
        # Add functions if not present
        if ! grep -q "^_claude_with_config()" "$rc" 2>/dev/null; then
            echo "" >> "$rc"
            echo "$CLAUDE_FUNCTION" >> "$rc"
            echo "[setup-aliases] Added claude functions to $(basename $rc)"
        fi
    fi
done

echo "[setup-aliases] Aliases configured:"
echo "  claude -> claude with local .claude/system-prompt.md (auto-created from defaults)"
echo "  cc     -> shorthand for claude with config"
echo "  ccraw  -> vanilla claude without any config"
