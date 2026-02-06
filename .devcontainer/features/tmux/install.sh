#!/bin/bash
set -e

echo "Installing tmux for Claude Code Agent Teams..."

# Install tmux via apt
apt-get update
apt-get install -y tmux

# Create a basic tmux config optimized for Claude Code teams
TMUX_CONF="/etc/tmux.conf"
cat > "$TMUX_CONF" << 'EOF'
# Claude Code Agent Teams - tmux configuration

# Enable mouse support for pane selection
set -g mouse on

# Start window numbering at 1
set -g base-index 1
setw -g pane-base-index 1

# Increase scrollback buffer
set -g history-limit 10000

# Reduce escape time for better responsiveness
set -sg escape-time 10

# Status bar configuration
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
set -g status-left '[#S] '
set -g status-right '%H:%M '
set -g status-left-length 20

# Pane border styling
set -g pane-border-style 'fg=#45475a'
set -g pane-active-border-style 'fg=#89b4fa'

# Window status
setw -g window-status-current-style 'fg=#1e1e2e bg=#89b4fa bold'
setw -g window-status-current-format ' #I:#W '
setw -g window-status-style 'fg=#cdd6f4'
setw -g window-status-format ' #I:#W '

# Enable true color support
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
EOF

echo "tmux installed successfully"
echo "  - Config: $TMUX_CONF"
echo "  - Use 'tmux new -s claude-teams' to start a session"
echo "  - Claude Code Agent Teams will auto-detect tmux when available"
