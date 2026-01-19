#!/bin/bash
# Setup cc function for claude with local system prompt support

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:?CLAUDE_CONFIG_DIR not set}"

echo "[setup-aliases] Configuring Claude aliases..."

# cc function: ensures local system prompt and settings exist, then runs claude
CC_FUNCTION='cc() {
    local LOCAL_PROMPT=".claude/system-prompt.md"
    local DEFAULT_PROMPT="/workspaces/.devcontainer/config/main-system-prompt.md"
    local LOCAL_SETTINGS=".claude/settings.json"
    local DEFAULT_SETTINGS="/workspaces/.devcontainer/config/settings.json"

    mkdir -p .claude

    if [ ! -f "$LOCAL_PROMPT" ]; then
        cp "$DEFAULT_PROMPT" "$LOCAL_PROMPT"
        echo "[cc] Created $LOCAL_PROMPT from default"
    fi

    if [ ! -f "$LOCAL_SETTINGS" ]; then
        cp "$DEFAULT_SETTINGS" "$LOCAL_SETTINGS"
        echo "[cc] Created $LOCAL_SETTINGS from default"
    fi

    claude --system-prompt-file "$LOCAL_PROMPT" --dangerously-skip-permissions "$@"
}'

for rc in ~/.bashrc ~/.zshrc; do
    if [ -f "$rc" ]; then
        # Remove old cc alias if present
        if grep -q "alias cc=" "$rc" 2>/dev/null; then
            sed -i '/alias cc=/d' "$rc"
            echo "[setup-aliases] Removed old cc alias from $(basename $rc)"
        fi
        # Remove old specwright alias if present
        if grep -q "alias specwright=" "$rc" 2>/dev/null; then
            sed -i '/alias specwright=/d' "$rc"
            echo "[setup-aliases] Removed specwright alias from $(basename $rc)"
        fi
        # Add cc function if not present
        if ! grep -q "^cc()" "$rc" 2>/dev/null; then
            echo "" >> "$rc"
            echo "$CC_FUNCTION" >> "$rc"
            echo "[setup-aliases] Added cc function to $(basename $rc)"
        fi
    fi
done

echo "[setup-aliases] Aliases configured:"
echo "  cc -> claude with local .claude/system-prompt.md and .claude/settings.json (auto-created from defaults)"
