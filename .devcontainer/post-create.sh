#!/bin/bash
set -euo pipefail

# ClaudePod Post-Create Script - Phases 2 & 4
# This script handles Claude Code installation, configuration, and development tools

echo "🚀 Starting ClaudePod post-create setup..."

# Source environment file if it exists
if [ -f "/workspace/.devcontainer/.env" ]; then
    echo "📋 Loading environment variables from .devcontainer/.env"
    set -a  # Export all variables
    source "/workspace/.devcontainer/.env"
    set +a  # Stop exporting
fi

# Source shared utility functions
source "/workspace/.devcontainer/scripts/utils.sh"

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

# Source configuration modules
source "/workspace/.devcontainer/scripts/config/claude-core.sh"
source "/workspace/.devcontainer/scripts/config/serena.sh"
source "/workspace/.devcontainer/scripts/config/taskmaster.sh"
source "/workspace/.devcontainer/scripts/config/searxng.sh"

# Source installation modules
source "/workspace/.devcontainer/scripts/install/claude-code.sh"

# Source NVM to make Node.js and npm available
export NVM_DIR="/usr/local/share/nvm"
# Wait for NVM to be available (up to 30 seconds)
for i in {1..30}; do
    [ -s "$NVM_DIR/nvm.sh" ] && break
    echo "⏳ Waiting for NVM installation... (attempt $i/30)"
    sleep 1
done

if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "🔧 Sourcing NVM..."
    . "$NVM_DIR/nvm.sh"
    
    # Verify npm is now available
    if command -v npm &> /dev/null; then
        echo "✅ npm is available: $(which npm)"
        echo "📌 npm version: $(npm --version)"
        echo "📌 node version: $(node --version)"
        
        # Setup npm permissions immediately after npm becomes available
        echo "🔧 Setting up npm directories and permissions..."
        
        # Create npm directories with correct ownership
        npm_dirs=(
            "/home/node/.npm"
            "/home/node/.npm/_cacache" 
            "/home/node/.npm/_logs"
            "/home/node/.config"
            "/home/node/.local"
            "/home/node/.local/bin"
            "/home/node/.cache"
        )
        
        for dir in "${npm_dirs[@]}"; do
            mkdir -p "$dir"
            chown -R node:node "$dir"
            chmod -R 755 "$dir"
        done
        
        # Remove any existing .npmrc directory/file and create .npmrc file
        # Use NVM-compatible configuration (no prefix setting to avoid NVM conflicts)
        rm -rf /home/node/.npmrc
        
        # Also clear any existing npm config that might conflict with NVM
        npm config delete prefix 2>/dev/null || true
        npm config delete globalconfig 2>/dev/null || true
        
        cat > /home/node/.npmrc << 'EOF'
cache=/home/node/.npm/_cacache
update-notifier=false
# Note: prefix and globalconfig settings removed to avoid NVM conflicts
EOF
        
        # Set environment variable to suppress NVM warnings about prefix
        export NVM_SUPPRESS_PREFIX_WARNING=1
        echo "export NVM_SUPPRESS_PREFIX_WARNING=1" >> /home/node/.profile
        echo "export NVM_SUPPRESS_PREFIX_WARNING=1" >> /home/node/.bashrc
        echo "export NVM_SUPPRESS_PREFIX_WARNING=1" >> /home/node/.zshrc
        
        # Set proper ownership for .npmrc
        chown node:node /home/node/.npmrc
        chmod 644 /home/node/.npmrc
        
        # Fix NVM symlink permissions issue PROPERLY
        echo "🔧 Fixing NVM symlink permissions..."
        if [ -d "/usr/local/share/nvm" ]; then
            # Remove the problematic root-owned symlink if it exists
            rm -f "/usr/local/share/nvm/current" 2>/dev/null || true
            
            # More aggressive permissions fix: make node user owner of NVM directory
            chown -R node:node "/usr/local/share/nvm"
            chmod -R 755 "/usr/local/share/nvm"
            
            # Pre-create the current symlink as the node user to avoid permission issues
            if command -v node &> /dev/null; then
                node_version=$(node --version | sed 's/v//')
                node_path="/usr/local/share/nvm/versions/node/v${node_version}"
                if [ -d "$node_path" ]; then
                    ln -sf "$node_path" "/usr/local/share/nvm/current" 2>/dev/null || true
                    chown -h node:node "/usr/local/share/nvm/current" 2>/dev/null || true
                fi
            fi
            
            echo "✅ NVM directory now owned by node user with symlink pre-created"
        fi
        
        echo "✅ npm directories and permissions configured (NVM conflicts resolved)"
    else
        echo "❌ npm still not found after sourcing NVM"
        exit 1
    fi
