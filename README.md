# ClaudePod DevContainer Package

A fully configured DevContainer optimized for Claude Code development with MCP servers, modern development tools, and persistent configuration. Easily add this development environment to any project with one command.

## 🚀 Quick Setup

```bash
# Install in any project directory
npx claudepod-devcontainer

# Start the container
devpod up .

# Connect with VS Code
devpod ssh <workspace-name> --ide vscode

# Start coding with Claude
claude
```

## ✨ What You Get

### 🛠️ Development Stack
- **Node.js 20** (via NVM) + npm/npx
- **Python 3.13** with pipx, uv/uvx, and common tools  
- **Git** with git-delta for beautiful diffs
- **GitHub CLI** for repository operations
- **Claude Code CLI** with optimized tool configuration

### 🔌 MCP Servers (Pre-configured)
- **Serena** - Advanced code analysis and semantic search
- **DeepWiki** - GitHub repository documentation search  
- **TaskMaster AI** - AI-powered project management
- **Sequential Thinking** - Structured problem-solving
- **GitHub MCP** - Complete GitHub API integration (requires API key)
- **Tavily Search** - Web search capabilities (requires API key)
- **Ref.Tools** - Documentation tools (requires API key)

### ⚡ Productivity Features
- **Optimized tool configuration** - 79 essential tools pre-allowed (51% reduction from 161 total)
- **Zero permission prompts** for common development workflows
- **Intelligent tool selection** - Prioritizes powerful MCP tools over basic built-ins
- **Shell aliases** - `gs`, `gd`, `gc`, `gp`, `gl` for git operations
- **Persistent storage** - Claude config and shell history survive rebuilds
- **VS Code extensions** - Pre-configured for remote development

## 📋 Requirements

1. **DevPod** installed and configured
2. **VS Code** with Remote Development Extension Pack:
   ```bash
   code --install-extension ms-vscode-remote.vscode-remote-extensionpack
   ```

## 🔧 Usage

### Install in Existing Project
```bash
cd my-existing-project
npx claudepod-devcontainer
devpod up .
```

### New Project Setup
```bash
mkdir new-project && cd new-project
npx claudepod-devcontainer
devpod up .
```

### First-Time Container Setup
```bash
# Inside the container
./scripts/setup-env.sh  # Optional environment setup
claude login           # Authenticate with Claude
claude                 # Start development
```

## 🎯 Quick Commands

```bash
# Claude Code (with MCP servers, no permission prompts)
claude                    # Start Claude 
claude mcp list          # List available MCP servers

# Git (with aliases and delta highlighting)
gs                       # git status
gd                       # git diff 
gc -m "message"          # git commit
gp                       # git push
gl                       # git log --oneline --graph

# Python development
uvx <package>            # Run packages without installing
uv add <package>         # Add dependencies

# Health check
./scripts/health-check.sh # Verify everything works
```

## 🔑 Optional API Keys

Add these to your environment for enhanced features:

```bash
# GitHub integration (recommended)
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token"

# Web search capabilities  
export TAVILY_API_KEY="tvly-your-key"

# Documentation tools
export REF_TOOLS_API_KEY="your-key"
```

## 📁 What Gets Installed

```
your-project/
├── .devcontainer/
│   ├── devcontainer.json    # Container configuration
│   ├── post-create.sh       # Development tools setup  
│   └── post-start.sh        # MCP server installation
└── (your existing files remain unchanged)
```

## 🏗️ Container Architecture

- **Base**: Ubuntu 22.04
- **User**: `node` (uid: 1000, gid: 1000)
- **Workspace**: `/workspace` (your project files)
- **Persistent Data**: Claude config, shell history, npm cache
- **Network**: Host network for optimal development server performance

## 🔧 Customization

After installation, you can modify `.devcontainer/devcontainer.json`:

```json
{
  "containerEnv": {
    "YOUR_API_KEY": "${localEnv:YOUR_API_KEY}"
  },
  "customizations": {
    "vscode": {
      "extensions": ["your.extension.id"]
    }
  }
}
```

## 🩺 Troubleshooting

```bash
# Container not starting?
devpod delete <workspace> && devpod up .

# Claude not authenticated?
claude login

# MCP servers not working?
claude mcp list
claude mcp remove <server> && claude mcp add <server>

# Check container health
./scripts/health-check.sh
```

## 📚 Documentation

After installation, see:
- `CLAUDE.md` - Complete container documentation
- `examples/` - Configuration examples
- `scripts/` - Helper scripts and utilities

## 🤝 Team Usage

Each team member runs:
```bash
cd shared-project
npx claudepod-devcontainer  # Installs .devcontainer
devpod up .                 # Starts identical environment
```

Perfect for ensuring consistent development environments across your team!

---

**Ready to supercharge your development with AI!** 🚀