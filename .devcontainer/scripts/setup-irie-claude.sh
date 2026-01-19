#!/bin/bash
# setup-irie-claude.sh
# Copies commands and agents from irie project to workspace .claude directory.
# This script is only for AnExiledDev's setup.

IRIE_CLAUDE="/workspaces/projects/irie/.claude"
WORKSPACE_CLAUDE="/workspaces/.claude"

# Fail gracefully if irie doesn't exist
if [[ ! -d "/workspaces/projects/irie" ]]; then
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│ Note: /workspaces/projects/irie not found.              │"
    echo "│ Failure is expected - this script is only for AnExiledDev│"
    echo "└─────────────────────────────────────────────────────────┘"
    exit 0
fi

# Copy commands if source exists
if [[ -d "$IRIE_CLAUDE/commands" ]]; then
    mkdir -p "$WORKSPACE_CLAUDE/commands"
    cp -f "$IRIE_CLAUDE/commands/"* "$WORKSPACE_CLAUDE/commands/" 2>/dev/null
    echo "Copied irie commands to workspace .claude"
fi

# Copy agents if source exists
if [[ -d "$IRIE_CLAUDE/agents" ]]; then
    mkdir -p "$WORKSPACE_CLAUDE/agents"
    cp -f "$IRIE_CLAUDE/agents/"* "$WORKSPACE_CLAUDE/agents/" 2>/dev/null
    echo "Copied irie agents to workspace .claude"
fi

echo "irie .claude sync complete"