else
    echo "❌ NVM not found at $NVM_DIR/nvm.sh"
    exit 1
fi

# Set environment for Node.js operations (using PATH helper to avoid duplicates)
add_to_path "/home/node/.local/bin"
export npm_config_prefix="/home/node/.local"

# Claude Code installation is now handled by focused functions:
# - install_claude_code_native(): Native binary installation
# - install_claude_code_npm(): NPM fallback installation  
# - verify_claude_installation(): Installation verification
# - install_claude_code(): Main orchestrator function
# See: /workspace/.devcontainer/scripts/install/claude-code.sh

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

# Function to create configuration backup
create_config_backup() {
    local config_file="$1"
    local backup_dir="/workspace/.devcontainer/config/backups"
    
    if [ -f "$config_file" ]; then
        mkdir -p "$backup_dir"
        local filename=$(basename "$config_file")
        # Include path to distinguish home vs workspace configs
        local path_prefix=$(echo "$config_file" | sed 's|/|_|g' | sed 's|^_||')
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_file="${backup_dir}/${path_prefix}.${timestamp}.backup"
        
        cp "$config_file" "$backup_file"
        chown node:node "$backup_file"
        chmod 600 "$backup_file"
        echo "📦 Created backup: $backup_file"
        
        # Keep only the last 5 backups for each unique file path
        local base_name="${backup_dir}/${path_prefix}"
        ls -t ${base_name}.*.backup 2>/dev/null | tail -n +6 | xargs -r rm -f
    fi
}

# Configuration is now handled by focused modules:
# - claude-core.sh: Claude directory and core config files
# - serena.sh: Serena MCP server configuration  
# - taskmaster.sh: TaskMaster AI configuration

