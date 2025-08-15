#!/bin/bash
# GitHub MCP Server Installation Script
# Installs and configures the GitHub MCP server for Claude Code

set -e

echo "🚀 Installing GitHub MCP Server..."
echo ""

# Check if Claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "❌ Claude CLI not found. Please install Claude Code first."
    exit 1
fi

# Function to install GitHub MCP server
install_github_mcp() {
    local server_url="ghcr.io/github/github-mcp-server:latest"
    local server_name="github"
    
    echo "🔧 Installing GitHub MCP server..."
    
    # Check if Docker is available
    if command -v docker &> /dev/null; then
        echo "✅ Docker found - using Docker-based installation"
        
        # Pull the GitHub MCP server Docker image
        if docker pull "$server_url"; then
            echo "✅ GitHub MCP server Docker image pulled successfully"
        else
            echo "⚠️  Failed to pull Docker image, trying alternative installation..."
            return 1
        fi
        
        # Add the GitHub MCP server to Claude
        if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
            echo "🔑 Using GitHub Personal Access Token from environment"
            
            # Configure with Docker and environment variables
            if claude mcp add "$server_name" -- docker run --rm -i \
                -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
                ${GITHUB_API_URL:+-e GITHUB_API_URL="$GITHUB_API_URL"} \
                ${GITHUB_TOOLSET:+-e GITHUB_TOOLSET="$GITHUB_TOOLSET"} \
                "$server_url"; then
                echo "✅ GitHub MCP server installed with Docker and PAT"
                return 0
            else
                echo "⚠️  Failed to install GitHub MCP server with Docker"
                return 1
            fi
        else
            echo "❌ GITHUB_PERSONAL_ACCESS_TOKEN not set"
            echo "   Please set your GitHub Personal Access Token:"
            echo "   export GITHUB_PERSONAL_ACCESS_TOKEN=\"ghp_your_token_here\""
            return 1
        fi
    else
        echo "❌ Docker not found. Docker is required for GitHub MCP server installation."
        echo "   Please install Docker first or use a different installation method."
        return 1
    fi
}

# Function to verify installation
verify_installation() {
    echo ""
    echo "🔍 Verifying GitHub MCP server installation..."
    
    if claude mcp list | grep -q "github"; then
        echo "✅ GitHub MCP server found in Claude configuration"
        return 0
    else
        echo "⚠️  GitHub MCP server not found in Claude configuration"
        return 1
    fi
}

# Function to display configuration info
show_configuration() {
    echo ""
    echo "📋 GitHub MCP Server Configuration:"
    echo "   Server Name: github"
    echo "   Authentication: Personal Access Token (PAT)"
    echo "   Required Token Scopes: repo, read:packages (minimum)"
    echo ""
    echo "🔧 Environment Variables:"
    echo "   GITHUB_PERSONAL_ACCESS_TOKEN (required): Your GitHub PAT"
    echo "   GITHUB_API_URL (optional): Custom GitHub API endpoint"
    echo "   GITHUB_TOOLSET (optional): Comma-separated toolsets to enable"
    echo ""
    echo "🛠️  Available Toolsets:"
    echo "   - context: Repository and file access"
    echo "   - actions: GitHub Actions management"
    echo "   - code_security: Security analysis tools"
    echo "   - dependabot: Dependency management"
    echo "   - discussions: GitHub Discussions"
    echo "   - issues: Issue management"
    echo "   - pull_requests: PR management"
    echo ""
}

# Main installation flow
echo "📦 Starting GitHub MCP Server installation..."
echo ""

# Show current environment status
if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
    echo "✅ GITHUB_PERSONAL_ACCESS_TOKEN is set (${#GITHUB_PERSONAL_ACCESS_TOKEN} characters)"
else
    echo "❌ GITHUB_PERSONAL_ACCESS_TOKEN is not set"
    echo ""
    echo "🔑 To get a GitHub Personal Access Token:"
    echo "   1. Go to https://github.com/settings/tokens"
    echo "   2. Click 'Generate new token (classic)'"
    echo "   3. Select scopes: repo, read:packages (minimum recommended)"
    echo "   4. Copy the token and export it:"
    echo "      export GITHUB_PERSONAL_ACCESS_TOKEN=\"ghp_your_token_here\""
    echo ""
    echo "❓ Do you want to continue without a token? (installation will fail)"
    read -p "Continue? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "🛑 Installation cancelled. Please set your GitHub token and try again."
        exit 1
    fi
fi

# Optional toolset configuration
if [ -z "$GITHUB_TOOLSET" ]; then
    echo "🛠️  No custom toolset specified. Using default GitHub MCP server toolsets."
    echo "   Set GITHUB_TOOLSET environment variable to customize (e.g., 'context,issues,pull_requests')"
else
    echo "🛠️  Using custom toolset: $GITHUB_TOOLSET"
fi

echo ""

# Perform installation
if install_github_mcp; then
    echo ""
    echo "🎉 GitHub MCP Server installation completed successfully!"
    
    # Verify installation
    if verify_installation; then
        echo ""
        echo "✅ Installation verified - GitHub MCP server is ready to use!"
    else
        echo ""
        echo "⚠️  Installation completed but verification failed"
        echo "   Run 'claude mcp list' to check server status"
    fi
else
    echo ""
    echo "❌ GitHub MCP Server installation failed"
    echo "   Check the error messages above and try again"
    echo "   Make sure Docker is installed and GITHUB_PERSONAL_ACCESS_TOKEN is set"
    exit 1
fi

# Show configuration information
show_configuration

echo "🚀 Ready to use GitHub MCP Server with Claude Code!"
echo "   Try: claude (then ask Claude to list your GitHub repositories)"
echo ""