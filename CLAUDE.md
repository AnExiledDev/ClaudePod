# ClaudePod Development Container

A fully configured DevPod environment optimized for Claude Code development with MCP servers, modern development tools, and persistent configuration. Features comprehensive template-based configuration management for consistent development environments.

## Container Overview

**Base**: Ubuntu 22.04  
**Runtime**: DevPod + VS Code Remote  
**User**: `node` (uid: 1000, gid: 1000)  

## Installed Tools & Features

### Core Development Stack
- **Node.js 20** (via NVM) - JavaScript/TypeScript development
- **Python 3.13** (with pipx, common tools) - Python development  
- **Git** (with git-delta for enhanced diffs) - Version control
- **GitHub CLI** - GitHub integration
- **Claude Code CLI** - AI-powered development assistant with optimized tool configuration

### MCP Servers (Model Context Protocol)

**Pre-installed (no API key required):**
- **Serena** - Advanced code analysis and semantic search
  - Installed from GitHub repository: https://github.com/oraios/serena
  - Provides web-based dashboard for logs (runs on localhost when active)
  - Context: ide-assistant for optimal Claude integration
- **DeepWiki** - HTTP-based documentation and knowledge search
- **Task Master** - AI-powered task management and project execution
  - Installed from NPM package: task-master-ai
  - No API keys required when used with Claude Code
  - Provides PRD parsing, task management, and autonomous development workflows
- **Sequential Thinking** - Structured progressive thinking and problem-solving
  - Installed from GitHub repository: https://github.com/arben-adm/mcp-sequential-thinking
  - Facilitates structured, progressive thinking through defined stages
  - Tracks thinking progression and generates summaries
  - Tools: process_thought, generate_summary, clear_history, export_session, import_session
- **ccusage** - Claude Code usage analysis and cost tracking
  - Installed from NPM package: ccusage
  - Analyzes token usage and costs from local Claude Code JSONL files
  - Provides daily, session, monthly, and 5-hour block reports
  - Tools: daily, session (provides usage analytics directly within Claude Code)

**Available with API keys (see examples/mcp-server-setup.sh):**
- **GitHub MCP Server** - GitHub repository integration (requires GITHUB_PERSONAL_ACCESS_TOKEN)
  - Repository and file access, issue management, PR operations
  - GitHub Actions integration, code security analysis
  - Installed via Docker: `ghcr.io/github/github-mcp-server:latest`
  - Setup guide: [docs/github-mcp-setup.md](docs/github-mcp-setup.md)
- **Tavily Search** - Web search capabilities (requires TAVILY_API_KEY)
- **Ref.Tools** - Reference documentation tools (requires REF_TOOLS_API_KEY)

### Development Tools
- **uv/uvx** - Fast Python package manager
- **git-delta** - Syntax-highlighted git diffs with side-by-side view
- **ccusage** - CLI tool for analyzing Claude Code token usage and costs from local JSONL files
- **Shell aliases** - Common git shortcuts (gs, gd, gc, gp, gl)
- **VS Code extensions** - Remote development, Python, ESLint, Prettier, GitLens

### Optimized Tool Configuration

Claude Code comes pre-configured with an **optimized tool allowlist** that provides:

- **79 essential tools allowed** (reduced from 161 total)
- **51% reduction** in tool choice complexity
- **Zero permission prompts** for common workflows
- **Intelligent tool selection** prioritizing MCP over built-in tools

**Tool Categories Allowed:**
- **Built-ins (3)**: Bash, Write, TodoWrite
- **Serena (20)**: Complete semantic code analysis suite  
- **Tavily (4)**: Complete web research capabilities
- **TaskMaster AI (14)**: Core + high-frequency project management
- **GitHub (27)**: Essential + high-frequency workflow tools
- **IDE (2)**: VS Code diagnostics + Jupyter execution
- **MCP Meta (2)**: Resource management tools
- **Ref.Tools (5)**: Documentation and API reference tools

**Smart Replacements:**
- `Read/Edit/MultiEdit` → Serena's semantic editing tools
- `Glob/Grep/LS` → Serena's code-aware search
- `WebFetch/WebSearch` → Tavily's superior research capabilities

This configuration covers ~90% of development scenarios while maintaining focus and eliminating decision fatigue.

## Template Configuration System

ClaudePod uses a comprehensive template-based configuration system for consistent, optimized setups:

### **Configuration Templates**
Located in `.devcontainer/config/`:
- **`claude/settings.json`** - Optimized tool allowlist (85 allowed, 91 denied)
- **`claude/mcp.json`** - MCP server definitions with environment variable support
- **`claude/system-prompt.md`** - ClaudePod-specific system prompt for enhanced workflows
- **`serena/serena_config.yml`** - Optimized Serena configuration for containers
- **`taskmaster/config.json`** - TaskMaster configuration with Claude Code integration