# Function to install ccusage CLI tool
install_ccusage() {
    # Check if ccusage is already installed
    if is_component_installed "ccusage"; then
        echo "✅ ccusage already installed (marker found)"
        if command -v ccusage &> /dev/null; then
            local version=$(ccusage --version 2>/dev/null || echo "installed")
            echo "📌 ccusage version: $version"
            return 0
        else
            echo "⚠️  Marker exists but verification failed, reinstalling..."
            rm -f "$STATE_DIR/ccusage.installed"
        fi
    fi
    
    echo "📊 Installing ccusage..."
    
    # Ensure npm uses the correct directories for the node user
    export npm_config_prefix="/home/node/.local"
    
    # Task 1: Clean ccusage directory conflicts before installation attempts
    echo "🧹 Cleaning any existing ccusage directories to prevent ENOTEMPTY errors..."
    local ccusage_dirs=(
        "/home/node/.local/lib/node_modules/ccusage"
        "/home/node/.local/lib/node_modules/.ccusage-*"
        "/home/node/.npm/_cacache/index-v5/*/ccusage"
    )
    
    for pattern in "${ccusage_dirs[@]}"; do
        if [ -d "$pattern" ] || ls $pattern >/dev/null 2>&1; then
            echo "🗑️  Removing existing directory: $pattern"
            rm -rf $pattern 2>/dev/null || true
        fi
    done
    
    # Clear npm cache for ccusage specifically
    npm cache clean --force --silent 2>/dev/null || true
    
    # Task 2: Add proper error handling for npm ENOTEMPTY issues
    echo "📦 Attempting ccusage installation with ENOTEMPTY error handling..."
    local install_success=false
    local attempts=3
    
    for attempt in $(seq 1 $attempts); do
        echo "📦 Installation attempt $attempt/$attempts..."
        
        if npm install -g ccusage 2>/dev/null; then
            install_success=true
            break
        else
            local exit_code=$?
            
            # Check for ENOTEMPTY error in npm logs
            local latest_log=$(find /home/node/.npm/_logs -name "*debug*.log" -type f -exec ls -t {} + | head -1 2>/dev/null)
            if [ -n "$latest_log" ] && grep -q "ENOTEMPTY" "$latest_log" 2>/dev/null; then
                echo "⚠️  ENOTEMPTY error detected, cleaning npm directories..."
                
                # Remove conflicting directories more aggressively
                rm -rf /home/node/.local/lib/node_modules/ccusage* 2>/dev/null || true
                rm -rf /home/node/.local/lib/node_modules/.ccusage* 2>/dev/null || true
                
                # Clear npm cache completely
                npm cache clean --force --silent 2>/dev/null || true
                rm -rf /home/node/.npm/_cacache/* 2>/dev/null || true
                
                if [ $attempt -lt $attempts ]; then
                    echo "🔄 Retrying installation after cleanup..."
                    sleep 2
                fi
            else
                echo "⚠️  Installation failed with exit code $exit_code (attempt $attempt/$attempts)"
                if [ $attempt -lt $attempts ]; then
                    echo "🔄 Retrying installation..."
                    sleep 2
                fi
            fi
        fi
    done
    
    if [ "$install_success" = "true" ]; then
        echo "✅ ccusage installed successfully"
        
        # Task 3: Verify installations work after fixes
        echo "🔍 Performing comprehensive installation verification..."
        
        # Wait for filesystem consistency
        sleep 1
        
        # Check multiple installation indicators
        local verification_passed=false
        local ccusage_bin="/home/node/.local/bin/ccusage"
        local ccusage_module="/home/node/.local/lib/node_modules/ccusage"
        
        if [ -f "$ccusage_bin" ] && [ -d "$ccusage_module" ]; then
            echo "✓ Binary and module directory both exist"
            
            # Test if the command actually works
            if "$ccusage_bin" --version >/dev/null 2>&1; then
                local version=$("$ccusage_bin" --version 2>/dev/null || echo "installed")
                echo "📌 ccusage version: $version"
                echo "✓ Command execution test passed"
                verification_passed=true
            else
                echo "⚠️  Binary exists but command execution failed"
            fi
        elif command -v ccusage &> /dev/null; then
            local version=$(ccusage --version 2>/dev/null || echo "installed")
            echo "📌 ccusage version: $version"
            echo "✓ Command found in PATH"
            verification_passed=true
        else
            echo "❌ Installation verification failed:"
            echo "   - Binary check: $([ -f "$ccusage_bin" ] && echo "FOUND" || echo "MISSING")"
            echo "   - Module check: $([ -d "$ccusage_module" ] && echo "FOUND" || echo "MISSING")"
            echo "   - PATH check: $(command -v ccusage &> /dev/null && echo "FOUND" || echo "MISSING")"
        fi
        
        if [ "$verification_passed" = "true" ]; then
            echo "✅ ccusage installation verification passed"
            create_state_marker "ccusage" "npm"
            return 0
        else
            echo "❌ ccusage installation verification failed"
            return 1
        fi
    else
        echo "❌ Failed to install ccusage after $attempts attempts"
        echo "💡 Manual installation command: npm install -g ccusage"
        return 1
    fi
}

# Function to install cchistory CLI tool
install_cchistory() {
    # Check if cchistory is already installed
    if is_component_installed "cchistory"; then
        echo "✅ cchistory already installed (marker found)"
        if command -v cchistory &> /dev/null; then
            local version=$(cchistory --help 2>/dev/null | grep -i version || echo "installed")
            echo "📌 cchistory version: installed"
            return 0
        else
            echo "⚠️  Marker exists but verification failed, reinstalling..."
            rm -f "$STATE_DIR/cchistory.installed"
        fi
    fi
    
    echo "📊 Installing cchistory (Claude Code prompt analyzer)..."
    
    # Ensure npm uses the correct directories for the node user
    export npm_config_prefix="/home/node/.local"
    
    # Clean any existing cchistory directories to prevent conflicts
    echo "🧹 Cleaning any existing cchistory directories..."
    local cchistory_dirs=(
        "/home/node/.local/lib/node_modules/@mariozechner/cchistory"
        "/home/node/.local/lib/node_modules/.@mariozechner-cchistory-*"
        "/home/node/.npm/_cacache/index-v5/*/cchistory"
    )
    
    for pattern in "${cchistory_dirs[@]}"; do
        if [ -d "$pattern" ] || ls $pattern >/dev/null 2>&1; then
            echo "🗑️  Removing existing directory: $pattern"
            rm -rf $pattern 2>/dev/null || true
        fi
    done
    
    # Install cchistory with error handling
    echo "📦 Attempting cchistory installation..."
    local install_success=false
    local attempts=2
    
    for attempt in $(seq 1 $attempts); do
        echo "📦 Installation attempt $attempt/$attempts..."
        
        if npm install -g @mariozechner/cchistory 2>/dev/null; then
            install_success=true
            break
        else
            local exit_code=$?
            echo "⚠️  Installation failed with exit code $exit_code (attempt $attempt/$attempts)"
            if [ $attempt -lt $attempts ]; then
                echo "🔄 Retrying installation..."
                sleep 2
            fi
        fi
    done
    
    if [ "$install_success" = "true" ]; then
        echo "✅ cchistory installed successfully"
        
        # Verify installation
        echo "🔍 Verifying cchistory installation..."
        
        # Wait for filesystem consistency
        sleep 1
        
        # Check installation indicators
        local verification_passed=false
        local cchistory_bin="/home/node/.local/bin/cchistory"
        local cchistory_module="/home/node/.local/lib/node_modules/@mariozechner/cchistory"
        
        if [ -f "$cchistory_bin" ] && [ -d "$cchistory_module" ]; then
            echo "✓ Binary and module directory both exist"
            
            # Test if the command actually works
            if "$cchistory_bin" --help >/dev/null 2>&1; then
                echo "📌 cchistory: Claude Code prompt analyzer"
                echo "✓ Command execution test passed"
                verification_passed=true
            else
                echo "⚠️  Binary exists but command execution failed"
            fi
        elif command -v cchistory &> /dev/null; then
            echo "📌 cchistory: Claude Code prompt analyzer"
            echo "✓ Command found in PATH"
            verification_passed=true
        else
            echo "❌ Installation verification failed:"
            echo "   - Binary check: $([ -f "$cchistory_bin" ] && echo "FOUND" || echo "MISSING")"
            echo "   - Module check: $([ -d "$cchistory_module" ] && echo "FOUND" || echo "MISSING")"
            echo "   - PATH check: $(command -v cchistory &> /dev/null && echo "FOUND" || echo "MISSING")"
        fi
        
        if [ "$verification_passed" = "true" ]; then
            echo "✅ cchistory installation verification passed"
            create_state_marker "cchistory" "npm"
            return 0
        else
            echo "❌ cchistory installation verification failed"
            return 1
        fi
    else
        echo "❌ Failed to install cchistory after $attempts attempts"
        echo "💡 Manual installation command: npm install -g @mariozechner/cchistory"
        return 1
    fi
}

