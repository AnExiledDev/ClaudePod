#!/bin/bash
# ClaudePod Health Check Script
# Verifies all components are working correctly

set -e

echo "🏥 ClaudePod Health Check"
echo "Verifying all components are working correctly..."

ERRORS=0
WARNINGS=0

# Function to check command availability
check_command() {
    local cmd="$1"
    local description="$2"
    local required="${3:-true}"
    
    if command -v "$cmd" > /dev/null 2>&1; then
        echo "✅ $description: $(command -v "$cmd")"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo "❌ $description: Not found"
            ((ERRORS++))
        else
            echo "⚠️  $description: Not found (optional)"
            ((WARNINGS++))
        fi
        return 1
    fi
}

# Function to check service status
check_service() {
    local service="$1"
    local description="$2"
    local check_cmd="$3"
    
    echo -n "🔍 Checking $description... "
    if eval "$check_cmd" > /dev/null 2>&1; then
        echo "✅ OK"
        return 0
    else
        echo "❌ Failed"
        ((ERRORS++))
        return 1
    fi
}

echo ""
echo "🔧 Core Development Tools"
echo "────────────────────────────────────────"

# Node.js ecosystem
check_command "node" "Node.js" true
check_command "npm" "npm" true
check_command "npx" "npx" true

# Python ecosystem  
check_command "python3" "Python 3" true
check_command "pip3" "pip3" true
check_command "pipx" "pipx" false

# Development tools
check_command "git" "Git" true
check_command "gh" "GitHub CLI" true
check_command "uv" "uv package manager" false
check_command "uvx" "uvx runner" false
check_command "delta" "git-delta" false

echo ""
echo "🤖 Claude Code"
echo "────────────────────────────────────────"

# Claude Code
if check_command "claude" "Claude Code CLI" true; then
    # Check Claude version
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    echo "   Version: $CLAUDE_VERSION"
    
    # Check MCP servers
    echo "🔌 MCP Servers:"
    if claude mcp list > /dev/null 2>&1; then
        MCP_COUNT=$(claude mcp list 2>/dev/null | grep -c ":" || echo "0")
        echo "   Found $MCP_COUNT configured MCP servers"
        
        # List server status
        claude mcp list 2>/dev/null | while read -r line; do
            if [[ $line =~ ^[a-zA-Z0-9_-]+: ]]; then
                if [[ $line =~ "✓" ]]; then
                    echo "   ✅ $(echo "$line" | cut -d: -f1)"
                elif [[ $line =~ "✗" ]]; then
                    echo "   ❌ $(echo "$line" | cut -d: -f1)"
                    ((ERRORS++)) 2>/dev/null || true
                else
                    echo "   ⚠️  $(echo "$line" | cut -d: -f1)"
                    ((WARNINGS++)) 2>/dev/null || true
                fi
            fi
        done
    else
        echo "   ⚠️  Could not check MCP servers (may need authentication)"
        ((WARNINGS++))
    fi
fi

echo ""
echo "📁 File System"
echo "────────────────────────────────────────"

# Check workspace
if [ -d "/workspace" ] && [ -w "/workspace" ]; then
    echo "✅ Workspace directory: /workspace (writable)"
else
    echo "❌ Workspace directory: Not writable"
    ((ERRORS++))
fi

# Check persistent volumes
EXPECTED_DIRS=("/home/node/.claude" "/home/node/.config" "/home/node/.local")
for dir in "${EXPECTED_DIRS[@]}"; do
    if [ -d "$dir" ] && [ -w "$dir" ]; then
        echo "✅ Persistent directory: $dir"
    else
        echo "⚠️  Persistent directory: $dir (not found or not writable)"
        ((WARNINGS++))
    fi
done

echo ""
echo "🌐 Network & Environment"  
echo "────────────────────────────────────────"

# Check important environment variables
ENV_VARS=("HOME" "USER" "PATH" "NVM_DIR")
for var in "${ENV_VARS[@]}"; do
    if [ -n "${!var}" ]; then
        echo "✅ Environment variable $var: ${!var}"
    else
        echo "⚠️  Environment variable $var: Not set"
        ((WARNINGS++))
    fi
done

# Check PATH components
EXPECTED_PATHS=("/usr/local/bin" "/usr/bin" "/bin")
for path_dir in "${EXPECTED_PATHS[@]}"; do
    if [[ ":$PATH:" == *":$path_dir:"* ]]; then
        echo "✅ PATH contains: $path_dir"
    else
        echo "⚠️  PATH missing: $path_dir"
        ((WARNINGS++))
    fi
done

echo ""
echo "🔐 Authentication Status"
echo "────────────────────────────────────────"

# Git configuration
if git config --global user.name > /dev/null 2>&1 && git config --global user.email > /dev/null 2>&1; then
    echo "✅ Git configured: $(git config --global user.name) <$(git config --global user.email)>"
else
    echo "⚠️  Git not configured (run setup-env.sh)"
    ((WARNINGS++))
fi

# GitHub CLI authentication
if gh auth status > /dev/null 2>&1; then
    echo "✅ GitHub CLI: Authenticated"
else
    echo "⚠️  GitHub CLI: Not authenticated"
    ((WARNINGS++))
fi

echo ""
echo "🧪 Quick Functionality Tests"
echo "────────────────────────────────────────"

# Test Node.js
echo -n "🧪 Testing Node.js... "
if echo "console.log('OK')" | node > /dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
    ((ERRORS++))
fi

# Test Python
echo -n "🧪 Testing Python... "
if echo "print('OK')" | python3 > /dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
    ((ERRORS++))
fi

# Test npm
echo -n "🧪 Testing npm... "
if npm --version > /dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
    ((ERRORS++))
fi

# Test git
echo -n "🧪 Testing git... "
if git --version > /dev/null 2>&1; then
    echo "✅ OK"
else
    echo "❌ Failed"
    ((ERRORS++))
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "📊 Health Check Summary"
echo "════════════════════════════════════════════════════════════════"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "🎉 Perfect! Everything is working correctly."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "✅ Good! $WARNINGS warnings found (non-critical issues)."
    echo ""
    echo "💡 Suggestions:"
    echo "   - Run 'scripts/setup-env.sh' to resolve configuration warnings"
    echo "   - Authenticate with GitHub CLI: gh auth login"
    echo "   - Configure git user info if needed"
    exit 0
else
    echo "❌ Issues found! $ERRORS errors and $WARNINGS warnings."
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   - Check if container built successfully"
    echo "   - Try rebuilding: devpod delete <workspace> && devpod up ."
    echo "   - Check logs for build errors"
    echo "   - Verify all DevContainer features are supported"
    exit 1
fi