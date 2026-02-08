# DevContainer Development Guide

CodeForge devcontainer for AI-assisted development with Claude Code.

## Directory Structure

```
/workspaces/
├── .devcontainer/           # Container configuration (this directory)
│   ├── devcontainer.json    # Main container definition
│   ├── .env                 # Environment variables
│   ├── config/              # Default configurations
│   │   ├── settings.json    # Claude Code settings
│   │   ├── keybindings.json # Claude Code keybindings
│   │   └── main-system-prompt.md
│   ├── features/            # Custom devcontainer features
│   ├── plugins/             # Local plugin marketplace
│   │   └── devs-marketplace/
│   └── scripts/             # Setup scripts
├── .claude/                 # Runtime Claude config (created on first run)
│   ├── settings.json        # Active settings (OVERWRITE_CONFIG=true → rebuilt each start)
│   ├── keybindings.json     # Active keybindings
│   └── system-prompt.md     # Active system prompt
└── .gh/                     # GitHub CLI config (persists across rebuilds)
    └── hosts.yml            # Authenticated hosts
```

## Key Configuration Files

| File | Purpose |
|------|---------|
| `devcontainer.json` | Container definition: base image, features, mounts, environment |
| `.env` | Environment variables controlling setup behavior |
| `config/settings.json` | Claude Code defaults: model, tokens, permissions, plugins |
| `config/keybindings.json` | Claude Code keybindings (empty by default — customizable) |
| `config/main-system-prompt.md` | Default system prompt defining assistant behavior |

> **Note**: `OVERWRITE_CONFIG=true` (default) means `.claude/settings.json` is overwritten on every container start. All persistent changes must go in `.devcontainer/config/settings.json`.

## Commands

| Command | Purpose |
|---------|---------|
| `claude` | Run Claude Code with auto-configuration (creates local `.claude/` if needed) |
| `cc` | Shorthand for `claude` with config |
| `ccraw` | Vanilla Claude Code without any config (bypasses function override) |
| `ccusage` | Analyze token usage history |
| `gh` | GitHub CLI for repo operations |
| `uv` | Fast Python package manager |
| `ast-grep` | Structural code search |

## Feature Development