# Function to install claude-trace CLI tool
install_claude_trace() {
    # Check if claude-trace is already installed
    if is_component_installed "claude-trace"; then
        echo "✅ claude-trace already installed (marker found)"
        if command -v claude-trace &> /dev/null; then
            local version=$(claude-trace --version 2>/dev/null || echo "installed")
            echo "📌 claude-trace version: $version"
            return 0
        else
            echo "⚠️  Marker exists but verification failed, reinstalling..."
            rm -f "$STATE_DIR/claude-trace.installed"
        fi
    fi
    
    echo "🔍 Installing claude-trace (Claude Code interaction recorder)..."
    
    # Ensure npm uses the correct directories for the node user
    export npm_config_prefix="/home/node/.local"
    
    # Clean any existing claude-trace directories to prevent conflicts
    echo "🧹 Cleaning any existing claude-trace directories..."
    local claude_trace_dirs=(
        "/home/node/.local/lib/node_modules/@mariozechner/claude-trace"
        "/home/node/.local/lib/node_modules/.@mariozechner-claude-trace-*"
        "/home/node/.npm/_cacache/index-v5/*/claude-trace"
    )
    
    for pattern in "${claude_trace_dirs[@]}"; do
        if [ -d "$pattern" ] || ls $pattern >/dev/null 2>&1; then
            echo "🗑️  Removing existing directory: $pattern"
            rm -rf $pattern 2>/dev/null || true
        fi
    done
    
    # Install claude-trace with error handling
    echo "📦 Attempting claude-trace installation..."
    local install_success=false
    local attempts=2
    
    for attempt in $(seq 1 $attempts); do
        echo "📦 Installation attempt $attempt/$attempts..."
        
        if npm install -g @mariozechner/claude-trace 2>/dev/null; then
            install_success=true
            break
        else
            local exit_code=$?
            echo "⚠️  Installation failed with exit code $exit_code (attempt $attempt/$attempts)"
            if [ $attempt -lt $attempts ]; then
                echo "🔄 Retrying installation..."
                sleep 2
            fi
        fi
    done
    
    if [ "$install_success" = "true" ]; then
        echo "✅ claude-trace installed successfully"
        
        # Verify installation
        echo "🔍 Verifying claude-trace installation..."
        
        # Wait for filesystem consistency
        sleep 1
        
        # Check installation indicators
        local verification_passed=false
        local claude_trace_bin="/home/node/.local/bin/claude-trace"
        local claude_trace_module="/home/node/.local/lib/node_modules/@mariozechner/claude-trace"
        
        if [ -f "$claude_trace_bin" ] && [ -d "$claude_trace_module" ]; then
            echo "✓ Binary and module directory both exist"
            
            # Test if the command actually works
            if "$claude_trace_bin" --version >/dev/null 2>&1; then
                local version=$("$claude_trace_bin" --version 2>/dev/null || echo "installed")
                echo "📌 claude-trace version: $version"
                echo "✓ Command execution test passed"
                verification_passed=true
            else
                echo "⚠️  Binary exists but command execution failed"
            fi
        elif command -v claude-trace &> /dev/null; then
            local version=$(claude-trace --version 2>/dev/null || echo "installed")
            echo "📌 claude-trace version: $version"
            echo "✓ Command found in PATH"
            verification_passed=true
        else
            echo "❌ Installation verification failed:"
            echo "   - Binary check: $([ -f "$claude_trace_bin" ] && echo "FOUND" || echo "MISSING")"
            echo "   - Module check: $([ -d "$claude_trace_module" ] && echo "FOUND" || echo "MISSING")"
            echo "   - PATH check: $(command -v claude-trace &> /dev/null && echo "FOUND" || echo "MISSING")"
        fi
        
        if [ "$verification_passed" = "true" ]; then
            echo "✅ claude-trace installation verification passed"
            create_state_marker "claude-trace" "npm"
            return 0
        else
            echo "❌ claude-trace installation verification failed"
            return 1
        fi
    else
        echo "❌ Failed to install claude-trace after $attempts attempts"
        echo "💡 Manual installation command: npm install -g @mariozechner/claude-trace"
        return 1
    fi
}

