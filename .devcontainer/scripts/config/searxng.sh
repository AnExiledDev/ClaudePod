#!/bin/bash

# SearXNG MCP Enhanced Configuration Module
# Handles MCP SearXNG Enhanced installation and configuration setup

install_searxng_mcp() {
    echo "🔧 Installing MCP SearXNG Enhanced..."
    
    # Define installation paths
    local mcp_install_dir="/usr/local/mcp-servers/searxng"
    local temp_dir="/tmp/mcp-searxng-enhanced"
    local repo_url="https://github.com/OvertliDS/mcp-searxng-enhanced"
    
    # Create installation directory
    sudo mkdir -p "$mcp_install_dir"
    
    # Clone repository to temporary location
    echo "📥 Cloning MCP SearXNG Enhanced repository..."
    if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
    
    git clone "$repo_url" "$temp_dir" 2>/dev/null || {
        echo "❌ Failed to clone repository from $repo_url"
        return 1
    }
    
    # Install Python dependencies using uv with the correct Python version
    echo "📦 Installing Python dependencies..."
    sudo /home/node/.local/bin/uv pip install --python /usr/local/python/current/bin/python3 --system -r "$temp_dir/requirements.txt" || {
        echo "❌ Failed to install Python dependencies"
        return 1
    }
    
    # Copy MCP server files
    echo "📋 Copying MCP server files..."
    sudo cp "$temp_dir/mcp_server.py" "$mcp_install_dir/"
    sudo chmod +x "$mcp_install_dir/mcp_server.py"
    
    # Copy additional files if they exist
    if [ -f "$temp_dir/README.md" ]; then
        sudo cp "$temp_dir/README.md" "$mcp_install_dir/"
    fi
    
    # Clean up temporary directory
    rm -rf "$temp_dir"
    
    echo "✅ MCP SearXNG Enhanced installed successfully"
}

setup_searxng_config() {
    echo "🔧 Setting up SearXNG configuration..."
    
    local config_source="/workspace/.devcontainer/config/searxng/ods_config.json"
    local config_target="/home/node/.claude/ods_config.json"
    
    if [ ! -f "$config_source" ]; then
        echo "⚠️  SearXNG configuration template not found, using defaults"
        return 1
    fi
    
    # Ensure Claude directory exists
    mkdir -p "/home/node/.claude"
    
    local copy_config=false
    if [ "${OVERRIDE_SEARXNG_CONFIG:-false}" = "true" ]; then
        echo "📝 OVERRIDE_SEARXNG_CONFIG=true: Forcing overwrite of SearXNG configuration"
        copy_config=true
    elif [ ! -f "$config_target" ]; then
        echo "📝 Creating SearXNG configuration (no existing file found)"
        copy_config=true
    else
        echo "📁 Preserving existing SearXNG configuration (set OVERRIDE_SEARXNG_CONFIG=true to overwrite)"
    fi
    
    if [ "$copy_config" = "true" ]; then
        # Copy configuration file
        cp "$config_source" "$config_target"
        chown node:node "$config_target"
        chmod 600 "$config_target"
        
        echo "📋 Copied optimized SearXNG configuration"
    fi
    
    echo "✅ SearXNG configuration ready"
}

validate_searxng_connection() {
    echo "🔍 Validating SearXNG connection..."
    
    local searxng_url="${SEARXNG_ENGINE_API_BASE_URL:-http://localhost:8080/search}"
    
    # Test connection to SearXNG instance
    if command -v curl >/dev/null 2>&1; then
        if curl -s --connect-timeout 10 --max-time 30 "${searxng_url%/search}" >/dev/null; then
            echo "✅ SearXNG instance at $searxng_url is accessible"
            return 0
        else
            echo "⚠️  Warning: SearXNG instance at $searxng_url may not be accessible"
            echo "   MCP server will still be configured but may fail during runtime"
            return 1
        fi
    else
        echo "⚠️  curl not found, skipping connection validation"
        return 1
    fi
}

setup_searxng_environment() {
    echo "🌍 Setting up SearXNG environment variables..."
    
    # Set default environment variables if not already set
    export ODS_CONFIG_PATH="${ODS_CONFIG_PATH:-/home/node/.claude/ods_config.json}"
    export SEARXNG_ENGINE_API_BASE_URL="${SEARXNG_ENGINE_API_BASE_URL:-http://localhost:8080/search}"
    export DESIRED_TIMEZONE="${DESIRED_TIMEZONE:-America/New_York}"
    
    echo "📋 Environment variables configured:"
    echo "   ODS_CONFIG_PATH=$ODS_CONFIG_PATH"
    echo "   SEARXNG_ENGINE_API_BASE_URL=$SEARXNG_ENGINE_API_BASE_URL"
    echo "   DESIRED_TIMEZONE=$DESIRED_TIMEZONE"
    
    echo "✅ SearXNG environment ready"
}

