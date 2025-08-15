#!/bin/bash
set -euo pipefail

# ClaudePod Post-Create Script - Phases 2 & 4
# This script handles Claude Code installation, configuration, and development tools

echo "🚀 Starting ClaudePod post-create setup..."

# Source NVM to make npm available
# The Node.js feature installs via NVM at /usr/local/share/nvm
export NVM_DIR="/usr/local/share/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Retry function for resilient installations
retry_command() {
    local max_attempts=${1:-3}
    local delay=${2:-5}
    shift 2
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if "$@"; then
            return 0
        fi
        echo "⚠️  Command failed (attempt $attempt/$max_attempts): $*"
        if [ $attempt -lt $max_attempts ]; then
            echo "   Retrying in ${delay}s..."
            sleep $delay
        fi
        ((attempt++))
    done
    return 1
}

# Function to install Claude Code
install_claude_code() {
    echo "📦 Installing Claude Code..."
    
    # Ensure PATH includes npm global bin directory
    export PATH="/home/node/.local/bin:$PATH"
    
    # Install Claude Code globally with retry logic
    if retry_command 3 5 npm install -g @anthropic-ai/claude-code; then
        echo "✅ Claude Code installed successfully"
        
        # Verify installation with updated PATH
        if command -v claude &> /dev/null || [ -f "/home/node/.local/bin/claude" ]; then
            local version=$(/home/node/.local/bin/claude --version 2>/dev/null || echo "installed")
            echo "📌 Claude Code version: $version"
            return 0
        else
            echo "⚠️  Claude Code installed but 'claude' command not found"
            echo "📍 Checking installation location..."
            find /home/node/.local -name "claude" -type f 2>/dev/null || echo "   No claude binary found"
            return 1
        fi
    else
        echo "❌ Failed to install Claude Code after multiple attempts"
        return 1
    fi
}

# Function to setup workspace directories for bind mounts
setup_workspace_directories() {
    echo "🔧 Setting up workspace configuration directories..."
    
    # Create workspace directories for bind mounts
    local workspace_dirs=(
        "/workspace/.claude"
        "/workspace/.serena"
    )
    
    for dir in "${workspace_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "📁 Created workspace directory: $dir"
        fi
        # Set proper permissions
        chown -R node:node "$dir"
        chmod -R 755 "$dir"
    done
    
    # Setup Serena configuration if it doesn't exist
    setup_serena_config
    
    echo "✅ Workspace configuration directories ready"
}

# Function to setup Serena configuration
setup_serena_config() {
    local serena_config="/workspace/.serena/serena_config.yml"
    
    if [ ! -f "$serena_config" ]; then
        echo "📝 Creating Serena configuration..."
        
        cat > "$serena_config" << 'EOF'
gui_log_window: False
# whether to open a graphical window with Serena's logs.

web_dashboard: True
# whether to open the Serena web dashboard (accessible through your web browser)

web_dashboard_open_on_launch: False
# whether to open a browser window with the web dashboard when Serena starts
# If set to False, you can still open the dashboard manually by navigating to
# http://localhost:24282/dashboard/ in your web browser

log_level: 20
# the minimum log level for the GUI log window and the dashboard (10 = debug, 20 = info, 30 = warning, 40 = error)

trace_lsp_communication: False
# whether to trace the communication between Serena and the language servers.

tool_timeout: 240
# timeout, in seconds, after which tool executions are terminated

excluded_tools: []
# list of tools to be globally excluded

included_optional_tools: []
# list of optional tools (which are disabled by default) to be included

jetbrains: False
# whether to enable JetBrains mode

record_tool_usage_stats: False
# whether to record tool usage statistics

token_count_estimator: TIKTOKEN_GPT4O
# token count estimator to use for tool usage statistics

# MANAGED BY SERENA, KEEP AT THE BOTTOM OF THE YAML AND DON'T EDIT WITHOUT NEED
# The list of registered projects.
projects: []
EOF
        
        # Set proper ownership
        chown node:node "$serena_config"
        chmod 644 "$serena_config"
        
        echo "✅ Serena configuration created with dashboard auto-open disabled"
    else
        echo "📁 Serena configuration already exists"
    fi
}