# Function to install development tools
install_dev_tools() {
    echo "🛠️  Installing additional development tools..."
    
    # Install git-delta for better git diffs  
    if command -v delta &> /dev/null; then
        echo "✅ git-delta already installed"
        # Still check and configure git if needed
        current_pager=$(git config --global core.pager 2>/dev/null || echo "")
        if [ "$current_pager" != "delta" ]; then
            echo "🔧 Configuring git to use delta..."
            git config --global core.pager "delta"
            git config --global interactive.diffFilter "delta --color-only"
            git config --global delta.navigate true
            git config --global delta.light false
            git config --global delta.side-by-side true
        else
            echo "✅ Git already configured to use delta"
        fi
    else
        echo "📦 Installing git-delta..."
        if command -v cargo &> /dev/null; then
            # If cargo is available, use it
            cargo install git-delta
        else
            # Otherwise, download the binary
            delta_version="0.18.2"
            delta_url="https://github.com/dandavison/delta/releases/download/${delta_version}/delta-${delta_version}-x86_64-unknown-linux-musl.tar.gz"
            
            if retry_command 2 5 wget -q -O /tmp/delta.tar.gz "$delta_url"; then
                sudo tar -xzf /tmp/delta.tar.gz -C /usr/local/bin delta-${delta_version}-x86_64-unknown-linux-musl/delta --strip-components=1
                sudo chmod +x /usr/local/bin/delta
                rm -f /tmp/delta.tar.gz
                echo "✅ git-delta installed successfully"
                
                # Configure git to use delta (idempotent)
                current_pager=$(git config --global core.pager 2>/dev/null || echo "")
                if [ "$current_pager" != "delta" ]; then
                    echo "🔧 Configuring git to use delta..."
                    git config --global core.pager "delta"
                    git config --global interactive.diffFilter "delta --color-only"
                    git config --global delta.navigate true
                    git config --global delta.light false
                    git config --global delta.side-by-side true
                else
                    echo "✅ Git already configured to use delta"
                fi
            else
                echo "⚠️  Failed to install git-delta"
            fi
        fi
    fi
    
    # Setup basic shell enhancements
    setup_shell_config
}

# Function to setup Claude Code environment variables
setup_claude_environment() {
    echo "🔧 Setting up Claude Code environment variables..."
    
    # Claude Code Performance and Timeout Settings (configurable via .env)
    export BASH_DEFAULT_TIMEOUT_MS="${BASH_DEFAULT_TIMEOUT_MS:-120000}"
    export BASH_MAX_TIMEOUT_MS="${BASH_MAX_TIMEOUT_MS:-600000}"
    export CLAUDE_CODE_MAX_OUTPUT_TOKENS="${CLAUDE_CODE_MAX_OUTPUT_TOKENS:-31999}"
    export MAX_THINKING_TOKENS="${MAX_THINKING_TOKENS:-62000}"
    export MAX_MCP_OUTPUT_TOKENS="${MAX_MCP_OUTPUT_TOKENS:-31999}"
    export MCP_TIMEOUT="${MCP_TIMEOUT:-60000}"
    export MCP_TOOL_TIMEOUT="${MCP_TOOL_TIMEOUT:-120000}"
    
    # Claude Code Stability Settings
    # DISABLE_AUTOUPDATER prevents Claude Code from auto-updating during work sessions
    # which can cause model selections to change and potential loss of system prompts
    export DISABLE_AUTOUPDATER="${DISABLE_AUTOUPDATER:-true}"
    
    # DISABLE_BUG_COMMAND prevents accidental bug reports in container environments
    export DISABLE_BUG_COMMAND="${DISABLE_BUG_COMMAND:-true}"
    
    # ENABLE_AUTOMATIC_TERMINAL_SETUP controls whether terminal keybindings are automatically configured
    # This performs the equivalent of Claude Code's /terminal-setup slash command
    export ENABLE_AUTOMATIC_TERMINAL_SETUP="${ENABLE_AUTOMATIC_TERMINAL_SETUP:-false}"
    
    echo "✅ Claude Code environment variables configured:"
    echo "   📊 BASH_DEFAULT_TIMEOUT_MS: $BASH_DEFAULT_TIMEOUT_MS"
    echo "   📊 BASH_MAX_TIMEOUT_MS: $BASH_MAX_TIMEOUT_MS" 
    echo "   📊 CLAUDE_CODE_MAX_OUTPUT_TOKENS: $CLAUDE_CODE_MAX_OUTPUT_TOKENS"
    echo "   📊 MAX_THINKING_TOKENS: $MAX_THINKING_TOKENS"
    echo "   📊 MAX_MCP_OUTPUT_TOKENS: $MAX_MCP_OUTPUT_TOKENS"
    echo "   📊 MCP_TIMEOUT: $MCP_TIMEOUT"
    echo "   📊 MCP_TOOL_TIMEOUT: $MCP_TOOL_TIMEOUT"
    echo "   🔒 DISABLE_AUTOUPDATER: $DISABLE_AUTOUPDATER"
    echo "   🔒 DISABLE_BUG_COMMAND: $DISABLE_BUG_COMMAND"
    echo "   ⌨️  ENABLE_AUTOMATIC_TERMINAL_SETUP: $ENABLE_AUTOMATIC_TERMINAL_SETUP"
}

