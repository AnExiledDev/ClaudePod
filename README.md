# ClaudePod

A complete development container that sets up Claude Code with 8 powerful MCP servers, modern dev tools, and persistent configurations. Drop it into any project and get a production-ready AI development environment in minutes.

## What's Inside

**Claude Code CLI** with native binary installation and optimized configuration  
**8 MCP Servers** providing 100+ specialized tools for code analysis, documentation search, task management, and more  
**Modern Stack** - Node.js 20, Python 3.13, Git with delta, GitHub CLI  
**Smart Persistence** - Your Claude config, shell history, and npm cache survive container rebuilds  
**Enhanced Terminal** - Powerlevel10k with quiet mode and useful git aliases  

## Quick Start

### Using NPM Package

ClaudePod is available as an npm package at [npmjs.com/package/claudepod](https://www.npmjs.com/package/claudepod):

```bash
# Drop into any project
cd your-project
npx claudepod-devcontainer

# Fire it up
devpod up .
devpod ssh <workspace-name> --ide vscode  # <workspace-name> is usually your project folder name

# Start coding with Claude
claude
```

### Cloning from Repository

```bash
# Clone the repository
git clone https://github.com/AnExiledDev/ClaudePod.git
cd ClaudePod

# Copy .devcontainer to your project
cp -r .devcontainer /path/to/your-project/
cd /path/to/your-project

# Fire it up
devpod up .
devpod ssh <workspace-name> --ide vscode  # <workspace-name> is usually your project folder name

# Start coding with Claude
claude
```

That's it. No configuration files to edit, no API keys to hunt down. Everything works out of the box.

## The MCP Servers

ClaudePod ships with 8 MCP servers that turn Claude into a powerhouse:

- **Serena** - Advanced code analysis and semantic search
- **DeepWiki** - GitHub repository documentation search  
- **TaskMaster AI** - AI-powered project management
- **Sequential Thinking** - Structured problem-solving workflows
- **ccusage** - Claude Code usage analytics and cost tracking
- **SearXNG Enhanced** - Web search with content scraping
- **GitHub MCP** - Complete GitHub API integration (API key required)
- **Tavily + Ref.Tools** - Web search and documentation tools (API keys required)

**Tool Permissions**: When Claude first starts, it will ask permission to use these MCP tools. You can deny or allow specific tools based on your needs - this helps manage the large number of available tools (100+). Future versions will make this easier to configure.

## Requirements

- **[DevPod](https://devpod.sh/)** installed and configured - the container development platform
- **VS Code** with Remote Development extensions
- That's literally it

## Container Details

**Base**: Ubuntu 22.04  
**User**: node (1000:1000)  
**Workspace**: `/workspace` (your project files)  
**Persistent**: Claude config, shell history, npm cache  

Your files stay exactly where they are. ClaudePod only adds a `.devcontainer/` directory.

## Handy Commands

```bash
# Claude with statusline and MCP servers
claude

# Git shortcuts (with beautiful diffs)
gs    # git status
gd    # git diff
gc    # git commit
gp    # git push
gl    # git log --oneline --graph

# Python without the pain
uvx <package>     # Run packages without installing
uv add <package>  # Add dependencies  

# Quick info
claudepod_info    # Show status and commands
```

## Optional Upgrades

**Web search is already included** via the built-in SearXNG server - no limits, no API keys required. But you can add more integrations:

```bash
cp .devcontainer/.env.example .devcontainer/.env
# Edit .devcontainer/.env with your keys
```

```bash
# GitHub integration (recommended)
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token

# Additional web search via Tavily (optional - SearXNG already provides unlimited search)
TAVILY_API_KEY=tvly-your-key

# Documentation tools
REF_TOOLS_API_KEY=your-key
```

## Customization & Pitfalls

### The Good News
ClaudePod is designed to be unbreakable. It uses smart configuration templates that preserve your customizations across container rebuilds.

### System Prompt Customization

**Custom System Prompts** - ClaudePod includes a system prompt file that gets automatically loaded into Claude Code:

```bash
# Edit the system prompt file
.devcontainer/config/claude/system-prompt.md
```

This file allows you to add project-specific instructions, coding standards, or context that Claude should remember throughout your sessions. Changes are automatically applied when the container starts.

**Output Styles** - Claude Code's output styles can be paired with your custom system prompt for even more specialized behavior:

```bash
# Create custom output styles in Claude Code
/output-style:new I want an output style that focuses on performance optimization
```

Output styles modify Claude's system prompt to change how it responds - perfect for specialized workflows like code reviews, documentation writing, or educational contexts.

### Common Gotchas

**Override Flags** - ClaudePod has environment variables like `OVERRIDE_CLAUDE_SETTINGS=true` that can overwrite your customizations. Only use these if you want to reset to defaults.

**Port Conflicts** - If you run services on ports 8080, 3000, or 5000 locally, add port forwarding rules to avoid conflicts:

```json
{
  "forwardPorts": [3001, 8081, 5001],
  "portsAttributes": {
    "3001": { "label": "Your App" }
  }
}
```

**Configuration Complexity** - ClaudePod has many layers (devcontainer.json, .env, MCP templates, tool configs). Stick to editing `.devcontainer/.env` for most customizations.

### Safe Customization

Edit `.devcontainer/devcontainer.json` after installation:

```json
{
  "containerEnv": {
    "YOUR_API_KEY": "${localEnv:YOUR_API_KEY}"
  },
  "customizations": {
    "vscode": {
      "extensions": ["your.extension.id"]
    }
  },
  "features": {
    "ghcr.io/devcontainers/features/aws-cli:1": {}
  }
}
```

## Troubleshooting

**Container won't start?**
```bash
devpod delete <workspace> && devpod up .  # <workspace> is your project folder name
# Don't worry - this preserves your ClaudePod configuration and project files
```

**Claude authentication issues?**
```bash
claude login
```

**MCP servers missing?**
```bash
claude mcp list
# If empty, restart the container
```

**npm permission errors?**
```bash
# Inside container - fix npm permissions
sudo chown -R node:node /home/node/.npm
sudo chown -R node:node /home/node/.local
```

**Configuration got overwritten?**
Look in `.devcontainer/config/backups/` - ClaudePod automatically backs up your configs before making changes.

## Architecture

ClaudePod uses a two-phase setup:
1. **post-create.sh** - Installs Claude Code, dev tools, and creates base configurations
2. **post-start.sh** - Installs MCP servers and validates everything works

The setup is idempotent - you can rebuild containers without losing your customizations (unless you use override flags).

## Team Usage

Perfect for teams who want consistent environments:

```bash
# Team member 1 sets up the project
cd shared-project
npx claudepod-devcontainer
git add .devcontainer/ && git commit -m "Add ClaudePod"

# Everyone else just runs
devpod up .
```

Each developer gets an identical environment with the same Claude configuration, MCP servers, and tools.

## What Gets Added

```
your-project/
├── .devcontainer/
│   ├── devcontainer.json           # Main container config
│   ├── post-create.sh             # Tool installation
│   ├── post-start.sh              # MCP server setup
│   ├── .env.example               # API key template
│   ├── config/
│   │   ├── claude/                # Claude Code templates
│   │   ├── serena/                # Serena config
│   │   └── taskmaster/            # TaskMaster config
│   └── scripts/                   # Modular setup scripts
└── (your files stay exactly the same)
```

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0). See the [full license text](https://www.gnu.org/licenses/gpl-3.0.txt) for details.

The GPL-3.0 is a copyleft license that ensures this software remains free and open source, requiring any modifications or derivative works to be released under the same license terms.

---

**Ready to code with AI superpowers?** ClaudePod turns any project into an AI-native development environment.
