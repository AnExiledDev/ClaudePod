#!/bin/bash
# ZSH Configuration Script for ClaudePod
# This script enhances the ZSH setup with plugins, themes, and productivity features

set -euo pipefail

# Clear npm prefix environment variables that conflict with NVM
unset npm_config_prefix 2>/dev/null || true
unset NPM_CONFIG_PREFIX 2>/dev/null || true

echo "🐚 Setting up enhanced ZSH configuration..."

# State tracking directory  
STATE_DIR="/workspace/.devcontainer/state"

# Function to create state marker
create_state_marker() {
    local component="$1"
    local method="${2:-unknown}"
    
    mkdir -p "$STATE_DIR"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $method" > "$STATE_DIR/${component}.installed"
    chown -R node:node "$STATE_DIR"
}

# Function to check if component is already installed
is_component_installed() {
    local component="$1"
    
    [ -f "$STATE_DIR/${component}.installed" ]
}

# Variables
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
NODE_USER="node"

# Source shell configuration modules
source "/workspace/.devcontainer/scripts/shell/zsh-config.sh"

# Function to install ZSH plugin
install_zsh_plugin() {
    local plugin_name="$1"
    local plugin_repo="$2"
    local plugin_dir="$ZSH_CUSTOM/plugins/$plugin_name"
    
    if [ ! -d "$plugin_dir" ]; then
        echo "📦 Installing ZSH plugin: $plugin_name"
        git clone "https://github.com/$plugin_repo.git" "$plugin_dir" || {
            echo "⚠️  Failed to install $plugin_name plugin"
            return 1
        }
    else
        echo "✅ ZSH plugin $plugin_name already installed"
    fi
}

# Function to install Powerlevel10k theme
install_powerlevel10k() {
    local theme_dir="$ZSH_CUSTOM/themes/powerlevel10k"
    
    if [ ! -d "$theme_dir" ]; then
        echo "🎨 Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir" || {
            echo "⚠️  Failed to install Powerlevel10k theme"
            return 1
        }
    else
        echo "✅ Powerlevel10k theme already installed"
    fi
}

# ZSH configuration is now handled by focused generator functions:
# - generate_zsh_basic_config(): Basic ZSH settings, plugins, history  
# - generate_zsh_aliases(): All alias definitions
# - generate_zsh_functions(): Shell utility functions
# - generate_zsh_welcome(): Welcome message and final configuration
# - create_zshrc(): Main orchestrator function  
# See: /workspace/.devcontainer/scripts/shell/zsh-config.sh

# Note: The actual create_zshrc() function is now imported from the module above

# Function to create Powerlevel10k configuration
create_p10k_config() {
    echo "⚡ Creating Powerlevel10k configuration..."
    
    cat > "$HOME/.p10k.zsh" << 'EOF'
# Powerlevel10k configuration for ClaudePod
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  # Unset all configuration options (safely).
  local var
  for var in ${(M)${(k)parameters[@]}:#POWERLEVEL9K_*}; do
    unset $var
  done

  # The list of segments shown on the left. Fill it with the most important segments.
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    os_icon                 # os identifier
    dir                     # current directory
    vcs                     # git status
    prompt_char             # prompt symbol
  )

  # The list of segments shown on the right. Fill it with less important segments.
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status                  # exit code of the last command
    command_execution_time  # duration of the last command
    background_jobs         # presence of background jobs
    direnv                  # direnv status (https://direnv.net/)
    asdf                    # asdf version manager (https://github.com/asdf-vm/asdf)
    virtualenv              # python virtual environment (https://docs.python.org/3/library/venv.html)
    anaconda                # conda environment (https://conda.io/)
    pyenv                   # python environment (https://github.com/pyenv/pyenv)
    goenv                   # go environment (https://github.com/syndbg/goenv)
    nodenv                  # node.js version from nodenv (https://github.com/nodenv/nodenv)
    nvm                     # node.js version from nvm (https://github.com/nvm-sh/nvm)
    nodeenv                 # node.js environment (https://github.com/ekalinin/nodeenv)
    node_version            # node.js version
    time                    # current time
  )

  # Basic style options that define the overall look of your prompt.
  typeset -g POWERLEVEL9K_BACKGROUND=                            # transparent background
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE= # no surrounding whitespace
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '  # separate segments with a space
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=        # no end-of-line symbol
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=           # no segment icons

  # Directory colors
  typeset -g POWERLEVEL9K_DIR_BACKGROUND=4
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=254
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=250
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=255
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true

  # Git colors
  typeset -g POWERLEVEL9K_VCS_CLEAN_BACKGROUND=2
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=0
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND=3
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=0
  typeset -g POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=1
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=0

  # Prompt character
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=76
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=196

  # Time format
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'

  # Command execution time threshold
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3

  # Node.js version display
  typeset -g POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY=true
}

# Apply configuration
(( ! $#p10k_config_opts )) || setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
EOF

    echo "✅ Powerlevel10k configuration created"
}

# Main setup function
main() {
    # Check if ZSH setup is already complete
    if is_component_installed "zsh-setup"; then
        echo "✅ ZSH enhancement already complete (marker found)"
        if [ -f "$HOME/.zshrc" ] && [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
            echo "✓ .zshrc and Powerlevel10k theme verified"
            return 0
        else
            echo "⚠️  Marker exists but files missing, re-running setup..."
            rm -f "$STATE_DIR/zsh-setup.installed"
        fi
    fi
    
    echo "🐚 Starting ZSH enhancement setup..."
    
    # Ensure we're running as the correct user
    if [ "$(whoami)" != "$NODE_USER" ]; then
        echo "❌ This script should run as user $NODE_USER"
        exit 1
    fi
    
    # Check if Oh My Zsh is installed
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "❌ Oh My Zsh not found. Ensure the common-utils feature installed it."
        exit 1
    fi
    
    # Source NVM for this process
    export NVM_DIR="/usr/local/share/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install Powerlevel10k theme
    install_powerlevel10k
    
    # Install useful ZSH plugins (with error handling)
    echo "📦 Installing ZSH plugins..."
    install_zsh_plugin "zsh-autosuggestions" "zsh-users/zsh-autosuggestions" || echo "⚠️  Failed to install zsh-autosuggestions"
    install_zsh_plugin "zsh-syntax-highlighting" "zsh-users/zsh-syntax-highlighting" || echo "⚠️  Failed to install zsh-syntax-highlighting"
    install_zsh_plugin "zsh-completions" "zsh-users/zsh-completions" || echo "⚠️  Failed to install zsh-completions"
    install_zsh_plugin "fast-syntax-highlighting" "zdharma-continuum/fast-syntax-highlighting" || echo "⚠️  Failed to install fast-syntax-highlighting"
    install_zsh_plugin "history-substring-search" "zsh-users/zsh-history-substring-search" || echo "⚠️  Failed to install history-substring-search"
    
    # Create enhanced .zshrc
    create_zshrc
    
    # Create Powerlevel10k configuration
    create_p10k_config
    
    # Set ZSH as default shell
    echo "🔧 Setting ZSH as default shell..."
    if [ -f "/usr/bin/zsh" ]; then
        sudo chsh -s /usr/bin/zsh "$NODE_USER" || echo "⚠️  Could not change default shell"
    fi
    
    create_state_marker "zsh-setup" "plugins+theme+config"
    echo "✅ ZSH enhancement setup complete!"
    echo "💡 Restart your terminal or run 'source ~/.zshrc' to apply changes"
}

# Execute main function
main