# Function to setup terminal keybindings (equivalent to /terminal-setup)
setup_terminal_keybindings() {
    echo "🔧 Setting up terminal keybindings..."
    
    # Check if automatic terminal setup is enabled (default: false)
    if [ "${ENABLE_AUTOMATIC_TERMINAL_SETUP:-false}" != "true" ]; then
        echo "⏭️  Automatic terminal setup disabled (set ENABLE_AUTOMATIC_TERMINAL_SETUP=true to enable)"
        return 0
    fi
    
    local keybindings_file="/home/node/.config/Code/User/keybindings.json"
    local keybindings_dir="/home/node/.config/Code/User"
    
    # Create VSCode config directory if it doesn't exist
    if [ ! -d "$keybindings_dir" ]; then
        mkdir -p "$keybindings_dir"
        chown -R node:node "/home/node/.config/Code"
    fi
    
    # Create or update keybindings file with proper Shift+Enter setup
    if [ -f "$keybindings_file" ]; then
        # Check if Shift+Enter binding already exists and is correctly configured
        if grep -q "shift+enter" "$keybindings_file" 2>/dev/null; then
            echo "📝 Existing Shift+Enter keybinding found, validating configuration..."
            
            # Check if it's the correct terminal setup binding
            if grep -A 5 -B 5 "shift+enter" "$keybindings_file" | grep -q "workbench.action.terminal.sendSequence" && \
               grep -A 5 -B 5 "shift+enter" "$keybindings_file" | grep -q "terminalFocus"; then
                echo "✅ Correct terminal Shift+Enter keybinding already configured"
                return 0
            else
                echo "⚠️  Incorrect Shift+Enter keybinding found, replacing with correct terminal setup..."
                # Create backup
                cp "$keybindings_file" "${keybindings_file}.backup.$(date +%Y%m%d_%H%M%S)"
                
                # Remove existing Shift+Enter bindings
                if command -v jq >/dev/null 2>&1; then
                    jq 'map(select(.key != "shift+enter"))' "$keybindings_file" > "${keybindings_file}.tmp" && \
                    mv "${keybindings_file}.tmp" "$keybindings_file"
                else
                    sed -i '/shift+enter/,/}/d' "$keybindings_file"
                    sed -i 's/,\s*]/]/g' "$keybindings_file"
                    sed -i 's/,\s*}/}/g' "$keybindings_file"
                fi
            fi
        else
            echo "📝 No Shift+Enter keybinding found, adding terminal setup..."
        fi
        
        # Add the correct terminal Shift+Enter keybinding
        if command -v jq >/dev/null 2>&1; then
            # Use jq to properly add the terminal keybinding
            jq '. += [{
                "key": "shift+enter",
                "command": "workbench.action.terminal.sendSequence",
                "args": {
                    "text": "\\r\\n"
                },
                "when": "terminalFocus"
            }]' "$keybindings_file" > "${keybindings_file}.tmp" && \
            mv "${keybindings_file}.tmp" "$keybindings_file"
        else
            # Fallback: manually construct the JSON
            if [ "$(cat "$keybindings_file")" = "[]" ]; then
                # Empty array, replace entirely
                cat > "$keybindings_file" << 'EOF'
