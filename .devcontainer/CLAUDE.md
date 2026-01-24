# DevContainer Development Guide

ClaudePod devcontainer for AI-assisted development with Claude Code.

## Directory Structure

```
/workspaces/
├── .devcontainer/           # Container configuration (this directory)
│   ├── devcontainer.json    # Main container definition
│   ├── .env                 # Environment variables
│   ├── config/              # Default configurations
│   │   ├── settings.json    # Claude Code settings
│   │   └── main-system-prompt.md
│   ├── features/            # Custom devcontainer features
│   ├── plugins/             # Local plugin marketplace
│   │   └── devs-marketplace/
│   └── scripts/             # Setup scripts
├── .claude/                 # Runtime Claude config (created on first run)
│   ├── settings.json        # Active settings
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
| `config/main-system-prompt.md` | Default system prompt defining assistant behavior |

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

## Setup Scripts

Scripts in `./scripts/` run via `postStartCommand`:

| Script | Purpose |
|--------|---------|
| `setup.sh` | Main orchestrator |
| `setup-config.sh` | Copies config files to `/workspaces/.claude/` |
| `setup-aliases.sh` | Creates `cc` shell function |
| `setup-lsp.sh` | Installs LSP plugins from local marketplace |
| `setup-plugins.sh` | Installs official Anthropic plugins |

## Installed Plugins

Automatically installed on container start:

- `frontend-design@claude-plugins-official` (skill)
- `claudepod-lsp@devs-marketplace` (LSP for Python + TypeScript/JavaScript)

### Local Marketplace

The `devs-marketplace` in `plugins/` provides locally-managed plugins:

```
plugins/devs-marketplace/
├── .claude-plugin/
│   └── marketplace.json      # Marketplace manifest
└── plugins/
    └── claudepod-lsp/        # Combined LSP plugin
        └── .claude-plugin/
            └── plugin.json
```

This gives full control over LSP configuration without external dependencies.

## Environment Variables

Key environment variables set in the container:

| Variable | Value |
|----------|-------|
| `WORKSPACE_ROOT` | `/workspaces` |
| `CLAUDE_CONFIG_DIR` | `/workspaces/.claude` |
| `GH_CONFIG_DIR` | `/workspaces/.gh` |
| `ANTHROPIC_MODEL` | `claude-opus-4-5-20251101` |

## Modifying Behavior

1. **Change default model**: Edit `config/settings.json`, update `"model"` field
2. **Change system prompt**: Edit `config/main-system-prompt.md`
3. **Add features**: Add to `"features"` in `devcontainer.json`
4. **Disable auto-setup**: Set variables to `false` in `.env`
