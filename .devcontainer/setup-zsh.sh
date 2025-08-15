#!/bin/bash
# ZSH Configuration Script for ClaudePod
# This script enhances the ZSH setup with plugins, themes, and productivity features

set -euo pipefail

echo "🐚 Setting up enhanced ZSH configuration..."

# Variables
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
NODE_USER="node"

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

# Function to create enhanced .zshrc
create_zshrc() {
    echo "📝 Creating enhanced .zshrc configuration..."
    
    # Backup existing .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%s)" 2>/dev/null || true
    fi
    
    cat > "$HOME/.zshrc" << 'EOF'
# ClaudePod ZSH Configuration
# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Disable P10k configuration wizard
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# ZSH Configuration
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"
DISABLE_AUTO_UPDATE="false"
DISABLE_UPDATE_PROMPT="true"
export UPDATE_ZSH_DAYS=7
DISABLE_MAGIC_FUNCTIONS="false"
DISABLE_LS_COLORS="false"
DISABLE_AUTO_TITLE="false"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="false"
HIST_STAMPS="yyyy-mm-dd"

# ZSH Plugins
plugins=(
  git
  docker
  docker-compose
  node
  npm
  python
  pip
  vscode
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-completions
  fast-syntax-highlighting
  history-substring-search
  colored-man-pages
  command-not-found
  extract
  z
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# User configuration
export LANG=en_US.UTF-8
export EDITOR='code'
export ARCHFLAGS="-arch x86_64"

# History configuration
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_BEEP
setopt SHARE_HISTORY

# Path configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/share/npm-global/bin:$PATH"

# Node.js/NVM configuration
export NVM_DIR="/usr/local/share/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Python configuration
if command -v python3 &> /dev/null; then
    alias python=python3
    alias pip=pip3
fi

# ClaudePod aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias gco='git checkout'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias ga='git add'
alias gb='git branch'
alias gm='git merge'
alias gr='git rebase'
alias gf='git fetch'
alias gpl='git pull'

# Development aliases
alias c='code .'
alias cls='clear'
alias h='history'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# Claude Code aliases with optimized configuration
claude() {
    local mcp_config="/workspace/.devcontainer/config/claude/mcp.json"
    local system_prompt_file="/workspace/.devcontainer/config/claude/system-prompt.md"
    local system_prompt=""
    
    # Generate sanitized system prompt if file exists
    if [ -f "$system_prompt_file" ]; then
        system_prompt=$(/workspace/.devcontainer/sanitize-system-prompt.sh "$system_prompt_file" 2>/dev/null || echo "")
    fi
    
    # Build command with conditional arguments
    local cmd_args=(
        --model sonnet
        --dangerously-skip-permissions
    )
    
    # Add MCP config if file exists
    if [ -f "$mcp_config" ]; then
        cmd_args+=(--mcp-config "$mcp_config")
    fi
    
    # Add system prompt if successfully generated
    if [ -n "$system_prompt" ]; then
        cmd_args+=(--append-system-prompt "$system_prompt")
    fi
    
    # Execute claude with all arguments
    command claude "${cmd_args[@]}" "$@"
}

alias claude-help='claude --help'
alias claude-mcp='claude mcp list'
alias claude-version='claude --version'
alias claude-basic='command claude'  # Access original claude without optimizations

# Docker aliases (if docker is available)
if command -v docker &> /dev/null; then
    alias d='docker'
    alias dc='docker-compose'
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
    alias drm='docker rm'
    alias drmi='docker rmi'
fi

# Useful functions
# Extract various archive formats
extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find process by name
findp() {
    ps aux | grep -v grep | grep "$1"
}

# Quick HTTP server
serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port"
}

# Load Powerlevel10k configuration
if [[ -r ~/.p10k.zsh ]]; then
  source ~/.p10k.zsh
fi

# Auto-suggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=true

# Syntax highlighting configuration
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

# Welcome message
if [[ -n "$ZSH_VERSION" && -z "$VSCODE_RESOLVING_ENVIRONMENT" ]]; then
    echo "🚀 Welcome to ClaudePod!"
    echo "💡 Type 'claude' to start using Claude Code"
    echo "📋 Run 'claude mcp list' to see available MCP servers"
fi
EOF

    echo "✅ Enhanced .zshrc created"
}

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
    
    # Suppress NVM errors during this process
    export NVM_DIR="/usr/local/share/nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true
    
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
    
    echo "✅ ZSH enhancement setup complete!"
    echo "💡 Restart your terminal or run 'source ~/.zshrc' to apply changes"
}

# Execute main function
main
