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
| `cc` | Run Claude Code with auto-configuration (creates local `.claude/` if needed) |
| `claude` | Direct Claude Code CLI |
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
| `setup-lsp.sh` | Installs LSP plugins |
| `setup-plugins.sh` | Installs official Anthropic plugins |

## Installed Plugins

Automatically installed on container start:

- `frontend-design@claude-plugins-official`
- `code-review@claude-plugins-official`
- `commit-commands@claude-plugins-official`
- `pr-review-toolkit@claude-plugins-official`

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
