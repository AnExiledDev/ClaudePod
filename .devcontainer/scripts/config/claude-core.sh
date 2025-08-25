#!/bin/bash

# Claude Core Configuration Module
# Handles Claude directory creation and core configuration files

setup_claude_core_config() {
    echo "🔧 Setting up Claude core configuration..."
    
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
    setup_claude_settings
    
    # Copy MCP configuration
    setup_claude_mcp_config
    
    # Copy system prompt
    setup_claude_system_prompt
    
    # Copy output styles
    setup_claude_output_styles
    
    echo "📋 Claude core configuration processing completed"
}

setup_claude_settings() {
    local settings_source="/workspace/.devcontainer/config/claude/settings.json"
    local settings_target_home="/home/node/.claude/settings.json"
    local settings_target_workspace="/workspace/.claude/settings.json"
    
    if [ ! -f "$settings_source" ]; then
        echo "⚠️  Claude settings template not found, using defaults"
        return 1
    fi
    
    # Check if we should override existing files or only create if missing
    local copy_settings=false
    if [ "${OVERRIDE_CLAUDE_SETTINGS:-false}" = "true" ]; then
        echo "📝 OVERRIDE_CLAUDE_SETTINGS=true: Forcing overwrite of Claude settings"
        copy_settings=true
    elif [ ! -f "$settings_target_home" ] && [ ! -f "$settings_target_workspace" ]; then
        echo "📝 Creating Claude settings (no existing files found)"
        copy_settings=true
    else
        echo "📁 Preserving existing Claude settings (set OVERRIDE_CLAUDE_SETTINGS=true to overwrite)"
    fi
    
    if [ "$copy_settings" = "true" ]; then
        # Create backups of existing configurations
        create_config_backup "$settings_target_home"
        create_config_backup "$settings_target_workspace"
        
        # Copy to home directory (will be bind-mounted to workspace)
        cp "$settings_source" "$settings_target_home"
        chown node:node "$settings_target_home"
        chmod 600 "$settings_target_home"
        
        # Also copy directly to workspace for redundancy
        cp "$settings_source" "$settings_target_workspace"
        chown node:node "$settings_target_workspace"
        chmod 600 "$settings_target_workspace"
        
        echo "📋 Claude settings configured"
    fi
}

setup_claude_mcp_config() {
    local mcp_source="/workspace/.devcontainer/config/claude/mcp.json"
    local mcp_target_home="/home/node/.claude/mcp.json"
    local mcp_target_workspace="/workspace/.claude/mcp.json"
    
    if [ ! -f "$mcp_source" ]; then
        echo "📝 MCP configuration template not found, will be generated in post-start phase"
        return 0
    fi
    
    local copy_mcp=false
    if [ "${OVERRIDE_CLAUDE_MCP:-false}" = "true" ]; then
        echo "📝 OVERRIDE_CLAUDE_MCP=true: Forcing overwrite of Claude MCP configuration"
        copy_mcp=true
    elif [ ! -f "$mcp_target_home" ] && [ ! -f "$mcp_target_workspace" ]; then
        echo "📝 Creating Claude MCP configuration (no existing files found)"
        copy_mcp=true
    else
        echo "📁 Preserving existing Claude MCP configuration (set OVERRIDE_CLAUDE_MCP=true to overwrite)"
    fi
    
    if [ "$copy_mcp" = "true" ]; then
        # Create backups of existing MCP configurations
        create_config_backup "$mcp_target_home"
        create_config_backup "$mcp_target_workspace"
        
        cp "$mcp_source" "$mcp_target_home"
        cp "$mcp_source" "$mcp_target_workspace"
        chown node:node "$mcp_target_home" "$mcp_target_workspace"
        chmod 600 "$mcp_target_home" "$mcp_target_workspace"
        
        echo "📋 Claude MCP configuration set up"
    fi
}

