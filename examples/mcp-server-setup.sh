#!/bin/bash
# Additional MCP Server Setup - API Key Required Servers
# These servers require API keys and are not installed by default

# Tavily Search MCP Server
# Provides web search capabilities to Claude
# Get your API key from: https://tavily.com/
install_tavily_search() {
    if [ -z "$TAVILY_API_KEY" ]; then
        echo "❌ TAVILY_API_KEY not set. Get one from https://tavily.com/"
        return 1
    fi
    
    echo "🔧 Installing Tavily Search MCP server..."
    if claude mcp add --transport http tavily-search "https://mcp.tavily.com/mcp/?tavilyApiKey=$TAVILY_API_KEY"; then
        echo "✅ Tavily Search MCP server installed"
    else
        echo "⚠️  Tavily Search MCP server installation failed"
    fi
}

# Ref.Tools MCP Server  
# Provides reference and documentation tools
# Get your API key from: https://ref.tools/
install_ref_tools() {
    if [ -z "$REF_TOOLS_API_KEY" ]; then
        echo "❌ REF_TOOLS_API_KEY not set. Get one from https://ref.tools/"
        return 1
    fi
    
    echo "🔧 Installing Ref.Tools MCP server..."
    if claude mcp add --transport http ref-tools "https://api.ref.tools/mcp?apiKey=$REF_TOOLS_API_KEY"; then
        echo "✅ Ref.Tools MCP server installed"
    else
        echo "⚠️  Ref.Tools MCP server installation failed"
    fi
}

# GitHub MCP Server
# Provides GitHub integration capabilities
# Get your PAT from: https://github.com/settings/tokens
install_github_mcp() {
    if [ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
        echo "❌ GITHUB_PERSONAL_ACCESS_TOKEN not set. Get one from https://github.com/settings/tokens"
        echo "   Minimum scopes: repo, read:packages"
        return 1
    fi
    
    echo "🔧 Installing GitHub MCP server..."
    if command -v docker &> /dev/null; then
        if claude mcp add github -- docker run --rm -i \
            -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
            ${GITHUB_API_URL:+-e GITHUB_API_URL="$GITHUB_API_URL"} \
            ${GITHUB_TOOLSET:+-e GITHUB_TOOLSET="$GITHUB_TOOLSET"} \
            ghcr.io/github/github-mcp-server:latest; then
            echo "✅ GitHub MCP server installed"
        else
            echo "⚠️  GitHub MCP server installation failed"
        fi
    else
        echo "❌ Docker not found - required for GitHub MCP server"
        return 1
    fi
}

# Main installation
echo "📦 Installing additional MCP servers with API keys..."
echo ""

# Export your API keys first:
# export TAVILY_API_KEY="your-tavily-api-key"
# export REF_TOOLS_API_KEY="your-ref-tools-api-key"
# export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"

install_tavily_search
echo ""
install_ref_tools
echo ""
install_github_mcp

echo ""
echo "✅ Additional MCP server setup complete!"
echo "📋 Run 'claude mcp list' to see all installed servers"