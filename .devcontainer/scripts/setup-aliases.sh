#!/bin/bash
# Setup cc/claude/ccraw aliases for claude with local system prompt support

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:?CLAUDE_CONFIG_DIR not set}"

echo "[setup-aliases] Configuring Claude aliases..."

# Simple alias definitions (not functions — functions don't behave reliably across shell contexts)
ALIAS_CC='alias cc='"'"'command claude --system-prompt-file .claude/system-prompt.md --permission-mode plan --allow-dangerously-skip-permissions'"'"''
ALIAS_CLAUDE='alias claude='"'"'command claude --system-prompt-file .claude/system-prompt.md --permission-mode plan --allow-dangerously-skip-permissions'"'"''
ALIAS_CCRAW='alias ccraw="command claude"'

for rc in ~/.bashrc ~/.zshrc; do
    if [ -f "$rc" ]; then
        # --- Cleanup old definitions ---

        # Remove old cc alias
        if grep -q "alias cc=" "$rc" 2>/dev/null; then
            sed -i '/alias cc=/d' "$rc"
            echo "[setup-aliases] Removed old cc alias from $(basename $rc)"
        fi
        # Remove old cc function (single-line or multi-line)
        if grep -q "^cc()" "$rc" 2>/dev/null; then
            sed -i '/^cc() {/,/^}/d' "$rc"
            echo "[setup-aliases] Removed old cc function from $(basename $rc)"
        fi
        # Remove old _claude_with_config function
        if grep -q "^_claude_with_config()" "$rc" 2>/dev/null; then
            sed -i '/^_claude_with_config() {/,/^}/d' "$rc"
            echo "[setup-aliases] Removed old _claude_with_config function from $(basename $rc)"
        fi
        # Remove old claude function override
        if grep -q "^claude() {" "$rc" 2>/dev/null; then
            sed -i '/^claude() { _claude_with_config/d' "$rc"
            echo "[setup-aliases] Removed old claude function from $(basename $rc)"
        fi
        # Remove old claude alias
        if grep -q "alias claude=" "$rc" 2>/dev/null; then
            sed -i '/alias claude=/d' "$rc"
        fi
        # Remove old ccraw alias
        if grep -q "alias ccraw=" "$rc" 2>/dev/null; then
            sed -i '/alias ccraw=/d' "$rc"
        fi
        # Remove old specwright alias
        if grep -q "alias specwright=" "$rc" 2>/dev/null; then
            sed -i '/alias specwright=/d' "$rc"
        fi

        # --- Add environment, auto-tmux, and aliases ---
        echo "" >> "$rc"
        echo "# Claude Code environment and aliases (managed by setup-aliases.sh)" >> "$rc"
        # Export CLAUDE_CONFIG_DIR so it's available in all shells (not just VS Code remoteEnv)
        if ! grep -q 'export CLAUDE_CONFIG_DIR=' "$rc" 2>/dev/null; then
            echo "export CLAUDE_CONFIG_DIR=\"${CLAUDE_CONFIG_DIR}\"" >> "$rc"
        fi
        # Export UTF-8 locale so tmux renders Unicode correctly (docker exec doesn't inherit locale)
        if ! grep -q 'export LANG=en_US.UTF-8' "$rc" 2>/dev/null; then
            echo 'export LANG=en_US.UTF-8' >> "$rc"
            echo 'export LC_ALL=en_US.UTF-8' >> "$rc"
        fi
        # Auto-enter tmux for Agent Teams split-pane support
        # Guards: not already in tmux, interactive shell only, tmux available
        if ! grep -q 'Auto-enter tmux' "$rc" 2>/dev/null; then
            cat >> "$rc" << 'TMUX_BLOCK'

# Auto-enter tmux for Agent Teams split-pane support
if [ -z "$TMUX" ] && [ -n "$PS1" ] && command -v tmux &>/dev/null; then
    exec tmux -u new-session -A -s claude-teams
fi
TMUX_BLOCK
        fi
        echo "$ALIAS_CC" >> "$rc"
        echo "$ALIAS_CLAUDE" >> "$rc"
        echo "$ALIAS_CCRAW" >> "$rc"
        echo "[setup-aliases] Added aliases to $(basename $rc)"
    fi
done

echo "[setup-aliases] Aliases configured:"
echo "  cc     -> claude with local .claude/system-prompt.md"
echo "  claude -> claude with local .claude/system-prompt.md"
echo "  ccraw  -> vanilla claude without any config"