# Function to setup Claude configuration directory
setup_claude_config() {
    echo "🔧 Setting up Claude configuration..."
    
    # Claude Code uses multiple possible config locations
    local claude_dirs=(
        "/home/node/.claude"
        "/home/node/.config/claude"
    )
    
    for dir in "${claude_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "📁 Created configuration directory: $dir"
        fi
        # Set proper permissions
        chown -R node:node "$dir"
        chmod -R 700 "$dir"
    done
    
    # Copy optimized settings.json from devcontainer config
    local settings_source="/workspace/.devcontainer/config/claude/settings.json"
    local settings_target_home="/home/node/.claude/settings.json"
    local settings_target_workspace="/workspace/.claude/settings.json"
    
    if [ -f "$settings_source" ]; then
        # Copy to home directory (will be bind-mounted to workspace)
        cp "$settings_source" "$settings_target_home"
        chown node:node "$settings_target_home"
        chmod 600 "$settings_target_home"
        
        # Also copy directly to workspace for redundancy
        cp "$settings_source" "$settings_target_workspace"
        chown node:node "$settings_target_workspace"
        chmod 600 "$settings_target_workspace"
        
        # Also copy MCP configuration and system prompt
        local mcp_source="/workspace/.devcontainer/config/claude/mcp.json"
        local mcp_target_home="/home/node/.claude/mcp.json"
        local mcp_target_workspace="/workspace/.claude/mcp.json"
        
        if [ -f "$mcp_source" ]; then
            cp "$mcp_source" "$mcp_target_home"
            cp "$mcp_source" "$mcp_target_workspace"
            chown node:node "$mcp_target_home" "$mcp_target_workspace"
            chmod 600 "$mcp_target_home" "$mcp_target_workspace"
        fi
        
        local prompt_source="/workspace/.devcontainer/config/claude/system-prompt.md"
        local prompt_target_home="/home/node/.claude/system-prompt.md"
        local prompt_target_workspace="/workspace/.claude/system-prompt.md"
        
        if [ -f "$prompt_source" ]; then
            cp "$prompt_source" "$prompt_target_home"
            cp "$prompt_source" "$prompt_target_workspace"
            chown node:node "$prompt_target_home" "$prompt_target_workspace"
            chmod 600 "$prompt_target_home" "$prompt_target_workspace"
        fi
        
        echo "📋 Copied optimized Claude settings (85 tools allowed, 91 tools denied)"
    else
        echo "⚠️  Claude settings template not found, using defaults"
    fi
    
    # Copy optimized Serena configuration
    local serena_source="/workspace/.devcontainer/config/serena/serena_config.yml"
    local serena_target_home="/home/node/.serena/serena_config.yml"
    local serena_target_workspace="/workspace/.serena/serena_config.yml"
    
    if [ -f "$serena_source" ]; then
        # Ensure Serena directories exist
        mkdir -p "/home/node/.serena" "/workspace/.serena"
        
        # Copy to home directory (will be bind-mounted to workspace)
        cp "$serena_source" "$serena_target_home"
        chown node:node "$serena_target_home"
        chmod 600 "$serena_target_home"
        
        # Also copy directly to workspace for redundancy
        cp "$serena_source" "$serena_target_workspace"
        chown node:node "$serena_target_workspace"
        chmod 600 "$serena_target_workspace"
        
        echo "📋 Copied optimized Serena configuration"
    else
        echo "⚠️  Serena configuration template not found, using defaults"
    fi
    
    # Copy optimized TaskMaster configuration
    local taskmaster_source="/workspace/.devcontainer/config/taskmaster/config.json"
    local taskmaster_target_workspace="/workspace/.taskmaster/config.json"
    
    if [ -f "$taskmaster_source" ]; then
        # Ensure TaskMaster directory exists
        mkdir -p "/workspace/.taskmaster"
        
        # Copy to workspace
        cp "$taskmaster_source" "$taskmaster_target_workspace"
        chown node:node "$taskmaster_target_workspace"
        chmod 600 "$taskmaster_target_workspace"
        
        echo "📋 Copied optimized TaskMaster configuration"
    else
        echo "⚠️  TaskMaster configuration template not found, using defaults"
    fi
    
    echo "✅ Configuration directories ready"
}

# Function to install ccusage CLI tool
install_ccusage() {
    echo "📊 Installing ccusage..."
    
    if retry_command 3 5 npm install -g ccusage; then
        echo "✅ ccusage installed successfully"
        
        # Verify installation
        if [ -f "/home/node/.local/bin/ccusage" ] || command -v ccusage &> /dev/null; then
            local version=$(/home/node/.local/bin/ccusage --version 2>/dev/null || echo "installed")
            echo "📌 ccusage version: $version"
            return 0
        else
            echo "⚠️  ccusage installed but command not found"
            return 1
        fi
    else
        echo "❌ Failed to install ccusage"
        return 1
    fi
}

# Function to install development tools
install_dev_tools() {
    echo "🛠️  Installing additional development tools..."
    
    # Install git-delta for better git diffs
    echo "📦 Installing git-delta..."
    if command -v cargo &> /dev/null; then
        # If cargo is available, use it
        cargo install git-delta
    else
        # Otherwise, download the binary
        local delta_version="0.18.2"
        local delta_url="https://github.com/dandavison/delta/releases/download/${delta_version}/delta-${delta_version}-x86_64-unknown-linux-musl.tar.gz"
        
        if retry_command 2 5 wget -q -O /tmp/delta.tar.gz "$delta_url"; then
            sudo tar -xzf /tmp/delta.tar.gz -C /usr/local/bin delta-${delta_version}-x86_64-unknown-linux-musl/delta --strip-components=1
            sudo chmod +x /usr/local/bin/delta
            rm -f /tmp/delta.tar.gz
            echo "✅ git-delta installed successfully"
            
            # Configure git to use delta
            git config --global core.pager "delta"
            git config --global interactive.diffFilter "delta --color-only"
            git config --global delta.navigate true
            git config --global delta.light false
            git config --global delta.side-by-side true
        else
            echo "⚠️  Failed to install git-delta"
        fi
    fi
    
    # Setup basic shell enhancements
    setup_shell_config
}

