#!/bin/bash
set -euo pipefail

# ClaudePod Post-Start Script - Phase 3: MCP Server Installation
# This script handles MCP server installations that don't require API keys

echo "🚀 Starting ClaudePod MCP server setup..."

# Initial NVM setup will be handled in main() to avoid conflicts

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

# Function to clean up existing MCP servers
cleanup_mcp_servers() {
    echo "🧹 Cleaning up existing MCP server configurations..."
    
    # Get list of existing servers
    local existing_servers=$(claude mcp list 2>/dev/null | grep -E "^(serena|deepwiki|tavily-search|ref-tools|taskmaster-ai|sequential-thinking):" | cut -d: -f1 || true)
    
    if [ -n "$existing_servers" ]; then
        echo "$existing_servers" | while read -r server; do
            if [ -n "$server" ]; then
                echo "   Removing $server..."
                claude mcp remove "$server" 2>/dev/null || true
            fi
        done
        echo "✅ Cleanup complete"
    else
        echo "✅ No existing servers to clean up"
    fi
}

# Function to install MCP servers
install_mcp_servers() {
    echo "📦 Installing core MCP servers..."
    
    local servers_installed=0
    local servers_failed=0
    
    # Install Serena MCP server
    echo ""
    echo "🔧 Installing Serena MCP server..."
    if retry_command 2 3 claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project /workspace --enable-web-dashboard false; then
        echo "✅ Serena MCP server installed"
        ((servers_installed++))
    else
        echo "⚠️  Serena MCP server installation failed"
        ((servers_failed++))
    fi
    
    # Install DeepWiki HTTP MCP server
    echo ""
    echo "🔧 Installing DeepWiki MCP server..."
    if retry_command 2 3 claude mcp add --transport http deepwiki https://mcp.deepwiki.com/mcp; then
        echo "✅ DeepWiki MCP server installed"
        ((servers_installed++))
    else
        echo "⚠️  DeepWiki MCP server installation failed"
        ((servers_failed++))
    fi
    
    # Install Tavily Search MCP server (if API key provided)
    if [ -n "$TAVILY_API_KEY" ]; then
        echo ""
        echo "🔧 Installing Tavily Search MCP server..."
        if retry_command 2 3 claude mcp add --transport http tavily-search "https://mcp.tavily.com/mcp/?tavilyApiKey=$TAVILY_API_KEY"; then
            echo "✅ Tavily Search MCP server installed"
            ((servers_installed++))
        else
            echo "⚠️  Tavily Search MCP server installation failed"
            ((servers_failed++))
        fi
    else
        echo ""
        echo "ℹ️  Skipping Tavily Search MCP server (no TAVILY_API_KEY set)"
    fi
    
    # Install Ref.Tools MCP server (if API key provided)
    if [ -n "$REF_TOOLS_API_KEY" ]; then
        echo ""
        echo "🔧 Installing Ref.Tools MCP server..."
        if retry_command 2 3 claude mcp add --transport http ref-tools "https://api.ref.tools/mcp?apiKey=$REF_TOOLS_API_KEY"; then
            echo "✅ Ref.Tools MCP server installed"
            ((servers_installed++))
        else
            echo "⚠️  Ref.Tools MCP server installation failed"
            ((servers_failed++))
        fi
    else
        echo ""
        echo "ℹ️  Skipping Ref.Tools MCP server (no REF_TOOLS_API_KEY set)"
    fi
    
    # Install Task Master MCP server (no API key required for Claude Code)
    echo ""
    echo "🔧 Installing Task Master MCP server..."
    if retry_command 2 3 claude mcp add taskmaster-ai -- npx -y --package=task-master-ai task-master-ai; then
        echo "✅ Task Master MCP server installed"
        ((servers_installed++))
    else
        echo "⚠️  Task Master MCP server installation failed"
        ((servers_failed++))
    fi
    
    # Install Sequential Thinking MCP server (no API key required)
    echo ""
    echo "🔧 Installing Sequential Thinking MCP server..."
    if retry_command 2 3 claude mcp add sequential-thinking -- uvx --from git+https://github.com/arben-adm/mcp-sequential-thinking.git --with portalocker mcp-sequential-thinking; then
        echo "✅ Sequential Thinking MCP server installed"
        ((servers_installed++))
    else
        echo "⚠️  Sequential Thinking MCP server installation failed"
        ((servers_failed++))
    fi
    
    # Install ccusage MCP server (no API key required)
    echo ""
    echo "🔧 Installing ccusage MCP server..."
    if retry_command 2 3 claude mcp add ccusage -- ccusage mcp; then
        echo "✅ ccusage MCP server installed"
        ((servers_installed++))
    else
        echo "⚠️  ccusage MCP server installation failed"
        ((servers_failed++))
    fi
    
    # Install GitHub MCP server (if GitHub PAT is provided and Docker is available)
    if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && command -v docker &> /dev/null; then
        echo ""
        echo "🔧 Installing GitHub MCP server..."
        # Pull the Docker image first to ensure it's available
        if docker pull ghcr.io/github/github-mcp-server:latest; then
            # Install using the complete Docker command
            if retry_command 2 3 claude mcp add github -- docker run --rm -i \
                -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
                ${GITHUB_API_URL:+-e GITHUB_API_URL="$GITHUB_API_URL"} \
                ${GITHUB_TOOLSET:+-e GITHUB_TOOLSET="$GITHUB_TOOLSET"} \
                ghcr.io/github/github-mcp-server:latest; then
                echo "✅ GitHub MCP server installed"
                ((servers_installed++))
            else
                echo "⚠️  GitHub MCP server installation failed"
                ((servers_failed++))
            fi
        else
            echo "⚠️  Failed to pull GitHub MCP server Docker image"
            ((servers_failed++))
        fi
    else
        echo ""
        if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
            echo "ℹ️  Skipping GitHub MCP server (no GITHUB_PERSONAL_ACCESS_TOKEN set)"
        elif ! command -v docker &> /dev/null; then
            echo "ℹ️  Skipping GitHub MCP server (Docker not available)"
        fi
    fi
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "📊 MCP Server Installation Summary:"
    echo "   ✅ Installed: $servers_installed servers"
    echo "   ⚠️  Failed: $servers_failed servers"
    echo "════════════════════════════════════════════════════════════════"
    
    # Return success if we have any servers installed
    [ $servers_installed -gt 0 ]
}

