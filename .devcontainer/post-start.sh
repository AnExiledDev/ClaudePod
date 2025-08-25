#!/bin/bash
set -euo pipefail

# ClaudePod Post-Start Script - Phase 3: MCP Server Installation
# This script handles MCP server installations that don't require API keys

echo "🚀 Starting ClaudePod MCP server setup..."

# Initial NVM setup will be handled in main() to avoid conflicts

# Source shared utility functions
source "/workspace/.devcontainer/scripts/utils.sh"

# Function to install uv via pipx
install_uv() {
    echo "📦 Installing uv package manager..."
    
    # Ensure we have the user's local bin in PATH
    export PATH="$HOME/.local/bin:$PATH"
    
    # Check if uv/uvx is already available
    if command -v uvx &> /dev/null; then
        echo "✅ uvx already available"
        return 0
    fi
    
    # Set PIPX_HOME and PIPX_BIN_DIR to user-writable locations
    export PIPX_HOME="$HOME/.local/pipx"
    export PIPX_BIN_DIR="$HOME/.local/bin"
    
    # Create directories if they don't exist
    mkdir -p "$PIPX_HOME" "$PIPX_BIN_DIR"
    
    # Check if pipx is available from Python feature
    if ! command -v pipx &> /dev/null; then
        echo "⚠️  pipx not found. Checking if it's installed via Python feature..."
        
        # The Python feature should install pipx, but it might not be in PATH yet
        if [ -f "/usr/local/py-utils/bin/pipx" ]; then
            # Use the pipx from Python feature but with user directories
            alias pipx="/usr/local/py-utils/bin/pipx"
            echo "✅ Found pipx in Python feature directory"
        else
            echo "⚠️  pipx not available. Skipping uv installation."
            return 1
        fi
    fi
    
    # Install uv with user directories
    if retry_command 3 5 /usr/local/py-utils/bin/pipx install uv; then
        echo "✅ uv installed successfully"
        
        # Verify uvx is available
        if [ -f "$HOME/.local/bin/uvx" ] || command -v uvx &> /dev/null; then
            echo "✅ uvx command available"
            return 0
        else
            echo "⚠️  uvx command not found after uv installation"
            return 1
        fi
    else
        echo "❌ Failed to install uv"
        return 1
    fi
}

# Function to validate MCP configuration
validate_mcp_configuration() {
    echo "🔍 Validating MCP configuration..."
    
    local mcp_config="/workspace/.devcontainer/config/claude/mcp.json"
    
    # Check if file exists
    if [ ! -f "$mcp_config" ]; then
        echo "⚠️  MCP configuration file not found at $mcp_config"
        return 1
    fi
    
    # Basic JSON validation
    if ! node -e "JSON.parse(require('fs').readFileSync('$mcp_config', 'utf8'))" 2>/dev/null; then
        echo "❌ MCP configuration is not valid JSON"
        # Restore from backup if available
        if [ -f "${mcp_config}.backup" ]; then
            echo "📦 Restoring from backup..."
            cp "${mcp_config}.backup" "$mcp_config"
        fi
        return 1
    fi
    
    # Test if Claude can read the configuration (if Claude is available)
    if command -v claude &> /dev/null; then
        echo "🧪 Testing Claude MCP integration..."
        if timeout 10 claude --mcp-config "$mcp_config" --print "test" &>/dev/null; then
            echo "✅ Claude MCP configuration valid"
        else
            echo "⚠️  Claude cannot load MCP configuration (authentication may be needed)"
        fi
    fi
    
    echo "✅ MCP configuration validation completed"
    return 0
}

