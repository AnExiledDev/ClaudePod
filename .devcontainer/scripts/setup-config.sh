#!/bin/bash
# Copy Claude configuration files to workspace

CONFIG_DIR="${CONFIG_SOURCE_DIR:?CONFIG_SOURCE_DIR not set}"
TARGET_DIR="${CLAUDE_CONFIG_DIR:?CLAUDE_CONFIG_DIR not set}"
OVERWRITE="${OVERWRITE_CONFIG:-false}"

echo "[setup-config] Copying configuration files..."
[ "$OVERWRITE" = "true" ] && echo "[setup-config] Overwrite mode enabled"

mkdir -p "$TARGET_DIR"

copy_file() {
    local file="$1"
    if [ -f "$CONFIG_DIR/$file" ]; then
        if [ "$OVERWRITE" = "true" ] || [ ! -f "$TARGET_DIR/$file" ]; then
            cp "$CONFIG_DIR/$file" "$TARGET_DIR/$file"
            chown "$(id -un):$(id -gn)" "$TARGET_DIR/$file" 2>/dev/null || true
            echo "[setup-config] Copied $file"
        else
            echo "[setup-config] $file already exists, skipping"
        fi
    fi
}

copy_file "settings.json"
copy_file "keybindings.json"
copy_file "main-system-prompt.md"

echo "[setup-config] Configuration complete"
