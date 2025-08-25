#!/bin/bash

# TaskMaster Configuration Module  
# Handles TaskMaster AI configuration setup

setup_taskmaster_config() {
    echo "🔧 Setting up TaskMaster configuration..."
    
    local taskmaster_source="/workspace/.devcontainer/config/taskmaster/config.json"
    local taskmaster_target_workspace="/workspace/.taskmaster/config.json"
    
    if [ ! -f "$taskmaster_source" ]; then
        echo "⚠️  TaskMaster configuration template not found, using defaults"
        return 1
    fi
    
    # Ensure TaskMaster directory exists
    mkdir -p "/workspace/.taskmaster"
    
    local copy_taskmaster=false
    if [ "${OVERRIDE_TASKMASTER_CONFIG:-false}" = "true" ]; then
        echo "📝 OVERRIDE_TASKMASTER_CONFIG=true: Forcing overwrite of TaskMaster configuration"
        copy_taskmaster=true
    elif [ ! -f "$taskmaster_target_workspace" ]; then
        echo "📝 Creating TaskMaster configuration (no existing files found)"
        copy_taskmaster=true
    else
        echo "📁 Preserving existing TaskMaster configuration (set OVERRIDE_TASKMASTER_CONFIG=true to overwrite)"
    fi
    
    if [ "$copy_taskmaster" = "true" ]; then
        # Copy to workspace
        cp "$taskmaster_source" "$taskmaster_target_workspace"
        chown node:node "$taskmaster_target_workspace"
        chmod 600 "$taskmaster_target_workspace"
        
        echo "📋 Copied optimized TaskMaster configuration"
    fi
    
    echo "✅ TaskMaster configuration ready"
}