# Function to setup enhanced ZSH configuration
setup_shell_config() {
    echo "🐚 Setting up enhanced shell configuration..."
    
    # Add PATH configuration to shell files
    local shell_files=(
        "/home/node/.bashrc"
        "/home/node/.zshrc" 
        "/home/node/.profile"
    )
    
    for shell_file in "${shell_files[@]}"; do
        # Ensure the shell file exists
        touch "$shell_file"
        
        # Add PATH and aliases if not already present
        if ! grep -q "# ClaudePod custom configuration" "$shell_file" 2>/dev/null; then
            cat >> "$shell_file" << 'EOF'

# ClaudePod custom configuration
export PATH="$HOME/.local/bin:$PATH"

# Git aliases
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# List aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
EOF
        fi
        
        # Set proper ownership
        chown node:node "$shell_file"
        chmod 644 "$shell_file"
    done
    
    # Run ZSH enhancement setup as the node user if available
    if [ -f ".devcontainer/setup-zsh.sh" ]; then
        sudo -u node -E bash .devcontainer/setup-zsh.sh 2>/dev/null || {
            echo "⚠️  ZSH setup encountered some non-critical errors, continuing..."
        }
        echo "✅ Enhanced ZSH configuration completed"
    else
        echo "✅ Basic shell configuration completed"
    fi
}

# Function to display setup completion message
display_completion_message() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "✅ ClaudePod setup complete!"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "🔑 Next steps:"
    echo "   1. Run 'claude' to start using Claude Code"
    echo "   2. Authentication will be handled on first use"
    echo "   3. Your configuration will persist in the mounted volumes"
    echo ""
    echo "🛠️  Installed tools:"
    echo "   - Claude Code CLI"
    echo "   - ccusage (Claude Code usage analytics)"
    echo "   - git-delta (better git diffs)"
    echo "   - Shell aliases (gs, gd, gc, gp, gl)"
    echo ""
    echo "💡 Tip: Claude Code is now available globally as 'claude'"
    echo "════════════════════════════════════════════════════════════════"
}

# Function to setup npm directories and permissions
setup_npm_permissions() {
    echo "🔧 Setting up npm directories and permissions..."
    
    # Create npm directories with correct ownership
    local npm_dirs=(
        "/home/node/.npm"
        "/home/node/.npm/_cacache" 
        "/home/node/.npm/_logs"
        "/home/node/.config"
        "/home/node/.local"
        "/home/node/.local/bin"
    )
    
    for dir in "${npm_dirs[@]}"; do
        mkdir -p "$dir"
        chown -R node:node "$dir"
        chmod -R 755 "$dir"
    done
    
    # Remove any existing .npmrc directory/file and create .npmrc file
    rm -rf /home/node/.npmrc
    cat > /home/node/.npmrc << 'EOF'
cache=/home/node/.npm/_cacache
update-notifier=false
EOF
    
    # Set proper ownership for .npmrc
    chown node:node /home/node/.npmrc
    chmod 644 /home/node/.npmrc
    
    echo "✅ npm directories and permissions configured"
}

# Main execution
main() {
    echo "════════════════════════════════════════════════════════════════"
    echo "🐳 ClaudePod Post-Create Setup - Phases 2 & 4"
    echo "════════════════════════════════════════════════════════════════"
    
    # Source NVM and ensure PATH is set correctly for the entire script
    export NVM_DIR="/usr/local/share/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    export PATH="/home/node/.local/bin:$PATH"
    
    # Fix workspace permissions
    echo "🔧 Setting workspace permissions..."
    sudo chown -R node:node /workspace
    sudo chmod -R u+rwX,g+rwX /workspace
    
    # Setup workspace directories for bind mounts (Claude and Serena)
    setup_workspace_directories
    
    # Setup npm permissions and directories
    setup_npm_permissions
    
    # Add node user to docker group for Docker socket access
    echo "🐳 Adding node user to docker group..."
    sudo usermod -aG docker node
    echo "✅ Node user added to docker group"
    
    # Install Claude Code
    if install_claude_code; then
        # Setup configuration directory
        setup_claude_config
        
        # Install ccusage CLI tool
        install_ccusage || echo "⚠️  Continuing without ccusage..."
        
        # Install development tools
        install_dev_tools
        
        # Display completion message
        display_completion_message
    else
        echo "⚠️  Setup completed with errors. Claude Code installation failed."
        echo "   You can try installing manually with: npm install -g @anthropic-ai/claude-code"
        exit 1
    fi
}

# Execute main function
main