[
    {
        "key": "shift+enter",
        "command": "workbench.action.terminal.sendSequence",
        "args": {
            "text": "\\r\\n"
        },
        "when": "terminalFocus"
    }
]
EOF
            else
                # Existing content, need to insert
                # Remove the closing ] and add the new binding
                sed -i '$s/]//' "$keybindings_file"
                cat >> "$keybindings_file" << 'EOF'
    ,{
        "key": "shift+enter",
        "command": "workbench.action.terminal.sendSequence",
        "args": {
            "text": "\\r\\n"
        },
        "when": "terminalFocus"
    }
]
EOF
            fi
        fi
        
        # Validate JSON
        if ! python3 -m json.tool "$keybindings_file" >/dev/null 2>&1; then
            echo "⚠️  JSON validation failed, creating clean terminal setup..."
            cat > "$keybindings_file" << 'EOF'
[
    {
        "key": "shift+enter",
        "command": "workbench.action.terminal.sendSequence",
        "args": {
            "text": "\\r\\n"
        },
        "when": "terminalFocus"
    }
]
EOF
        fi
        
    else
        # Create new keybindings file with terminal setup
        echo "📝 Creating new keybindings.json with terminal setup..."
        cat > "$keybindings_file" << 'EOF'
[
    {
        "key": "shift+enter",
        "command": "workbench.action.terminal.sendSequence",
        "args": {
            "text": "\\r\\n"
        },
        "when": "terminalFocus"
    }
]
EOF
    fi
    
    # Set proper ownership and permissions
    chown node:node "$keybindings_file"
    chmod 644 "$keybindings_file"
    
    echo "✅ Terminal Shift+Enter keybinding configured successfully"
    echo "   💡 Shift+Enter will now send newlines in VSCode terminal (equivalent to /terminal-setup)"
}

# Function to setup enhanced ZSH configuration
setup_shell_config() {
    echo "🐚 Setting up enhanced shell configuration..."
    
    # Add PATH configuration to shell files
    shell_files=(
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
# Function to add directory to PATH without duplication
add_to_path() {
    local dir="$1"
    case ":$PATH:" in
        *":$dir:"*) ;;
        *) export PATH="$dir:$PATH" ;;
    esac
}

# Add local bin to PATH (avoiding duplicates)
add_to_path "$HOME/.local/bin"

# Source NVM (Node Version Manager)
export NVM_DIR="/usr/local/share/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Claude Code Environment Variables (configurable via .devcontainer/.env)
export BASH_DEFAULT_TIMEOUT_MS="${BASH_DEFAULT_TIMEOUT_MS:-120000}"
export BASH_MAX_TIMEOUT_MS="${BASH_MAX_TIMEOUT_MS:-600000}"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS="${CLAUDE_CODE_MAX_OUTPUT_TOKENS:-31999}"
export MAX_THINKING_TOKENS="${MAX_THINKING_TOKENS:-62000}"
export MAX_MCP_OUTPUT_TOKENS="${MAX_MCP_OUTPUT_TOKENS:-31999}"
export MCP_TIMEOUT="${MCP_TIMEOUT:-60000}"
export MCP_TOOL_TIMEOUT="${MCP_TOOL_TIMEOUT:-120000}"
export DISABLE_AUTOUPDATER="${DISABLE_AUTOUPDATER:-true}"
export DISABLE_BUG_COMMAND="${DISABLE_BUG_COMMAND:-true}"
export ENABLE_AUTOMATIC_TERMINAL_SETUP="${ENABLE_AUTOMATIC_TERMINAL_SETUP:-false}"

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

