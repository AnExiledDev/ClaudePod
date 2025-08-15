#!/bin/bash
# TaskMaster Auto-Configuration Script
# Ensures TaskMaster is properly configured on container startup

set -e

PROJECT_ROOT="/workspace"

echo "🔧 Setting up TaskMaster configuration..."

# Function to initialize TaskMaster using MCP
initialize_taskmaster() {
    echo "🚀 Initializing TaskMaster project using MCP..."
    
    cd "$PROJECT_ROOT"
    
    # Use Claude Code MCP to initialize TaskMaster with minimal setup
    if command -v claude &> /dev/null; then
        echo "📦 Using Claude Code MCP to initialize TaskMaster..."
        
        # Try to initialize via a direct Claude Code invocation
        # This simulates what would happen when Claude Code uses the MCP server
        claude -p "Initialize TaskMaster project in this workspace with claude profile, skip installation, and configure to use claude-code provider models" 2>/dev/null || {
            echo "⚠️  Direct Claude initialization failed, using manual approach"
            return 1
        }
        
        echo "✅ TaskMaster initialized via Claude Code"
        return 0
    else
        echo "❌ Claude Code not available"
        return 1
    fi
}

# Function to configure models for claude-code provider
configure_models() {
    if [ -f "$PROJECT_ROOT/.taskmaster/config.json" ]; then
        echo "🔧 Configuring TaskMaster to use claude-code provider..."
        
        # Update config to use claude-code provider
        python3 -c "
import json
import sys

config_file = '$PROJECT_ROOT/.taskmaster/config.json'
try:
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    # Update models to use claude-code provider
    config['models'] = {
        'main': {
            'provider': 'claude-code',
            'modelId': 'sonnet',
            'maxTokens': 64000,
            'temperature': 0.2
        },
        'research': {
            'provider': 'claude-code',
            'modelId': 'sonnet',
            'maxTokens': 64000,
            'temperature': 0.1
        },
        'fallback': {
            'provider': 'claude-code',
            'modelId': 'sonnet',
            'maxTokens': 64000,
            'temperature': 0.2
        }
    }
    
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=2)
    
    print('✅ Models configured for claude-code provider')
except Exception as e:
    print(f'❌ Failed to configure models: {e}')
    sys.exit(1)
" || echo "⚠️  Manual model configuration failed"
    fi
}

# Function to check if TaskMaster needs setup
needs_setup() {
    # Check if TaskMaster is already initialized properly
    if [ ! -d "$PROJECT_ROOT/.taskmaster" ]; then
        return 0  # Needs setup
    fi
    
    if [ ! -f "$PROJECT_ROOT/.taskmaster/config.json" ]; then
        return 0  # Needs setup
    fi
    
    # Check if using claude-code provider
    if ! grep -q '"provider": "claude-code"' "$PROJECT_ROOT/.taskmaster/config.json" 2>/dev/null; then
        return 0  # Needs reconfiguration
    fi
    
    return 1  # No setup needed
}

# Update CLAUDE.md to reference TaskMaster (if not already done)
update_main_claude_md() {
    if [ -f "$PROJECT_ROOT/CLAUDE.md" ] && ! grep -q "@./.taskmaster/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md"; then
        echo "" >> "$PROJECT_ROOT/CLAUDE.md"
        echo "## Task Master AI Instructions" >> "$PROJECT_ROOT/CLAUDE.md"
        echo "**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**" >> "$PROJECT_ROOT/CLAUDE.md"
        echo "@./.taskmaster/CLAUDE.md" >> "$PROJECT_ROOT/CLAUDE.md"
        echo "✅ Updated main CLAUDE.md to reference TaskMaster"
    fi
}

# Main execution
main() {
    cd "$PROJECT_ROOT"
    
    if needs_setup; then
        echo "📁 TaskMaster needs initialization or configuration..."
        
        # Try MCP initialization first
        if initialize_taskmaster; then
            echo "✅ TaskMaster initialized via MCP"
        else
            echo "⚠️  MCP initialization failed, TaskMaster will need manual initialization"
            echo "   Run: 'Initialize TaskMaster project in this directory' via Claude Code"
            echo "   Or use MCP commands directly in Claude Code interface"
        fi
        
        # Ensure claude-code provider configuration
        configure_models
    else
        echo "✅ TaskMaster already configured with claude-code provider"
    fi
    
    update_main_claude_md
    
    echo ""
    echo "🎉 TaskMaster setup complete!"
    echo "   • Ready for use via Claude Code MCP"
    echo "   • Configuration: claude-code provider (no API keys needed)"
    echo "   • Available commands: initialize_project, parse_prd, get_tasks, etc."
    echo ""
}

# Execute main function
main "$@"