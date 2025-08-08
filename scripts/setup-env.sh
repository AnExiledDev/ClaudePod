#!/bin/bash
# ClaudePod Environment Setup Script
# Run this script to customize your environment after container startup

set -e

echo "🚀 ClaudePod Environment Setup"
echo "This script helps you customize your development environment"

# Function to prompt for user input
prompt_user() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        eval "$var_name=\"${input:-$default}\""
    else
        read -p "$prompt: " input
        eval "$var_name=\"$input\""
    fi
}

# Git configuration
echo ""
echo "📝 Git Configuration"
if ! git config --global user.name > /dev/null 2>&1; then
    prompt_user "Enter your Git username" GIT_NAME
    prompt_user "Enter your Git email" GIT_EMAIL
    
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    echo "✅ Git user configuration set"
else
    echo "✅ Git already configured for $(git config --global user.name)"
fi

# GitHub CLI authentication
echo ""
echo "🔐 GitHub CLI Authentication"
if ! gh auth status > /dev/null 2>&1; then
    echo "GitHub CLI is not authenticated."
    read -p "Would you like to authenticate now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gh auth login
        echo "✅ GitHub CLI authenticated"
    else
        echo "⏭️  Skipping GitHub CLI authentication"
    fi
else
    echo "✅ GitHub CLI already authenticated"
fi

# Claude Code authentication
echo ""
echo "🤖 Claude Code Authentication" 
if ! claude --version > /dev/null 2>&1; then
    echo "❌ Claude Code not found. Please check your installation."
else
    echo "✅ Claude Code is available"
    echo "💡 Run 'claude' to authenticate and start using Claude Code"
fi

# GitHub Environment Setup
echo ""
echo "🐙 GitHub Environment Variables"
if [ -f "/workspace/.env" ]; then
    echo "Environment file found: /workspace/.env"
    
    # Source environment variables
    set -a  # automatically export all variables
    source /workspace/.env
    set +a  # turn off auto-export
    
    # Check GitHub PAT
    if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ] && [ "$GITHUB_PERSONAL_ACCESS_TOKEN" != "ghp_your-github-personal-access-token-here" ]; then
        echo "✅ GitHub Personal Access Token is configured"
        
        # Validate GitHub environment
        if [ -f "/workspace/scripts/validate-github-env.sh" ]; then
            echo "🔍 Validating GitHub environment..."
            if bash /workspace/scripts/validate-github-env.sh; then
                echo "✅ GitHub environment validation passed"
            else
                echo "⚠️  GitHub environment validation failed"
                echo "   Check your token and try running: bash /workspace/scripts/validate-github-env.sh"
            fi
        fi
    else
        echo "⚠️  GitHub Personal Access Token not configured"
        read -p "Would you like to set up GitHub integration now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            echo "🔑 GitHub Personal Access Token Setup"
            echo "   1. Go to https://github.com/settings/tokens"
            echo "   2. Click 'Generate new token (classic)'"
            echo "   3. Select scopes: repo, read:packages (minimum)"
            echo "   4. Copy the token and paste it when prompted"
            echo ""
            prompt_user "Enter your GitHub Personal Access Token" GITHUB_TOKEN
            
            # Update .env file
            if grep -q "GITHUB_PERSONAL_ACCESS_TOKEN" /workspace/.env; then
                # Update existing entry
                sed -i "s/GITHUB_PERSONAL_ACCESS_TOKEN=.*/GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_TOKEN/" /workspace/.env
            else
                # Add new entry
                echo "GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_TOKEN" >> /workspace/.env
            fi
            
            echo "✅ GitHub Personal Access Token saved to /workspace/.env"
            echo "🔄 Please restart your container to apply changes"
        fi
    fi
else
    echo "No environment file found. Creating /workspace/.env..."
    cat > /workspace/.env << 'EOF'
# ClaudePod Environment Variables
# Copy this file and customize as needed

# GitHub Integration (required for GitHub MCP server)
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your-github-personal-access-token-here
# GITHUB_API_URL=https://api.github.com
# GITHUB_TOOLSET=context,issues,pull_requests

# Web Search (optional - requires API keys)
# TAVILY_API_KEY=tvly-your-tavily-api-key-here
# REF_TOOLS_API_KEY=rt-your-ref-tools-api-key-here
EOF
    echo "✅ Created /workspace/.env template"
    echo "🔧 Edit the file with your API keys and restart the container"
fi

# MCP Servers Status
echo ""
echo "🔌 MCP Servers Status"
if command -v claude > /dev/null 2>&1; then
    if claude mcp list > /dev/null 2>&1; then
        echo "MCP servers configured:"
        claude mcp list 2>/dev/null | grep -E "^[a-zA-Z]" | while read -r server; do
            echo "   $server"
        done
    else
        echo "⚠️  MCP servers not accessible (authentication may be required)"
        echo "   Run 'claude' to authenticate Claude Code"
    fi
fi

# Shell Aliases
echo ""
echo "🐚 Shell Aliases"
echo "ClaudePod includes these helpful aliases:"
echo "   gs  = git status"
echo "   gd  = git diff (with delta highlighting)"
echo "   gc  = git commit"
echo "   gp  = git push"
echo "   gl  = git log --oneline --graph --decorate"

# Final Instructions
echo ""
echo "✅ Environment setup complete!"
echo ""
echo "🚀 Next Steps:"
echo "   1. Run 'claude' to start Claude Code"
echo "   2. Try: './scripts/health-check.sh' to verify everything works"
echo "   3. Check available tools: See tools.md or ask Claude 'what tools do you have?'"
echo ""
echo "📚 Documentation:"
echo "   - CLAUDE.md: Complete container documentation"
echo "   - docs/: Setup guides for GitHub, API keys, security"
echo "   - examples/: Configuration examples and customizations"
echo ""
echo "Happy coding! 🎉"