### **Smart Configuration Management**
- **Post-create**: Copies optimized templates to appropriate locations
- **Post-start**: Preserves existing configurations, only creates defaults when missing
- **Environment variables**: Sourced from `.devcontainer/.env` for API keys
- **Bind mounts**: Configuration persists across container rebuilds

### **Enhanced Claude Alias**
The `claude` command is enhanced with:
```bash
claude() {
    # Automatically uses:
    # --mcp-config /workspace/.devcontainer/config/claude/mcp.json
    # --append-system-prompt <sanitized-content-from-system-prompt.md>
    # --dangerously-skip-permissions
    # --model sonnet
}
```

**Additional aliases:**
- `claude-basic` - Access original Claude without optimizations
- `claude-help` - Show Claude help
- `claude-mcp` - List MCP servers
- `claude-version` - Show Claude version

## Persistent Storage

The following data persists across container rebuilds via Docker volumes:

- **Claude configuration** - `~/.claude` and `~/.config/claude`
- **Shell history** - Bash and Zsh command history
- **Git configuration** - User settings and credentials
- **NPM cache and configuration** - `~/.npm` and `~/.config`
- **NPM global packages** - `~/.local` (includes Claude Code CLI)

## Quick Start

1. **Start the container**:
   ```bash
   devpod up .
   ```

2. **Connect with VS Code**:
   ```bash
   devpod ssh <workspace-name> --ide vscode
   ```

3. **Start using Claude**:
   ```bash
   claude
   ```

## Commands & Usage

### Essential Commands
```bash
# Claude Code (pre-configured with 79 optimized tools)
claude                    # Start Claude Code (no permission prompts)
claude mcp list          # List available MCP servers
claude --help           # Claude Code help

# Usage Analytics
ccusage                  # Show daily Claude Code usage report
ccusage session          # Show usage by conversation sessions
ccusage monthly          # Show monthly aggregated usage
ccusage blocks --live    # Real-time usage dashboard

# Development
gs                       # git status
gd                       # git diff (with delta)  
gc                       # git commit
gp                       # git push
gl                       # git log --oneline --graph --decorate

# Python package management
uvx <package>           # Run Python packages without installing
uv add <package>        # Add Python dependencies

# GitHub MCP server setup
/workspace/scripts/install-github-mcp.sh  # Install GitHub MCP server
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token"  # Set GitHub PAT
```

### VS Code Extensions
The container automatically installs these extensions when you connect:
- Remote Development Pack
- Python + Pylance
- ESLint + Prettier  
- GitLens
- GitHub Pull Requests

## Configuration Files

### Git Configuration
Git is pre-configured to use delta as the pager:
```bash
git config --global core.pager "delta"
git config --global delta.side-by-side true
git config --global delta.navigate true
```

### MCP Server Configuration  
MCP servers are automatically configured and available to Claude Code:
- No additional setup required
- Servers activate when Claude uses them
- Add API keys via environment variables for additional servers

## Troubleshooting

### Common Issues

**Claude authentication needed**:
```bash
claude login  # Follow the authentication flow
```

**MCP server not working**:
```bash
claude mcp list          # Check server status
claude mcp remove <name> # Remove problematic server
claude mcp add <name> -- <command>  # Reinstall server
```

**Missing tools**:
```bash
which <tool>            # Check if tool is installed
echo $PATH              # Verify PATH includes ~/.local/bin
```

### Container Rebuild
If you need a fresh start:
```bash
devpod delete <workspace>
devpod up .
```

Note: Persistent volumes (Claude config, shell history) will be preserved.

## Development Workflows

### Python Development
```bash
cd /workspace
uv init                 # Initialize Python project
uv add requests         # Add dependencies
uvx ruff check .        # Lint code
claude                  # Get AI assistance
```

### Node.js Development  
```bash
cd /workspace
npm init -y            # Initialize Node project
npm install <package>  # Add dependencies
claude                 # Get AI assistance with MCP servers
```

### Git Workflow
```bash
gs                     # Check status
gd                     # View changes with delta
gc -m "message"        # Commit changes
gp                     # Push to remote
gl                     # View commit history
```

## Architecture Notes

### Container Lifecycle
1. **Build**: DevContainer features install base tools
2. **Post-create**: Claude Code + development tools installed  
3. **Post-start**: MCP servers configured and activated
4. **Runtime**: Full development environment ready

### File Structure
```
/workspace              # Your project files (bind mount)
/home/node/.claude      # Claude configuration (volume)
/home/node/.local/bin   # User-installed tools
/usr/local/share/nvm    # Node.js installation
/usr/local/py-utils     # Python tools installation
```

### Networking
- Container runs on host network for optimal performance
- All standard development ports available
- VS Code extensions communicate via SSH tunnel

## Contributing

This container configuration is designed to be:
- **Reproducible** - Same environment every time
- **Persistent** - Important data survives rebuilds  
- **Extensible** - Easy to add new tools and configurations
- **Efficient** - Fast startup with proper caching

For modifications, update the `.devcontainer/` configuration files and rebuild.

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