# Function to display completion message
display_completion_message() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "✅ ClaudePod Phase 3 MCP setup complete!"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "📋 Available MCP servers:"
    claude mcp list 2>/dev/null || echo "   Run 'claude mcp list' to see installed servers"
    echo ""
    echo "💡 Tips:"
    echo "   - Use 'claude' to start working with MCP servers"
    echo "   - Add API keys to enable additional servers"
    echo "   - Check 'claude mcp list' to verify installations"
    echo "════════════════════════════════════════════════════════════════"
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
    
    # Source .env file if it exists
    if [ -f "/workspace/.devcontainer/.env" ]; then
        echo "🔧 Loading environment variables from .devcontainer/.env file..."
        set -a  # automatically export all variables
        source /workspace/.devcontainer/.env
        set +a  # disable automatic export
        echo "✅ Environment variables loaded"
    fi
    
    # Fix NVM permissions and conflicts
    echo "🔧 Resolving NVM configuration conflicts..."
    
    # Temporarily rename .npmrc to avoid NVM conflicts during sourcing
    if [ -f "/home/node/.npmrc" ]; then
        mv "/home/node/.npmrc" "/home/node/.npmrc.bak"
    fi
    
    # Source NVM without conflicts
    export NVM_DIR="/usr/local/share/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Restore .npmrc after NVM is sourced
    if [ -f "/home/node/.npmrc.bak" ]; then
        mv "/home/node/.npmrc.bak" "/home/node/.npmrc"
    fi
    
    # Set PATH and HOME for proper Claude Code operation
    export PATH="/home/node/.local/bin:$PATH"
    export HOME="/home/node"
    
    # Ensure proper ownership of .local directory
    chown -R node:node /home/node/.local 2>/dev/null || true
    
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
    
    echo "✅ NVM configuration resolved"
    
    # Install uv (for future MCP servers that might need it)
    install_uv || echo "⚠️  Continuing without uv/uvx..."
    
    # Clean up any existing MCP server configurations
    cleanup_mcp_servers
    
    # Install MCP servers fresh
    if install_mcp_servers; then
        display_completion_message
        exit 0
    else
        echo "⚠️  No MCP servers were installed."
        echo "   You can try installing them manually later."
        exit 0
    fi
}

# Execute main function
main