setup_searxng_local_instance() {
    echo "🐳 Setting up SearXNG local instance..."
    
    # Check if local instance should be enabled
    if [ "${ENABLE_SEARXNG_LOCAL:-true}" != "true" ]; then
        echo "⏭️  SearXNG local instance is disabled (set ENABLE_SEARXNG_LOCAL=true to enable)"
        return 0
    fi
    
    local install_dir="${SEARXNG_LOCAL_INSTALL_DIR:-/opt/searxng-local}"
    
    # Ensure install directory exists with proper permissions
    sudo mkdir -p "$install_dir"
    sudo chown -R node:node "$install_dir"
    sudo chmod 755 "$install_dir"
    
    # Copy searxng-local configuration if it doesn't exist or is empty
    if [ ! -f "$install_dir/docker-compose.yaml" ] || [ ! -s "$install_dir/docker-compose.yaml" ]; then
        echo "📋 Copying SearXNG local configuration to persistent volume..."
        
        if [ -d "/workspace/searxng-local" ]; then
            # Copy entire searxng-local directory contents
            sudo cp -r /workspace/searxng-local/* "$install_dir/" 2>/dev/null || true
            
            # Ensure node user owns everything
            sudo chown -R node:node "$install_dir"
            sudo chmod -R u+rwX,g+rX "$install_dir"
            
            # Make sure docker-compose.yaml is properly copied
            if [ -f "$install_dir/docker-compose.yaml" ]; then
                echo "✅ SearXNG local configuration copied to $install_dir"
            else
                echo "⚠️  docker-compose.yaml not found after copy"
                return 1
            fi
        else
            echo "⚠️  Source searxng-local directory not found in workspace"
            return 1
        fi
    else
        echo "📁 SearXNG local configuration already exists in $install_dir"
    fi
    
    echo "✅ SearXNG local instance setup complete"
    return 0
}

start_searxng_local_instance() {
    echo "🚀 Starting SearXNG local instance..."
    
    # Check if local instance should be enabled
    if [ "${ENABLE_SEARXNG_LOCAL:-true}" != "true" ]; then
        echo "⏭️  SearXNG local instance startup is disabled"
        return 0
    fi
    
    local install_dir="${SEARXNG_LOCAL_INSTALL_DIR:-/opt/searxng-local}"
    
    # Verify installation directory and docker-compose.yaml exist
    if [ ! -f "$install_dir/docker-compose.yaml" ]; then
        echo "⚠️  SearXNG local configuration not found at $install_dir/docker-compose.yaml"
        echo "   Run setup_searxng_local_instance first"
        return 1
    fi
    
    # Change to the installation directory
    cd "$install_dir"
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        echo "⚠️  Docker daemon is not running. Waiting for Docker to start..."
        # Wait up to 30 seconds for Docker to be ready
        local attempts=0
        while [ $attempts -lt 30 ] && ! docker info >/dev/null 2>&1; do
            sleep 1
            ((attempts++))
        done
        
        if ! docker info >/dev/null 2>&1; then
            echo "❌ Docker daemon is not available after waiting. Cannot start SearXNG local instance."
            return 1
        fi
    fi
    
    # Start the services using docker-compose
    echo "🐳 Starting SearXNG and Redis containers..."
    if docker compose up -d 2>/dev/null || docker-compose up -d 2>/dev/null; then
        echo "✅ SearXNG local instance started successfully"
        
        # Wait a moment and check container status
        sleep 5
        if docker compose ps 2>/dev/null | grep -q "Up" || docker-compose ps 2>/dev/null | grep -q "Up"; then
            echo "🔍 SearXNG should be accessible at http://localhost:8080"
        else
            echo "⚠️  Containers started but may need more time to initialize"
            echo "   You can check status with: docker compose ps (in $install_dir)"
        fi
    else
        echo "❌ Failed to start SearXNG local instance"
        echo "   You can try manually: cd $install_dir && docker compose up -d"
        return 1
    fi
    
    return 0
}

# Main setup function
setup_searxng() {
    if [ "${ENABLE_SEARXNG_ENHANCED_MCP:-true}" != "true" ]; then
        echo "⏭️  SearXNG Enhanced MCP is disabled (set ENABLE_SEARXNG_ENHANCED_MCP=true to enable)"
        return 0
    fi
    
    echo "🔄 Setting up MCP SearXNG Enhanced..."
    
    # Setup local SearXNG instance first (during post-create)
    setup_searxng_local_instance || echo "   (Local instance setup failed, but continuing with MCP setup)"
    
    # Run installation and configuration steps
    install_searxng_mcp || return 1
    setup_searxng_config || return 1
    setup_searxng_environment
    validate_searxng_connection || echo "   (Connection validation failed, but continuing with setup)"
    
    echo "✅ MCP SearXNG Enhanced setup complete"
    
    return 0
}