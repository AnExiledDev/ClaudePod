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
if [ -f "/workspace/.devcontainer/.env" ]; then
    echo "Environment file found: /workspace/.devcontainer/.env"
    
    # Source environment variables
    set -a  # automatically export all variables
    source /workspace/.devcontainer/.env
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
            echo "   4. Copy the token and paste it below"
            echo ""
            read -s -p "Enter your GitHub PAT: " GITHUB_PAT
            echo ""
            
            if [ -n "$GITHUB_PAT" ]; then
                # Update .env file
                if grep -q "GITHUB_PERSONAL_ACCESS_TOKEN=" /workspace/.devcontainer/.env; then
                    sed -i "s/GITHUB_PERSONAL_ACCESS_TOKEN=.*/GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_PAT/" /workspace/.devcontainer/.env
                else
                    echo "GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_PAT" >> /workspace/.devcontainer/.env
                fi
                
                export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PAT"
                echo "✅ GitHub PAT saved to .env file"
                
                # Validate the new token
                if [ -f "/workspace/scripts/validate-github-env.sh" ]; then
                    echo "🔍 Validating GitHub token..."
                    bash /workspace/scripts/validate-github-env.sh || echo "⚠️  Validation failed - token may be invalid"
                fi
            else
                echo "⏭️  Skipping GitHub PAT setup"
            fi
        fi
    fi
else
    echo "⚠️  Environment file not found: /workspace/.devcontainer/.env"
    echo "   Copy .devcontainer/.env.example to .devcontainer/.env and configure your API keys"
    read -p "Would you like to create .env from .env.example now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp /workspace/.devcontainer/.env.example /workspace/.devcontainer/.env
        echo "✅ .env file created from .env.example"
        echo "   Edit /workspace/.devcontainer/.env to add your API keys"
    fi
fi

# MCP Server status
echo ""
echo "🔌 MCP Server Status"
if command -v claude > /dev/null 2>&1; then
    echo "Checking MCP servers..."
    claude mcp list || echo "⚠️  Run 'claude' to initialize MCP servers"
else
    echo "⚠️  Claude Code not available for MCP check"
fi

# Development environment check
echo ""
echo "🛠️  Development Environment Check"

# Node.js
if command -v node > /dev/null 2>&1; then
    echo "✅ Node.js $(node --version)"
else
    echo "❌ Node.js not found"
fi

# Python
if command -v python3 > /dev/null 2>&1; then
    echo "✅ Python $(python3 --version | cut -d' ' -f2)"
else
    echo "❌ Python not found"
fi

# uv/uvx
if command -v uvx > /dev/null 2>&1; then
    echo "✅ uv/uvx $(uvx --version | cut -d' ' -f2)"
else
    echo "❌ uv/uvx not found"
fi

# Git delta
if command -v delta > /dev/null 2>&1; then
    echo "✅ git-delta $(delta --version | cut -d' ' -f2)"
else
    echo "❌ git-delta not found"
fi

# TaskMaster setup
echo ""
echo "🤖 TaskMaster Setup"
if [ -f "/workspace/scripts/setup-taskmaster.sh" ]; then
    echo "Configuring TaskMaster for AI-powered project management..."
    bash /workspace/scripts/setup-taskmaster.sh
else
    echo "⚠️  TaskMaster setup script not found"
fi

# Project initialization
echo ""
echo "📁 Project Initialization"
if [ "$(ls -A /workspace 2>/dev/null | grep -v '.devcontainer\|CLAUDE.md\|README.md\|examples\|scripts')" ]; then
    echo "✅ Workspace contains project files"
else
    echo "📁 Workspace is empty"
    read -p "Would you like to initialize a new project? (node/python/empty/n): " PROJECT_TYPE
    
    case $PROJECT_TYPE in
        node|nodejs)
            cd /workspace
            npm init -y
            echo "✅ Node.js project initialized"
            echo "💡 Run 'npm install <package>' to add dependencies"
            ;;
        python|py)
            cd /workspace
            uv init
            echo "✅ Python project initialized with uv"
            echo "💡 Run 'uv add <package>' to add dependencies"
            ;;
        empty)
            touch /workspace/.gitkeep
            echo "✅ Empty project structure created"
            ;;
        *)
            echo "⏭️  Skipping project initialization"
            ;;
    esac
fi

# VS Code settings suggestion
echo ""
echo "⚙️  VS Code Settings"
if [ ! -f "/workspace/.vscode/settings.json" ]; then
    read -p "Would you like to create a VS Code settings file with recommended settings? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p /workspace/.vscode
        cat > /workspace/.vscode/settings.json << 'EOF'
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": "explicit"
  },
  "python.defaultInterpreterPath": "/usr/local/bin/python3",
  "python.terminal.activateEnvironment": false,
  "git.autofetch": true,
  "git.enableSmartCommit": true,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true
}
EOF
        echo "✅ VS Code settings created"
    fi
else
    echo "✅ VS Code settings already exist"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ Environment setup complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "🎉 Next steps:"
echo "   1. Run 'claude' to start using Claude Code"
echo "   2. Open VS Code and start coding"
echo "   3. Use 'gs', 'gd', 'gc' for quick git operations"
echo "   4. Check the examples/ folder for more configuration options"
echo ""
echo "💡 This setup persists across container rebuilds!"
echo "════════════════════════════════════════════════════════════════"