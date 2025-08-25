#!/bin/bash

# Claude Code Installation Module
# Handles Claude Code installation using focused functions

# State tracking directory
STATE_DIR="/workspace/.devcontainer/state"

# Function to create state marker
create_state_marker() {
    local component="$1"
    local method="${2:-unknown}"
    
    mkdir -p "$STATE_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $method" > "$STATE_DIR/${component}.installed"
    chown -R node:node "$STATE_DIR"
}

# Function to check if component is already installed
is_component_installed() {
    local component="$1"
    
    [ -f "$STATE_DIR/${component}.installed" ]
}

# Function to verify Claude Code installation
verify_claude_installation() {
    local installation_method="$1"
    
    if command -v claude &> /dev/null || [ -f "/home/node/.local/bin/claude" ]; then
        local version=$(claude --version 2>/dev/null || echo "installed")
        echo "📌 Claude Code version: $version"
        echo "✅ Claude Code verification successful ($installation_method)"
        return 0
    else
        echo "⚠️  Claude Code installed via $installation_method but 'claude' command not found"
        echo "📍 Checking installation location..."
        find /home/node/.local -name "claude" -type f 2>/dev/null || echo "   No claude binary found"
        return 1
    fi
}

# Function to install Claude Code via native binary
install_claude_code_native() {
    echo "📦 Installing Claude Code via native binary..."
    
    if retry_command 3 5 bash -c 'curl -fsSL claude.ai/install.sh | bash'; then
        echo "✅ Claude Code native binary installation completed"
        return 0
    else
        echo "❌ Failed to install Claude Code native binary after multiple attempts"
        return 1
    fi
}

# Function to install Claude Code via npm fallback
install_claude_code_npm() {
    echo "📦 Installing Claude Code via npm fallback..."
    
    # Ensure npm environment is configured
    export npm_config_prefix="/home/node/.local"
    
    if retry_command 3 5 npm install -g @anthropic-ai/claude-code; then
        echo "✅ Claude Code npm installation completed"
        return 0
    else
        echo "❌ Failed to install Claude Code via npm"
        return 1
    fi
}

# Main Claude Code installation function
install_claude_code() {
    # Check if Claude Code is already installed
    if is_component_installed "claude-code"; then
        echo "✅ Claude Code already installed (marker found)"
        if verify_claude_installation "cached"; then
            return 0
        else
            echo "⚠️  Marker exists but verification failed, reinstalling..."
            rm -f "$STATE_DIR/claude-code.installed"
        fi
    fi
    
    echo "📦 Installing Claude Code (Native Binary)..."
    
    # Attempt native binary installation first
    if install_claude_code_native; then
        if verify_claude_installation "native binary"; then
            create_state_marker "claude-code" "native binary"
            return 0
        else
            echo "⚠️  Native binary installation completed but verification failed"
        fi
    fi
    
    # Fallback to npm installation
    echo "⚠️  Falling back to npm installation..."
    
    if install_claude_code_npm; then
        if verify_claude_installation "npm fallback"; then
            create_state_marker "claude-code" "npm fallback"
            return 0
        else
            echo "❌ npm installation completed but verification failed"
            return 1
        fi
    else
        echo "❌ Failed to install Claude Code via both native binary and npm"
        return 1
    fi
}