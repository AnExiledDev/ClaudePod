#!/bin/bash

# ZSH Configuration Module
# Handles focused ZSH configuration generation

# Function to generate basic ZSH configuration
generate_zsh_basic_config() {
    cat << 'EOF'
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

# Suppress P10k instant prompt warnings (quiet mode)
export POWERLEVEL9K_INSTANT_PROMPT=quiet

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

EOF
}

# Function to generate ZSH aliases
generate_zsh_aliases() {
    cat << 'EOF'
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

EOF

    # Add Docker aliases conditionally
    cat << 'EOF'
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

EOF
}

# Function to generate ZSH utility functions
generate_zsh_functions() {
    cat << 'EOF'
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

EOF
}

# Function to generate ZSH welcome and final configuration
generate_zsh_welcome() {
    cat << 'EOF'
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
if [[ -n "$ZSH_VERSION" ]]; then
    echo "🚀 Welcome to ClaudePod!"
    echo "💡 Type 'claude' to start using Claude Code"
    echo "📋 Run 'claude mcp list' to see available MCP servers"
fi
EOF
}

# Main function to create enhanced .zshrc using focused generators
create_zshrc() {
    echo "📝 Creating enhanced .zshrc configuration..."
    
    # Backup existing .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%s)" 2>/dev/null || true
    fi
    
    # Generate complete .zshrc using focused components
    {
        generate_zsh_basic_config
        generate_zsh_aliases  
        generate_zsh_functions
        generate_zsh_welcome
    } > "$HOME/.zshrc"
    
    echo "✅ Enhanced .zshrc created"
}