setup_claude_system_prompt() {
    local prompt_source="/workspace/.devcontainer/config/claude/system-prompt.md"
    local prompt_target_home="/home/node/.claude/system-prompt.md"
    local prompt_target_workspace="/workspace/.claude/system-prompt.md"
    
    if [ ! -f "$prompt_source" ]; then
        echo "📝 System prompt template not found, skipping"
        return 0
    fi
    
    local copy_prompt=false
    if [ "${OVERRIDE_CLAUDE_SYSTEM_PROMPT:-false}" = "true" ]; then
        echo "📝 OVERRIDE_CLAUDE_SYSTEM_PROMPT=true: Forcing overwrite of Claude system prompt"
        copy_prompt=true
    elif [ ! -f "$prompt_target_home" ] && [ ! -f "$prompt_target_workspace" ]; then
        echo "📝 Creating Claude system prompt (no existing files found)"
        copy_prompt=true
    else
        echo "📁 Preserving existing Claude system prompt (set OVERRIDE_CLAUDE_SYSTEM_PROMPT=true to overwrite)"
    fi
    
    if [ "$copy_prompt" = "true" ]; then
        # Create backups of existing system prompt configurations
        create_config_backup "$prompt_target_home"
        create_config_backup "$prompt_target_workspace"
        
        cp "$prompt_source" "$prompt_target_home"
        cp "$prompt_source" "$prompt_target_workspace"
        chown node:node "$prompt_target_home" "$prompt_target_workspace"
        chmod 600 "$prompt_target_home" "$prompt_target_workspace"
        
        echo "📋 Claude system prompt configured"
    fi
}

setup_claude_output_styles() {
    local styles_source="/workspace/.devcontainer/config/claude/output-styles"
    local styles_target_home="/home/node/.claude/output-styles"
    local styles_target_workspace="/workspace/.claude/output-styles"
    
    if [ ! -d "$styles_source" ]; then
        echo "📝 Output styles directory not found, skipping"
        return 0
    fi
    
    local copy_styles=false
    if [ "${OVERRIDE_CLAUDE_OUTPUT_STYLES:-false}" = "true" ]; then
        echo "📝 OVERRIDE_CLAUDE_OUTPUT_STYLES=true: Forcing overwrite of Claude output styles"
        copy_styles=true
    elif [ ! -d "$styles_target_home" ] && [ ! -d "$styles_target_workspace" ]; then
        echo "📝 Creating Claude output styles (no existing directories found)"
        copy_styles=true
    else
        echo "📁 Preserving existing Claude output styles (set OVERRIDE_CLAUDE_OUTPUT_STYLES=true to overwrite)"
    fi
    
    if [ "$copy_styles" = "true" ]; then
        # Create backups of existing output styles directories
        if [ -d "$styles_target_home" ]; then
            local backup_dir="/workspace/.devcontainer/config/backups"
            mkdir -p "$backup_dir"
            local timestamp=$(date +"%Y%m%d_%H%M%S")
            local backup_home="${backup_dir}/home_node_.claude_output-styles.${timestamp}.backup"
            cp -r "$styles_target_home" "$backup_home"
            chown -R node:node "$backup_home"
            chmod -R 600 "$backup_home"
            echo "📦 Created backup: $backup_home"
        fi
        
        if [ -d "$styles_target_workspace" ]; then
            local backup_dir="/workspace/.devcontainer/config/backups"
            mkdir -p "$backup_dir"
            local timestamp=$(date +"%Y%m%d_%H%M%S")
            local backup_workspace="${backup_dir}/workspace_.claude_output-styles.${timestamp}.backup"
            cp -r "$styles_target_workspace" "$backup_workspace"
            chown -R node:node "$backup_workspace"
            chmod -R 600 "$backup_workspace"
            echo "📦 Created backup: $backup_workspace"
        fi
        
        # Copy to home directory (will be bind-mounted to workspace)
        mkdir -p "$styles_target_home"
        cp -r "$styles_source"/* "$styles_target_home"/
        chown -R node:node "$styles_target_home"
        chmod -R 600 "$styles_target_home"
        
        # Also copy directly to workspace for redundancy
        mkdir -p "$styles_target_workspace"
        cp -r "$styles_source"/* "$styles_target_workspace"/
        chown -R node:node "$styles_target_workspace"
        chmod -R 600 "$styles_target_workspace"
        
        echo "📋 Claude output styles configured"
    fi
}