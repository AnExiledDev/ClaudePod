#!/bin/bash
# Git Configuration Examples for ClaudePod

# This script shows how to customize git configuration
# Run these commands inside the container to personalize your git setup

echo "🔧 Git Configuration Examples"
echo "Copy and modify these commands for your setup"

# Basic user configuration (replace with your details)
echo ""
echo "# User Configuration"
echo "git config --global user.name 'Your Name'"  
echo "git config --global user.email 'your.email@example.com'"

# Enhanced delta configuration (already set by default)
echo ""
echo "# Delta Configuration (already configured)"
echo "git config --global core.pager 'delta'"
echo "git config --global interactive.diffFilter 'delta --color-only'"
echo "git config --global delta.navigate true"
echo "git config --global delta.light false"
echo "git config --global delta.side-by-side true"
echo "git config --global delta.line-numbers true"
echo "git config --global delta.syntax-theme 'Dracula'"

# Merge and diff tools
echo ""
echo "# Merge and Diff Tools"
echo "git config --global merge.conflictstyle 'diff3'"
echo "git config --global diff.algorithm 'patience'"
echo "git config --global merge.tool 'code'"
echo "git config --global mergetool.code.cmd 'code --wait \$MERGED'"

# Useful aliases (some already set via shell aliases)
echo ""
echo "# Git Aliases"
echo "git config --global alias.st 'status'"
echo "git config --global alias.co 'checkout'"
echo "git config --global alias.br 'branch'"
echo "git config --global alias.ci 'commit'"
echo "git config --global alias.unstage 'reset HEAD --'"
echo "git config --global alias.last 'log -1 HEAD'"
echo "git config --global alias.visual '!gitk'"
echo "git config --global alias.tree 'log --oneline --graph --decorate --all'"
echo "git config --global alias.amend 'commit --amend --no-edit'"

# Push and pull configuration
echo ""
echo "# Push and Pull Configuration"
echo "git config --global push.default 'simple'"
echo "git config --global pull.rebase false"
echo "git config --global branch.autosetuprebase 'always'"

# Security settings
echo ""
echo "# Security Settings"
echo "git config --global init.defaultBranch 'main'"
echo "git config --global commit.gpgsign false  # Set to true if using GPG"
echo "git config --global tag.gpgsign false     # Set to true if using GPG"

# Performance settings
echo ""
echo "# Performance Settings"
echo "git config --global core.preloadindex true"
echo "git config --global core.fscache true"
echo "git config --global gc.auto 256"

# GitHub CLI integration (gh is already installed)
echo ""
echo "# GitHub CLI Integration"
echo "git config --global credential.helper '!gh auth git-credential'"

# Advanced diff and merge settings
echo ""
echo "# Advanced Settings"
echo "git config --global diff.renames copies"
echo "git config --global diff.mnemonicPrefix true"
echo "git config --global status.showUntrackedFiles all"
echo "git config --global log.abbrevCommit true"

echo ""
echo "✅ Copy the commands you want and run them in your container"
echo "💡 Your git config persists across container rebuilds"