# Function to verify MCP configuration
verify_mcp_config() {
    echo "📦 Verifying MCP server configuration..."
    
    # Check if MCP configuration file exists
    local mcp_config="/workspace/.claude/mcp.json"
    if [ ! -f "$mcp_config" ]; then
        echo "⚠️  MCP configuration file not found at $mcp_config"
        echo "   This should have been copied during post-create phase"
        return 1
    fi
    
    echo "✅ MCP configuration file found"
    
    # Verify Docker is available for GitHub MCP server
    if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && command -v docker &> /dev/null; then
        echo "🐳 Pre-pulling GitHub MCP server Docker image..."
        if docker pull ghcr.io/github/github-mcp-server:latest; then
            echo "✅ GitHub MCP server image ready"
        else
            echo "⚠️  Failed to pull GitHub MCP server Docker image"
        fi
    fi
    
    # Verify and setup SearXNG MCP server files when enabled (including container rebuilds)
    if [ "${ENABLE_SEARXNG_ENHANCED_MCP:-true}" = "true" ]; then
        echo "🔍 Verifying SearXNG MCP server installation..."
        local searxng_server="/usr/local/mcp-servers/searxng/mcp_server.py"
        local searxng_config="/home/node/.claude/ods_config.json"
        local config_template="/workspace/.devcontainer/config/searxng/ods_config.json"
        
        if [ -f "$searxng_server" ]; then
            echo "✅ SearXNG MCP server files found"
            
            # Handle configuration during container rebuilds with existence check
            if [ -f "$searxng_config" ]; then
                echo "✅ SearXNG configuration file ready"
            else
                echo "📋 SearXNG configuration not found, copying from template..."
                
                # Source searxng script to get setup functions
                if [ -f "/workspace/.devcontainer/scripts/config/searxng.sh" ]; then
                    source "/workspace/.devcontainer/scripts/config/searxng.sh"
                    
                    # Call configuration setup function
                    setup_searxng_config || {
                        echo "⚠️  Failed to setup SearXNG configuration during container rebuild"
                        echo "   You can manually copy with: cp $config_template $searxng_config"
                    }
                else
                    echo "⚠️  SearXNG setup script not found, performing basic copy..."
                    
                    # Ensure Claude directory exists
                    mkdir -p "/home/node/.claude"
                    
                    # Copy configuration file if template exists
                    if [ -f "$config_template" ]; then
                        cp "$config_template" "$searxng_config"
                        chown node:node "$searxng_config"
                        chmod 600 "$searxng_config"
                        echo "📋 SearXNG configuration copied from template"
                    else
                        echo "⚠️  SearXNG configuration template not found at $config_template"
                    fi
                fi
            fi
        else
            echo "❌ SearXNG MCP server not found at $searxng_server"
            echo "   Installation may have failed during post-create phase"
            echo "   Try running: bash /workspace/.devcontainer/scripts/config/searxng.sh"
        fi
    fi
    
    return 0
}

