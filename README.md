# ClaudePod DevContainer

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![npm version](https://img.shields.io/npm/v/claudepod.svg)](https://www.npmjs.com/package/claudepod)

A curated development environment optimized for AI-powered coding with Claude Code. ClaudePod comes pre-configured with language servers, code intelligence tools, and official Anthropic plugins to streamline your development workflow.

## Installation

Add ClaudePod to any project:

```bash
npx claudepod
```

This copies the `.devcontainer/` directory to your project. Then open in VS Code and select "Reopen in Container".

### Options

```bash
npx claudepod --force    # Overwrite existing .devcontainer directory
npx claudepod -f         # Short form
```

### Alternative Install Methods

```bash
# Install globally
npm install -g claudepod
claudepod

# Run specific version
npx claudepod@1.2.3
```

## Prerequisites

- **Docker Desktop** (or compatible container runtime like Podman)
- **VS Code** with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers), or **GitHub Codespaces**
- **Claude Code authentication** - see [Authentication](#authentication) section

## Quick Start

1. **Open in Container**
   - VS Code: Open the folder, then select "Reopen in Container" from the command palette
   - Codespaces: Create a new codespace from this repository

2. **Authenticate** (first time only)
   ```bash
   claude
   ```
   Follow the prompts to authenticate via browser or API key.

3. **Start Claude Code**
   ```bash
   cc
   ```

## Authentication

Claude Code supports multiple authentication methods. On first run, you'll be prompted to choose:

### Browser Login (Recommended)

```bash
claude
```

Select "Login with browser" and complete authentication in your browser. This uses your Claude.ai account.

### API Key

For programmatic access or environments without browsers:

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
claude
```

Get an API key from [console.anthropic.com](https://console.anthropic.com/).

### Credential Persistence

Authentication credentials are stored in `/workspaces/.claude/` and persist across container rebuilds.

For more options, see the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code).

## GitHub CLI Authentication

GitHub CLI (`gh`) is pre-installed for repository operations like pushing code, creating pull requests, and accessing private repositories.

### Interactive Login (Recommended)

```bash
gh auth login
```

Follow the prompts:
1. Select **GitHub.com** (or your enterprise server)
2. Choose your preferred protocol: **HTTPS** (recommended) or **SSH**
3. Authenticate via **browser** (easiest) or paste a personal access token

### Token-Based Login

For automated setups or environments without browser access:

```bash
# From a file
gh auth login --with-token < ~/github-token.txt

# From environment variable
echo "$GITHUB_TOKEN" | gh auth login --with-token
```

Generate a token at [github.com/settings/tokens](https://github.com/settings/tokens) with appropriate scopes (typically `repo`, `read:org`).

### Verifying Authentication

```bash
gh auth status
```

Expected output shows your authenticated account and token scopes.

### Credential Persistence

GitHub CLI credentials are automatically persisted across container rebuilds. The container is configured to store credentials in `/workspaces/.gh/` (via `GH_CONFIG_DIR`), which is part of the bind-mounted workspace.

**You only need to authenticate once.** After running `gh auth login`, your credentials will survive container rebuilds and be available in future sessions.

## Available Tools

### Languages & Runtimes
| Tool | Description |
|------|-------------|
| Python 3.14 | Base language runtime |
| Node.js LTS | JavaScript runtime |
| TypeScript | Via Node.js |

### Package Managers
| Tool | Description |
|------|-------------|
| `uv` | Fast Python package manager (pip alternative) |
| `npm` | Node.js package manager |
| `pip` / `pipx` | Python package installers |

### Development Tools
| Tool | Description |
|------|-------------|
| `gh` | GitHub CLI for repository operations |
| `docker` | Container CLI (connects to host Docker) |
| `git` | Version control |
| `jq` | JSON processor |
| `curl` | HTTP client |

### Code Intelligence
| Tool | Description |
|------|-------------|
| tree-sitter | AST parsing for JavaScript, TypeScript, Python |
| ast-grep | Structural code search and rewriting |
| Pyright | Python language server |
| TypeScript LSP | TypeScript/JavaScript language server |

### Claude Code Tools
| Tool | Description |
|------|-------------|
| `claude` | Claude Code CLI |
| `cc` | Wrapper with auto-configuration |
| `ccusage` | Token usage analyzer |
| `ccstatusline` | Status line for sessions |
| `claude-monitor` | Real-time usage tracking |

## Using Claude Code

### The `cc` Command

The `cc` command is a wrapper that:
- Creates a project-local `.claude/` directory if missing
- Copies default configuration files
- Launches Claude Code with the project's system prompt

```bash
cc                    # Start Claude Code in current directory
cc "explain this"     # Start with an initial prompt
```

### Direct CLI

For more control, use the `claude` command directly:

```bash
claude                        # Basic invocation
claude --help                 # View all options
claude --resume               # Resume previous session
```

## Configuration

### Environment Variables

Edit `.devcontainer/.env` to customize behavior:

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_CONFIG_DIR` | `/workspaces/.claude` | Claude configuration directory |
| `SETUP_CONFIG` | `true` | Copy config files during setup |
| `OVERWRITE_CONFIG` | `true` | Overwrite existing configs |
| `SETUP_ALIASES` | `true` | Add `cc` alias to shell |
| `SETUP_PLUGINS` | `true` | Install official plugins |

### Claude Code Settings

Default settings are in `.devcontainer/config/settings.json`. These are copied to `/workspaces/.claude/settings.json` on first run.

Key defaults:
- **Model**: Claude Opus 4.5
- **Default mode**: Plan (prompts before executing)
- **Max output tokens**: 64,000

### System Prompt

The default system prompt is in `.devcontainer/config/main-system-prompt.md`. Override it by creating a `.claude/system-prompt.md` in your project directory.

## Custom Features

ClaudePod includes several custom devcontainer features:

| Feature | Description |
|---------|-------------|
| `claude-monitor` | Real-time token usage monitoring with ML predictions |
| `ccusage` | Usage analytics CLI |
| `ccstatusline` | Compact powerline status display |
| `ast-grep` | Structural code search using AST patterns |
| `tree-sitter` | Parser with JS/TS/Python grammars |
| `lsp-servers` | Pyright and TypeScript language servers |

## Essential Gotchas

- **Authentication required**: Run `claude` once to authenticate before using `cc`
- **Plan mode default**: The container starts in "plan" mode, which prompts for approval before making changes
- **Project-local config**: The `cc` command creates `.claude/` in your current directory for project-specific settings
- **GitHub auth persists**: Run `gh auth login` once; credentials survive container rebuilds (stored in `/workspaces/.gh/`)

## Development

### Testing Locally

```bash
git clone https://github.com/AnExiledDev/ClaudePod.git
cd ClaudePod
npm test
```

### Publishing

```bash
# Bump version in package.json, then:
npm publish
```

## Further Reading

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Dev Containers Specification](https://containers.dev/)
- [GitHub CLI Manual](https://cli.github.com/manual/)
