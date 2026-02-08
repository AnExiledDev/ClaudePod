#!/bin/bash
# Symlink $HOME/.claude → $CLAUDE_CONFIG_DIR so third-party tools
# (ccburn, ccusage, etc.) that hardcode ~/.claude can find auth and config.

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:=/workspaces/.claude}"
HOME_CLAUDE="$HOME/.claude"

echo "[setup-symlink] Ensuring $HOME_CLAUDE → $CLAUDE_DIR ..."

# Already a correct symlink — nothing to do
if [ -L "$HOME_CLAUDE" ]; then
    CURRENT_TARGET="$(readlink "$HOME_CLAUDE")"
    if [ "$CURRENT_TARGET" = "$CLAUDE_DIR" ]; then
        echo "[setup-symlink] Symlink already correct, skipping"
        exit 0
    fi
    # Points somewhere else — remove stale symlink
    echo "[setup-symlink] Removing stale symlink ($CURRENT_TARGET)"
    rm "$HOME_CLAUDE"
fi

# Real directory exists — merge contents into target, then remove
if [ -d "$HOME_CLAUDE" ]; then
    echo "[setup-symlink] Moving existing $HOME_CLAUDE contents into $CLAUDE_DIR"
    mkdir -p "$CLAUDE_DIR"
    # Copy contents preserving attributes; skip files that already exist in target
    cp -rn "$HOME_CLAUDE/." "$CLAUDE_DIR/" 2>/dev/null || true
    rm -rf "$HOME_CLAUDE"
fi

# Ensure target exists
mkdir -p "$CLAUDE_DIR"

# Create symlink
ln -s "$CLAUDE_DIR" "$HOME_CLAUDE"
echo "[setup-symlink] Created symlink: $HOME_CLAUDE → $CLAUDE_DIR"
