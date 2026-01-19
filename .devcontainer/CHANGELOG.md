# ClaudePod Devcontainer Changelog

## [2025-01-19] Documentation & GitHub CLI Persistence

### Added
- **README.md**: Comprehensive documentation including:
  - Prerequisites and quick start guide
  - GitHub CLI authentication instructions (interactive and token-based)
  - Available tools reference tables
  - Configuration guide
  - Essential gotchas
- **CLAUDE.md**: Development guide for Claude Code with:
  - Directory structure overview
  - Key configuration files reference
  - Command reference
  - Feature development guide
  - Setup scripts documentation
- **GitHub CLI Credential Persistence**: Added `GH_CONFIG_DIR=/workspaces/.gh` to `remoteEnv` so credentials survive container rebuilds

### Files Created
- `/workspaces/.devcontainer/README.md`
- `/workspaces/.devcontainer/CLAUDE.md`

### Files Modified
- `/workspaces/.devcontainer/devcontainer.json` - Added `GH_CONFIG_DIR` environment variable

---

## [2025-01-19] Configuration Updates

### Added
- **GitHub CLI**: Added `ghcr.io/devcontainers/features/github-cli:1` feature for GitHub operations
- **Official Anthropic Plugins**: New `setup-plugins.sh` script installs 7 official plugins:
  - `@anthropics/claude-plugins-official/frontend-design`
  - `@anthropics/claude-plugins-official/code-review`
  - `@anthropics/claude-plugins-official/commit-commands`
  - `@anthropics/claude-plugins-official/pr-review-toolkit`
  - `@anthropics/claude-plugins-official/typescript-lsp`
  - `@anthropics/claude-plugins-official/pyright-lsp`
  - `@anthropics/claude-plugins-official/code-simplifier`
- **SETUP_PLUGINS** environment variable to control plugin installation

### Changed
- **Plan Mode Default**: Changed `defaultMode` from `"dontAsk"` to `"plan"` in settings.json
- **cc Command**: Replaced simple alias with smart function that:
  - Checks for `.claude/system-prompt.md` in current directory
  - Auto-creates from `/workspaces/.devcontainer/config/main-system-prompt.md` if missing
  - Enables per-project system prompt customization

### Removed
- **Specwright**: Completely removed (setup script, aliases, plugin files, ORCHESTRATOR.md)

### Files Modified
- `/workspaces/.devcontainer/devcontainer.json` - Added GitHub CLI feature
- `/workspaces/.devcontainer/config/settings.json` - Set defaultMode to plan
- `/workspaces/.devcontainer/scripts/setup-aliases.sh` - Replaced cc alias with function
- `/workspaces/.devcontainer/.env` - Removed specwright, added plugins
- `/workspaces/.devcontainer/scripts/setup.sh` - Removed specwright, added setup-plugins.sh

### Files Deleted
- `/workspaces/.devcontainer/scripts/setup-specwright.sh`
- `/workspaces/.claude/ORCHESTRATOR.md`
- `/workspaces/.claude/plugins/marketplaces/specwright-marketplace/`
- `/workspaces/.claude/plugins/cache/specwright-marketplace/`

### Files Created
- `/workspaces/.devcontainer/scripts/setup-plugins.sh` - Plugin installer script
- `/workspaces/.devcontainer/CHANGELOG.md` - This changelog
