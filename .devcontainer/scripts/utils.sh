#!/bin/bash

# ClaudePod Shared Utilities
# Common functions used across multiple setup scripts

# Function to retry a command with exponential backoff
# Usage: retry_command <max_attempts> <delay_seconds> <command> [args...]
# Example: retry_command 3 5 npm install -g some-package
retry_command() {
    local max_attempts=${1:-3}
    local delay=${2:-5}
    shift 2
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if "$@"; then
            return 0
        fi
        echo "⚠️  Command failed (attempt $attempt/$max_attempts): $*"
        if [ $attempt -lt $max_attempts ]; then
            echo "   Retrying in ${delay}s..."
            sleep $delay
        fi
        ((attempt++))
    done
    return 1
}

# Function to add directory to PATH without duplication
# Usage: add_to_path <directory>
# Example: add_to_path "/home/node/.local/bin"
add_to_path() {
    local dir="$1"
    case ":$PATH:" in
        *":$dir:"*) 
            # Directory already in PATH
            return 0
            ;;
        *) 
            # Add directory to PATH
            export PATH="$dir:$PATH"
            ;;
    esac
}