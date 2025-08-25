#!/bin/bash

# Serena Configuration Module
# Handles Serena MCP server configuration setup

setup_serena_config() {
    echo "🔧 Setting up Serena configuration..."
    
    local serena_source="/workspace/.devcontainer/config/serena/serena_config.yml"
    local serena_target_home="/home/node/.serena/serena_config.yml"
    local serena_target_workspace="/workspace/.serena/serena_config.yml"
    
    if [ ! -f "$serena_source" ]; then
        echo "⚠️  Serena configuration template not found, using defaults"
        return 1
    fi
    
    # Ensure Serena directories exist
    mkdir -p "/home/node/.serena" "/workspace/.serena"
    
    local copy_serena=false
    if [ "${OVERRIDE_SERENA_CONFIG:-false}" = "true" ]; then
        echo "📝 OVERRIDE_SERENA_CONFIG=true: Forcing overwrite of Serena configuration"
        copy_serena=true
    elif [ ! -f "$serena_target_home" ] && [ ! -f "$serena_target_workspace" ]; then
        echo "📝 Creating Serena configuration (no existing files found)"
        copy_serena=true
    else
        echo "📁 Preserving existing Serena configuration (set OVERRIDE_SERENA_CONFIG=true to overwrite)"
    fi
    
    if [ "$copy_serena" = "true" ]; then
        # Copy to home directory (will be bind-mounted to workspace)
        cp "$serena_source" "$serena_target_home"
        chown node:node "$serena_target_home"
        chmod 600 "$serena_target_home"
        
        # Also copy directly to workspace for redundancy
        cp "$serena_source" "$serena_target_workspace"
        chown node:node "$serena_target_workspace"
        chmod 600 "$serena_target_workspace"
        
        echo "📋 Copied optimized Serena configuration"
    fi
    
    echo "✅ Serena configuration ready"
}