# Function to validate environment variables and provide feedback
validate_environment_variables() {
    echo "🔍 Validating environment configuration..."
    
    local missing_keys=()
    local optional_keys=()
    
    # Check optional API keys and track status
    if [ "${ENABLE_TAVILY_MCP:-false}" = "true" ]; then
        if [ -z "$TAVILY_API_KEY" ]; then
            missing_keys+=("TAVILY_API_KEY")
        fi
    fi
    
    if [ "${ENABLE_REF_TOOLS_MCP:-false}" = "true" ]; then
        if [ -z "$REF_TOOLS_API_KEY" ]; then
            missing_keys+=("REF_TOOLS_API_KEY")
        fi
    fi
    
    if [ "${ENABLE_GITHUB_MCP:-false}" = "true" ]; then
        if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
            missing_keys+=("GITHUB_PERSONAL_ACCESS_TOKEN")
        fi
    fi
    
    # Report validation results
    if [ ${#missing_keys[@]} -eq 0 ]; then
        echo "✅ All required environment variables configured"
    else
        echo "⚠️  Missing API keys for enabled services:"
        for key in "${missing_keys[@]}"; do
            echo "   • $key"
        done
        echo "   📝 Add missing keys to .devcontainer/.env or disable services"
    fi
}

# Function to display startup status summary
display_startup_status() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║ 📊 ClaudePod Status Summary                                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    
    # Core tools status
    echo ""
    echo "🛠️  Core Tools:"
    local claude_version=$(claude --version 2>/dev/null || echo "Not available")
    echo "   Claude Code: $claude_version"
    
    local ccusage_version=$(ccusage --version 2>/dev/null || echo "Not available")
    echo "   ccusage: $ccusage_version"
    
    # Check Node.js with proper environment sourcing
    local node_version="Not available"
    if command -v node &>/dev/null; then
        node_version=$(node --version 2>/dev/null || echo "Not available")
    elif [ -s "/usr/local/share/nvm/nvm.sh" ]; then
        # Try sourcing NVM if Node.js not found in PATH (permissions should now be fixed)
        if source "/usr/local/share/nvm/nvm.sh"; then
            if command -v node &>/dev/null; then
                node_version=$(node --version 2>/dev/null || echo "Not available")
            fi
        else
            node_version="NVM sourcing failed"
        fi
    fi
    echo "   Node.js: $node_version"
    
    local uvx_status=$(command -v uvx &>/dev/null && echo "Available" || echo "Not available")
    echo "   uvx: $uvx_status"
    
    # MCP servers status
    echo ""
    echo "🔌 MCP Servers:"
    local enabled_count=0
    local disabled_count=0
    
    # Core servers (enabled by default)
    # for server in "serena:ENABLE_SERENA_MCP:semantic code analysis" \
    #               "deepwiki:ENABLE_DEEPWIKI_MCP:documentation search" \
    #               "taskmaster:ENABLE_TASKMASTER_MCP:project management" \
    #               "sequential-thinking:ENABLE_SEQUENTIAL_THINKING_MCP:structured analysis" \
    #               "ccusage:ENABLE_CCUSAGE_MCP:usage analytics"; do
    #     IFS=':' read -r name var desc <<< "$server"
    #     if [ "${!var:-true}" = "true" ]; then
    #         echo "   ✅ $name ($desc)"
    #         ((enabled_count++))
    #     else
    #         echo "   ❌ $name (disabled)"
    #         ((disabled_count++))
    #     fi
    # done
    
    # Optional servers (require API keys)
    # for server in "tavily:ENABLE_TAVILY_MCP:TAVILY_API_KEY:web search" \
    #               "ref-tools:ENABLE_REF_TOOLS_MCP:REF_TOOLS_API_KEY:reference docs" \
    #               "github:ENABLE_GITHUB_MCP:GITHUB_PERSONAL_ACCESS_TOKEN:repository integration"; do
    #     IFS=':' read -r name var key desc <<< "$server"
    #     if [ "${!var:-false}" = "true" ] && [ -n "${!key}" ]; then
    #         echo "   ✅ $name ($desc)"
    #         ((enabled_count++))
    #     elif [ "${!var:-false}" = "true" ]; then
    #         echo "   ⚠️  $name (missing $key)"
    #         ((disabled_count++))
    #     else
    #         echo "   ❌ $name (disabled)"
    #         ((disabled_count++))
    #     fi
    # done
    
    # Shell shortcuts
    echo ""
    echo "⌨️  Shell Shortcuts:"
    echo "   gs (git status)  gd (git diff)   gc (git commit)"
    echo "   gp (git push)    gl (git log)    ll (list files)"
    
    # Summary and next steps
    echo ""
    echo "📈 Summary: $enabled_count servers enabled, $disabled_count disabled"
    echo ""
    echo "🚀 Ready to start:"
    echo "   claude                    # Start Claude Code with MCP servers"
    echo "   claude mcp list          # Verify MCP server connectivity"
    echo "   ccusage                  # View usage analytics"
    
    # Add SearXNG info if it exists
    local searxng_local_dir="${SEARXNG_LOCAL_INSTALL_DIR:-/opt/searxng-local}"
    if [ "${ENABLE_SEARXNG_LOCAL:-true}" = "true" ] && [ -d "$searxng_local_dir" ] && [ -f "$searxng_local_dir/docker-compose.yaml" ]; then
        echo ""
        echo "🔍 Local SearXNG Instance:"
        echo "   http://localhost:8080    # SearXNG web interface"
        echo "   MCP server configured for zero rate limiting"
        echo "   Location: $searxng_local_dir (persistent volume)"
    fi
    echo ""
    echo "════════════════════════════════════════════════════════════════"
}

# Function to start local SearXNG containers if configured
start_local_searxng() {
    # Check if SearXNG local instance is enabled
    if [ "${ENABLE_SEARXNG_LOCAL:-true}" != "true" ]; then
        echo "   ℹ️  SearXNG local instance is disabled (using public instances)"
        return 0
    fi
    
    # Source the searxng configuration functions
    source "/workspace/.devcontainer/scripts/config/searxng.sh"
    
    # Use the new function to start the persistent local instance
    start_searxng_local_instance
}

# Function to display completion message
display_completion_message() {
    # Validate environment first
    validate_environment_variables
    
    echo ""
    echo "✅ ClaudePod Phase 3 MCP setup complete!"
    
    # Display comprehensive startup status
    display_startup_status
}

# Main execution
main() {
    echo "════════════════════════════════════════════════════════════════"
    echo "🐳 ClaudePod Post-Start Setup - Phase 3: MCP Servers"
    echo "════════════════════════════════════════════════════════════════"
    
    # Ensure .claude directory exists and preserve optimized settings
    echo "🔧 Configuring Claude Code settings..."
    mkdir -p /workspace/.claude
    
    # Only create basic settings if optimized settings don't exist
    if [ ! -f "/workspace/.claude/settings.json" ]; then
        echo "   Creating basic Claude settings..."
        cat > /workspace/.claude/settings.json << 'EOF'
{
  "includeCoAuthoredBy": false,
  "model": "claude-sonnet-4-0",
  "forceLoginMethod": "claudeai"
}
EOF
        echo "   ℹ️  Basic settings created (optimized settings not found)"
    else
        # Check if settings contain the optimized permissions
        if grep -q '"permissions"' "/workspace/.claude/settings.json" 2>/dev/null; then
            local allowed_count=$(grep -o '"allow"' "/workspace/.claude/settings.json" | wc -l)
            local denied_count=$(grep -o '"deny"' "/workspace/.claude/settings.json" | wc -l)
            echo "   ✅ Preserving optimized Claude settings (permissions configured)"
        else
            echo "   ⚠️  Existing settings found but no optimized permissions detected"
        fi
    fi
    
    echo "✅ Claude Code settings configured"
    
    # Ensure Serena configuration exists and preserve optimized settings
    echo "🔧 Configuring Serena settings..."
    mkdir -p /workspace/.serena
    
    if [ ! -f "/workspace/.serena/serena_config.yml" ]; then
        echo "   ℹ️  No existing Serena configuration found (will use defaults)"
    else
        echo "   ✅ Preserving existing Serena configuration"
    fi
    
    # Ensure TaskMaster configuration exists and preserve optimized settings
    echo "🔧 Configuring TaskMaster settings..."
    mkdir -p /workspace/.taskmaster
    
    if [ ! -f "/workspace/.taskmaster/config.json" ]; then
        echo "   ℹ️  No existing TaskMaster configuration found (will use defaults)"
    else
        # Check if settings contain the optimized model configuration
        if grep -q '"claude-code"' "/workspace/.taskmaster/config.json" 2>/dev/null; then
            echo "   ✅ Preserving optimized TaskMaster configuration (Claude Code integration)"
        else
            echo "   ⚠️  Existing TaskMaster configuration found but no Claude Code integration detected"
        fi
    fi
    
    echo "✅ MCP configurations ready"
    
    # Environment variables already loaded in post-create.sh
    # Set environment for proper Node.js and Claude Code operation
    echo "🔧 Configuring Node.js environment..."
    
    # Source NVM to make Node.js and npm available (needed for MCP config generation)
    export NVM_DIR="/usr/local/share/nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        echo "🔧 Sourcing NVM in post-start..."
        . "$NVM_DIR/nvm.sh"
        
        # Handle potential npm prefix conflicts with NVM
        if command -v nvm &> /dev/null && command -v node &> /dev/null; then
            echo "🔧 Checking NVM/npm prefix conflicts..."
            # Only run nvm use if there's actually a prefix conflict, not just because Node.js exists
            local current_prefix=$(npm config get prefix 2>/dev/null || echo "")
            local expected_prefix="/home/node/.local"
            
            if [ -n "$current_prefix" ] && [ "$current_prefix" != "$expected_prefix" ]; then
                echo "🔧 Resolving npm prefix conflict by removing conflicting settings"
                # Remove prefix settings that conflict with NVM instead of setting them
                npm config delete prefix 2>/dev/null || true
                npm config delete globalconfig 2>/dev/null || true
                echo "✅ Removed conflicting npm prefix settings for NVM compatibility"
            else
                echo "✅ NVM/npm prefix already correct"
            fi
        fi
        
        # Verify Node.js is now available
        if command -v node &> /dev/null; then
            echo "✅ Node.js available for MCP generation: $(node --version)"
        else
            echo "⚠️  Node.js still not available after sourcing NVM"
        fi
    else
        echo "⚠️  NVM not found at $NVM_DIR/nvm.sh"
    fi
    
    # Set PATH and HOME for proper Claude Code operation
    export PATH="/home/node/.local/bin:$PATH"
    export HOME="/home/node"
    
    # Ensure proper ownership of .local directory
    chown -R node:node /home/node/.local 2>/dev/null || true
    
    # CRITICAL: Re-load environment variables from .devcontainer/.env
    # Why this is needed AGAIN after post-create.sh:
    # - Environment variables set in post-create.sh are only available during that shell session
    # - Container restarts/rebuilds lose those environment variables since they're not persisted
    # - MCP config generation happens during post-start phase and requires API keys from .env
    # - Without this re-loading, MCP servers requiring API keys will be disabled due to missing env vars
    if [ -f "/workspace/.devcontainer/.env" ]; then
        echo "📋 Re-loading environment variables from .devcontainer/.env (required after container rebuild)"
        set -a  # Export all variables
        source "/workspace/.devcontainer/.env"
        set +a  # Stop exporting
        echo "✅ Environment variables reloaded for MCP server configuration"
    else
        echo "⚠️  .devcontainer/.env file not found - MCP servers requiring API keys will be disabled"
    fi
    
    # Generate MCP configuration from template
    echo "🔧 Generating MCP configuration from template..."
    if [ -f "/workspace/.devcontainer/config/claude/mcp.json.template" ]; then
        # Use Node.js to generate configuration with environment loaded
        if command -v node &> /dev/null; then
            # Ensure script is executable and run with explicit node
            # Note: The script now uses dotenv to load environment variables directly
            chmod +x /workspace/.devcontainer/scripts/generate-mcp-config.js
            if node /workspace/.devcontainer/scripts/generate-mcp-config.js; then
                echo "✅ MCP configuration generated successfully"
                # Validate generated configuration
                validate_mcp_configuration
            else
                echo "⚠️  Failed to generate MCP configuration from template"
                echo "   Fallback: using existing mcp.json if available"
            fi
        else
            echo "⚠️  Node.js not available - cannot generate MCP configuration"
            echo "   Using existing mcp.json configuration"
        fi
    else
        echo "ℹ️  No MCP template found - using existing configuration"
    fi
    
    # Check if Claude is available with detailed debugging
    echo "🔍 Checking Claude Code availability..."
    echo "   PATH: $PATH"
    echo "   Current user: $(whoami)"
    echo "   Home directory: $HOME"
    
    if command -v claude &> /dev/null; then
        echo "✅ Claude Code found in PATH: $(which claude)"
    elif [ -f "/home/node/.local/bin/claude" ]; then
        echo "✅ Claude Code found at: /home/node/.local/bin/claude"
        # Ensure it's executable
        chmod +x /home/node/.local/bin/claude
    else
        echo "❌ Claude Code not found. Checking installation..."
        echo "   Contents of /home/node/.local/bin/:"
        ls -la /home/node/.local/bin/ 2>/dev/null || echo "   Directory not found"
        echo "   Searching for claude binary:"
        find /home/node/.local -name "claude*" -type f 2>/dev/null || echo "   No claude binary found"
        echo ""
        echo "   Please ensure Phase 2 (post-create) completed successfully."
        echo "   You can manually install Claude Code with:"
        echo "   npm install -g @anthropic-ai/claude-code"
        exit 1
    fi
    
    echo "✅ Claude Code is available"
    
    # Test Claude MCP functionality
    echo "🧪 Testing Claude MCP functionality..."
    if claude mcp list &>/dev/null; then
        echo "✅ Claude MCP commands working"
    else
        echo "⚠️  Claude MCP commands may not be fully initialized"
        echo "   This is normal for first run - continuing with installation..."
    fi
    
    echo "✅ Node.js environment configured"
    
    # Install uv (for future MCP servers that might need it)
    install_uv || echo "⚠️  Continuing without uv/uvx..."
    
    # Start SearXNG containers if configured for local instance
    echo "🔍 Checking SearXNG container setup..."
    start_local_searxng
    
    # Verify MCP configuration instead of installing servers
    if verify_mcp_config; then
        display_completion_message
        exit 0
    else
        echo "⚠️  MCP configuration verification failed."
        echo "   MCP servers are configured via mcp.json file."
        echo "   Check that the file was copied correctly during post-create phase."
        exit 0
    fi
}

# Execute main function
main