# ClaudePod usage information function
claudepod_info() {
    echo ""
    echo "🐳 ClaudePod Development Container"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 Core Tools:"
    echo "   claude               # Start Claude Code CLI"
    echo "   ccusage              # View Claude Code usage analytics"
    echo "   cchistory            # Analyze Claude Code prompt changes"
    echo "   claude-trace         # Record Claude Code interactions"
    echo ""
    echo "📊 Quick Commands:"
    echo "   ccusage              # Daily usage report"
    echo "   ccusage session      # Usage by conversation"
    echo "   cchistory 1.0.50 --latest  # Compare prompts since v1.0.50"
    echo "   cchistory --current  # View current version prompts"
    echo "   claude-trace         # Start logging Claude interactions"
    echo "   claude-trace --generate-html logs.jsonl report.html  # Create HTML report"
    echo ""
    echo "💡 Tips:"
    echo "   • Claude statusline shows real-time usage/costs"
    echo "   • Use 'gs', 'gd', 'gc' for git shortcuts"
    echo "   • Run 'claudepod_info' anytime to see this again"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Show ClaudePod info on first terminal open (once per session)
if [ ! -f "/tmp/.claudepod_info_shown_$$" ]; then
    claudepod_info
    touch "/tmp/.claudepod_info_shown_$$"
fi
EOF
        fi
        
        # Set proper ownership
        chown node:node "$shell_file"
        chmod 644 "$shell_file"
    done
    
    # Run ZSH enhancement setup as the node user if available
    if [ -f "/workspace/.devcontainer/setup-zsh.sh" ]; then
        echo "🔧 Clearing npm prefix conflicts before ZSH setup..."
        # Clear npm prefix environment variables that conflict with NVM during shell setup
        unset npm_config_prefix 2>/dev/null || true
        unset NPM_CONFIG_PREFIX 2>/dev/null || true
        
        if sudo -u node -E bash -c 'unset npm_config_prefix; unset NPM_CONFIG_PREFIX; bash /workspace/.devcontainer/setup-zsh.sh' 2>&1; then
            echo "✅ ZSH setup completed successfully"
        else
            local exit_code=$?
            echo "⚠️  ZSH setup encountered some non-critical errors (exit code: $exit_code), continuing..."
            echo "   You can manually run: sudo -u node bash /workspace/.devcontainer/setup-zsh.sh"
        fi
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
    echo "   - Claude Code CLI with statusline integration"
    echo "   - ccusage (Claude Code usage analytics)"
    echo "   - cchistory (Claude Code prompt analyzer)"
    echo "   - claude-trace (Claude Code interaction recorder)"
    echo "   - git-delta (better git diffs)"
    echo "   - Shell aliases (gs, gd, gc, gp, gl)"
    echo ""
    echo "💡 Tips:"
    echo "   • Run 'claude' to start Claude Code with statusline integration"
    echo "   • Use 'ccusage' for real-time usage analytics and cost tracking"  
    echo "   • Use 'cchistory' to analyze Claude Code prompt changes"
    echo "   • Use 'claude-trace' to record and analyze Claude interactions"
    echo "   • Terminal info shown on new terminal sessions"
    echo "   • Run 'claudepod_info' anytime for quick command reference"
    echo "════════════════════════════════════════════════════════════════"
}


# Main execution
main() {
    echo "════════════════════════════════════════════════════════════════"
    echo "🐳 ClaudePod Post-Create Setup - Phases 2 & 4"
    echo "════════════════════════════════════════════════════════════════"
    
    # Fix workspace permissions
    echo "🔧 Setting workspace permissions..."
    if [ -d "/workspace" ]; then
        sudo chown -R node:node /workspace
        sudo chmod -R u+rwX,g+rwX /workspace
    else
        echo "⚠️  /workspace directory not found - this is unexpected"
        exit 1
    fi
    
    # Setup workspace directories for bind mounts (Claude and Serena)
    setup_workspace_directories
    
    # Add node user to docker group for Docker socket access
    echo "🐳 Adding node user to docker group..."
    sudo usermod -aG docker node 2>/dev/null || echo "   Docker group already configured"
    echo "✅ Node user added to docker group"
    
    # Setup Claude Code environment variables
    setup_claude_environment
    
    # Install Claude Code
    if install_claude_code; then
        # Setup configuration directories using focused modules
        setup_claude_core_config
        echo "✓ Claude core config completed successfully"
        
        setup_serena_config
        echo "✓ Serena config completed successfully"
        
        setup_taskmaster_config
        echo "✓ TaskMaster config completed successfully"
        
        setup_searxng
        echo "✓ SearXNG setup completed successfully"
        
        # Install ccusage CLI tool
        echo "📊 Starting ccusage installation..."
        install_ccusage || echo "⚠️  Continuing without ccusage..."
        echo "✓ ccusage installation phase completed"
        
        # Install cchistory CLI tool
        echo "📊 Starting cchistory installation..."
        install_cchistory || echo "⚠️  Continuing without cchistory..."
        echo "✓ cchistory installation phase completed"
        
        # Install claude-trace CLI tool
        echo "📊 Starting claude-trace installation..."
        install_claude_trace || echo "⚠️  Continuing without claude-trace..."
        echo "✓ claude-trace installation phase completed"
        
        # Install development tools
        echo "🛠️  Starting development tools installation..."
        install_dev_tools || echo "⚠️  Continuing without some dev tools..."
        echo "✓ Development tools installation phase completed"
        
        # Setup terminal keybindings (equivalent to /terminal-setup)
        echo "⌨️  Starting terminal keybindings setup..."
        setup_terminal_keybindings || echo "⚠️  Continuing without terminal keybindings..."
        echo "✓ Terminal keybindings setup completed"
        
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