Custom features live in `./features/`. Each feature follows the [devcontainer feature spec](https://containers.dev/implementors/features/):

```
features/
└── my-feature/
    ├── devcontainer-feature.json   # Metadata and options
    ├── install.sh                  # Installation script
    └── README.md                   # Documentation
```

To test a feature locally, reference it in `devcontainer.json`:
```json
"features": {
  "./features/my-feature": {}
}
```

> **Note**: The old `./features/claude-code` local feature is no longer used. Claude Code is installed via `ghcr.io/anthropics/devcontainer-features/claude-code:1` (Anthropic's official feature). The local `features/claude-code/` directory contains only a fallback config for the feature's install script.

## Setup Scripts

Scripts in `./scripts/` run via `postStartCommand`:

| Script | Purpose |
|--------|---------|
| `setup.sh` | Main orchestrator |
| `setup-config.sh` | Copies config files (settings, keybindings, system prompt) to `/workspaces/.claude/` |
| `setup-aliases.sh` | Creates `cc`/`claude`/`ccraw` shell aliases |
| `setup-plugins.sh` | Registers local marketplace + installs official Anthropic plugins |
| `setup-update-claude.sh` | Background auto-update of Claude Code binary |
| `setup-projects.sh` | Auto-detects projects for VS Code Project Manager |
| `setup-symlink-claude.sh` | Symlinks ~/.claude for third-party tool compatibility |

## Installed Plugins

Plugins are declared in `config/settings.json` under `enabledPlugins` and auto-activated on container start:

### Official (Anthropic)
- `frontend-design@claude-code-plugins` — UI/frontend design skill

### Local Marketplace (devs-marketplace)
- `codeforge-lsp@devs-marketplace` — LSP for Python + TypeScript/JavaScript
- `ticket-workflow@devs-marketplace` — EARS-based ticket workflow with GitHub integration
- `notify-hook@devs-marketplace` — Desktop notifications on completion
- `dangerous-command-blocker@devs-marketplace` — Blocks destructive bash commands
- `protected-files-guard@devs-marketplace` — Blocks edits to secrets/lock files
- `auto-formatter@devs-marketplace` — Auto-formats Python/Go/JS/TS on stop
- `auto-linter@devs-marketplace` — Auto-lints Python files via Pyright
- `code-directive@devs-marketplace` — 17 custom agents, 16 skills, syntax validation, skill suggestions, agent redirect hook

### Local Marketplace

The `devs-marketplace` in `plugins/` provides locally-managed plugins:

```
plugins/devs-marketplace/
├── .claude-plugin/
│   └── marketplace.json      # Marketplace manifest
└── plugins/
    ├── codeforge-lsp/        # Combined LSP plugin
    ├── ticket-workflow/      # EARS ticket workflow
    ├── auto-formatter/       # Batch formatter (Stop hook)
    ├── auto-linter/          # Pyright linter
    ├── code-directive/       # Agents, skills + hooks
    └── ...
```

## Agents & Skills

The `code-directive` plugin includes 17 custom agent definitions and 16 coding reference skills.

**Agents** (`plugins/devs-marketplace/plugins/code-directive/agents/`):
architect, bash-exec, claude-guide, debug-logs, dependency-analyst, doc-writer, explorer, generalist, git-archaeologist, migrator, perf-profiler, refactorer, researcher, security-auditor, spec-writer, statusline-config, test-writer

The `redirect-builtin-agents.py` hook (PreToolUse/Task) transparently swaps built-in agent types to these custom agents (e.g., Explore→explorer, Plan→architect).

**Skills** (`plugins/devs-marketplace/plugins/code-directive/skills/`):
claude-agent-sdk, claude-code-headless, debugging, docker, docker-py, fastapi, git-forensics, performance-profiling, pydantic-ai, refactoring-patterns, security-checklist, skill-building, specification-writing, sqlite, svelte5, testing

## VS Code Keybinding Conflicts

Claude Code runs inside VS Code's integrated terminal. VS Code intercepts some shortcuts before they reach the terminal:

| Shortcut | VS Code Action | Claude Code Action |
|----------|---------------|-------------------|
| `Ctrl+G` | Go to Line | `chat:externalEditor` |
| `Ctrl+S` | Save File | `chat:stash` |
| `Ctrl+T` | Open Symbol | `app:toggleTodos` |
| `Ctrl+O` | Open File | `app:toggleTranscript` |
| `Ctrl+B` | Toggle Sidebar | `task:background` |
| `Ctrl+P` | Quick Open | `chat:modelPicker` |
| `Ctrl+R` | Open Recent | `history:search` |

`Ctrl+P` and `Ctrl+F` are configured to pass through to the terminal via `terminal.integrated.commandsToSkipShell` in `devcontainer.json`. For other conflicts, use Meta (Alt) variants or customize via `config/keybindings.json`.

## Environment Variables

Key environment variables set in the container:

| Variable | Value |
|----------|-------|
| `WORKSPACE_ROOT` | `/workspaces` |
| `CLAUDE_CONFIG_DIR` | `/workspaces/.claude` |
| `GH_CONFIG_DIR` | `/workspaces/.gh` |
| `ANTHROPIC_MODEL` | `claude-opus-4-6` |
| `TMPDIR` | `/workspaces/.tmp` |

## Modifying Behavior

1. **Change default model**: Edit `config/settings.json`, update `"model"` field
2. **Change system prompt**: Edit `config/main-system-prompt.md`
3. **Change keybindings**: Edit `config/keybindings.json`
4. **Add features**: Add to `"features"` in `devcontainer.json`
5. **Disable auto-setup**: Set variables to `false` in `.env`
