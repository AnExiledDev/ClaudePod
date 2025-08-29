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
    
    local searxng_url="${SEARXNG_ENGINE_API_BASE_URL:-http://localhost:80/search}"
    
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
    export SEARXNG_ENGINE_API_BASE_URL="${SEARXNG_ENGINE_API_BASE_URL:-http://localhost:80/search}"
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
    local temp_dir="/tmp/searxng-local-setup"
    local repo_url="https://github.com/searxng/searxng-docker"
    
    # Ensure install directory exists with proper permissions
    sudo mkdir -p "$install_dir"
    sudo chown -R node:node "$install_dir"
    sudo chmod 755 "$install_dir"
    
    # Install fresh SearXNG configuration from latest repository if it doesn't exist or is empty
    if [ ! -f "$install_dir/docker-compose.yaml" ] || [ ! -s "$install_dir/docker-compose.yaml" ]; then
        echo "📥 Installing SearXNG from latest repository..."
        
        # Clean up any existing temp directory
        if [ -d "$temp_dir" ]; then
            rm -rf "$temp_dir"
        fi
        
        # Clone the latest SearXNG Docker repository
        if git clone "$repo_url" "$temp_dir" 2>/dev/null; then
            echo "✅ Successfully cloned SearXNG repository"
            
            # Copy the necessary files from the repository
            if [ -f "$temp_dir/docker-compose.yaml" ]; then
                sudo cp "$temp_dir/docker-compose.yaml" "$install_dir/"
                echo "✅ Installed docker-compose.yaml"
            fi
            
            if [ -f "$temp_dir/.env" ]; then
                sudo cp "$temp_dir/.env" "$install_dir/"
                echo "✅ Installed .env configuration"
            fi
            
            if [ -f "$temp_dir/Caddyfile" ]; then
                sudo cp "$temp_dir/Caddyfile" "$install_dir/"
                echo "✅ Installed Caddyfile"
            fi
            
            if [ -d "$temp_dir/searxng" ]; then
                sudo cp -r "$temp_dir/searxng" "$install_dir/"
                echo "✅ Installed SearXNG configuration directory"
            fi
            
            # Ensure node user owns everything
            sudo chown -R node:node "$install_dir"
            sudo chmod -R u+rwX,g+rX "$install_dir"
            
            # Clean up temp directory
            rm -rf "$temp_dir"
            
            if [ -f "$install_dir/docker-compose.yaml" ]; then
                echo "✅ SearXNG local instance installed successfully from latest repository"
            else
                echo "❌ Failed to install docker-compose.yaml from repository"
                return 1
            fi
        else
            echo "❌ Failed to clone SearXNG repository from $repo_url"
            return 1
        fi
    else
        echo "📁 SearXNG local configuration already exists in $install_dir"
    fi
    
    # Always configure SearXNG for local development (even if installation already exists)
    configure_searxng_for_local_dev "$install_dir"
    
    echo "✅ SearXNG local instance setup complete"
    return 0
}

