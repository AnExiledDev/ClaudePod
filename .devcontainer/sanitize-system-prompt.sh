#!/bin/bash
# Sanitize system prompt markdown for Claude CLI usage
# This script converts a markdown file to a format suitable for --append-system-prompt

set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: $0 <markdown-file>"
    exit 1
fi

MARKDOWN_FILE="$1"

if [ ! -f "$MARKDOWN_FILE" ]; then
    echo "Error: File '$MARKDOWN_FILE' not found"
    exit 1
fi

# Read the markdown file and perform sanitization
cat "$MARKDOWN_FILE" | \
    # Remove leading/trailing whitespace from each line
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
    # Escape double quotes
    sed 's/"/\\"/g' | \
    # Escape backslashes
    sed 's/\\/\\\\/g' | \
    # Join all lines with literal \n
    tr '\n' '\001' | \
    sed 's/\001/\\n/g' | \
    # Remove any trailing \n
    sed 's/\\n$//'