configure_searxng_for_local_dev() {
    local install_dir="$1"
    echo "🔧 Configuring SearXNG for local development..."
    
    # Fix Caddyfile if it exists as directory (from previous broken installations)
    if [ -d "$install_dir/Caddyfile" ]; then
        echo "🔧 Fixing Caddyfile directory issue..."
        sudo rm -rf "$install_dir/Caddyfile"
        # Re-download proper Caddyfile
        local temp_dir="/tmp/searxng-caddyfile-fix"
        if git clone "https://github.com/searxng/searxng-docker" "$temp_dir" 2>/dev/null; then
            if [ -f "$temp_dir/Caddyfile" ]; then
                sudo cp "$temp_dir/Caddyfile" "$install_dir/"
                echo "✅ Fixed Caddyfile (was incorrectly a directory)"
            fi
            rm -rf "$temp_dir"
        fi
    fi
    
    # Generate secure secret key
    local secret_key=$(openssl rand -base64 32 2>/dev/null || echo "$(date +%s)-$(whoami)-$(hostname)" | base64)
    
    # Create optimized settings.yml for local development
    sudo tee "$install_dir/searxng/settings.yml" > /dev/null << EOF
use_default_settings: true
server:
  secret_key: "$secret_key"
  limiter: false
  image_proxy: true
  public_instance: false
  bind_address: "0.0.0.0:8080"
  method: "POST"
redis:
  url: redis://redis:6379/0
search:
  safe_search: 0
  autocomplete: ""
  default_lang: ""
  ban_time_on_fail: 0
  max_ban_time_on_fail: 0
  formats: ['html', 'json']
general:
  debug: false
  instance_name: "SearXNG Local Development"
enabled_plugins: []
disabled_plugins: ['Hash plugin', 'Tracker URL remover', 'Hostnames plugin', 'Unit converter plugin', 'Self Information', 'Search on category select', 'Tor check plugin']
EOF
    
    # Disable limiter configuration by renaming the file
    if [ -f "$install_dir/searxng/limiter.toml" ]; then
        sudo mv "$install_dir/searxng/limiter.toml" "$install_dir/searxng/limiter.toml.disabled"
        echo "✅ Disabled SearXNG rate limiter"
    fi
    
    # Fix docker-compose.yaml network configuration for MCP compatibility
    echo "🔧 Fixing docker-compose.yaml for MCP server compatibility..."
    if [ -f "$install_dir/docker-compose.yaml" ]; then
        # Replace network_mode: host with proper networks configuration
        sudo sed -i 's/network_mode: host/networks:\
      - searxng\
    ports:\
      - "80:80"\
      - "443:443"/' "$install_dir/docker-compose.yaml"
        echo "✅ Fixed docker-compose.yaml network configuration"
    else
        echo "⚠️  docker-compose.yaml not found, skipping network fix"
    fi
    
    # Fix Caddyfile proxy target and API paths for MCP compatibility  
    echo "🔧 Fixing Caddyfile for MCP server compatibility..."
    if [ -f "$install_dir/Caddyfile" ]; then
        # Replace localhost:8080 with searxng:8080 for container networking
        sudo sed -i 's/reverse_proxy localhost:8080/reverse_proxy searxng:8080/' "$install_dir/Caddyfile"
        
        # Add /search and / paths to @api matcher after /stats/checker
        sudo sed -i '/path \/stats\/checker/a\\tpath \/search\
\tpath \/' "$install_dir/Caddyfile"
        echo "✅ Fixed Caddyfile proxy target and API paths"
    else
        echo "⚠️  Caddyfile not found, skipping proxy fix"
    fi
    
    # Ensure proper ownership
    sudo chown -R node:node "$install_dir"
    
    echo "✅ SearXNG configured for local development (JSON API enabled, network fixed, no rate limiting)"
}

test_searxng_functionality() {
    echo "🧪 Testing SearXNG functionality..."
    
    local searxng_url="${SEARXNG_ENGINE_API_BASE_URL:-http://localhost:80/search}"
    
    # Wait for services to be ready
    local attempts=0
    while [ $attempts -lt 30 ]; do
        if curl -s --connect-timeout 5 "http://localhost:8080/" >/dev/null 2>&1; then
            break
        fi
        sleep 2
        ((attempts++))
    done
    
    if [ $attempts -eq 30 ]; then
        echo "⚠️  SearXNG web interface not responding after 60 seconds"
        return 1
    fi
    
    # Test web interface
    if curl -s "http://localhost:8080/" | grep -qi "searxng"; then
        echo "✅ SearXNG web interface accessible"
    else
        echo "⚠️  SearXNG web interface not working properly"
        return 1
    fi
    
    # Note about API access - may require specific headers/form submission
    echo "ℹ️  SearXNG installed and web interface working"
    echo "   API access may require proper form submission (not just GET requests)"
    
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
            
            # Test functionality
            test_searxng_functionality
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