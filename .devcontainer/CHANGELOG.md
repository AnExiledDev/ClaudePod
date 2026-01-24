# ClaudePod Devcontainer Changelog

## [v1.3.1] - 2025-01-24

### Fixed

- **Plugin installation**: Fixed invalid plugin.json schema causing installation failures
  - Removed `$schema`, `category`, `version`, `lspServers` keys from individual plugin.json files
  - These fields now correctly reside only in `marketplace.json`
- **setup-plugins.sh**: Fixed path resolution for marketplace discovery
  - Changed from `${containerWorkspaceFolder:-.}` to `SCRIPT_DIR` relative path
  - Script now works correctly regardless of working directory

### Changed

- **Consolidated LSP setup**: Merged `setup-lsp.sh` into `setup-plugins.sh`
  - Single script now handles both official and local marketplace plugins
  - Removed `SETUP_LSP` environment variable (no longer needed)
- **settings.json**: Updated Claude Code configuration
  - Increased `MAX_THINKING_TOKENS` from 14999 to 63999
  - Added `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`: 80 (auto-compact at 80% context)
  - Added `CLAUDE_CODE_SHELL`: zsh
  - Added `FORCE_AUTOUPDATE_PLUGINS`: true
  - Added `autoUpdatesChannel`: "latest"

### Removed

- **setup-lsp.sh**: Deleted (functionality consolidated into setup-plugins.sh)

---

## [v1.3.0] - 2025-01-24

### Added

#### Code Quality Hooks
- **dangerous-command-blocker**: PreToolUse hook blocks dangerous bash commands
  - Blocks `rm -rf /`, `rm -rf ~`, `sudo rm`, `chmod 777`
  - Blocks `git push --force` to main/master
  - Blocks writes to system directories (`/usr`, `/etc`, `/bin`)
  - Blocks disk formatting (`mkfs.*`, `dd of=/dev/`)
- **protected-files-guard**: PreToolUse hook blocks modifications to sensitive files
  - Blocks `.env`, `.env.*` environment files
  - Blocks `.git/` directory
  - Blocks lock files (`package-lock.json`, `yarn.lock`, `poetry.lock`, etc.)
  - Blocks certificates/keys (`.pem`, `.key`, `.crt`)
  - Blocks credential files and auth directories (`.ssh/`, `.aws/`)
- **auto-formatter**: PostToolUse hook auto-formats edited files
  - Python files via Black (`/usr/local/py-utils/bin/black`)
  - Go files via gofmt (`/usr/local/go/bin/gofmt`)
- **auto-linter**: PostToolUse hook auto-lints edited files
  - Python files via Pyright with JSON output parsing
- **planning-reminder**: PreToolUse hook encourages plan-before-implement workflow

#### Features
- **notify-hook feature**: Desktop notifications when Claude finishes responding
  - OSC escape sequences for terminal notification support
  - Optional audio bell
  - VS Code extension recommendation for terminal notifications
- **agent-browser feature**: Headless browser automation CLI for AI agents
  - Accessibility tree snapshots for AI navigation
  - Screenshots and PDF capture
  - Element interaction and cookie management
- **Go LSP (gopls)**: Full Go language server support
  - Added `gopls` to claudepod-lsp plugin configuration
  - Added `goplsVersion` option to lsp-servers feature
  - Supports `.go`, `.mod`, `.sum` file extensions
- **Go language**: Added `ghcr.io/devcontainers/features/go:1` feature

#### Plugins
- **ticket-workflow plugin**: EARS-based ticket workflow with GitHub integration
  - `/ticket:new` - Transform requirements into EARS-formatted GitHub issues
  - `/ticket:work` - Create technical implementation plans from tickets
  - `/ticket:review-commit` - Thorough code review with requirements verification
  - `/ticket:create-pr` - Create PRs with aggressive security/architecture review
- **notify-hook plugin**: Claude Code hook integration for completion notifications
- **claudepod-lsp plugin.json**: Proper plugin structure for LSP servers

#### Commands & Aliases
- **ccraw alias**: Runs vanilla Claude Code without any config
  - Bypasses the function override via `command claude`
  - Useful for debugging or running without custom system prompt

#### Documentation
- **System prompt**: Added `<tools_reference>` section with all available tools
- **System prompt**: Added `<browser_automation>` section with usage guidance

### Changed

- **claude command**: Now behaves the same as `cc` (auto-creates local config)
  - Uses `command claude` internally to call the actual binary
  - Both `claude` and `cc` auto-setup `.claude/system-prompt.md` and `.claude/settings.json`
- **Container name**: Now includes project folder name for multi-project clarity
  - Format: `ClaudePod - ${localWorkspaceFolderBasename}`
- **setup-lsp.sh**: Replaced hard-coded plugin list with dynamic discovery
  - Now reads all plugins from `marketplace.json` using `jq`
  - Automatically installs new plugins when added to marketplace
- **System prompt**: Updated to use correct Claude Code tool names
  - Fixed plan mode references: `PlanMode` → `EnterPlanMode` / `ExitPlanMode`
  - Added explicit tool names throughout directives
- **Plugin installation**: Reduced from 7 plugins to 1 official plugin (frontend-design skill)

### Removed

- `code-review@claude-plugins-official` (command plugin)
- `commit-commands@claude-plugins-official` (command plugin)
- `pr-review-toolkit@claude-plugins-official` (command + agent plugin)
- `code-simplifier` npx installation block

### Files Created

```
.devcontainer/
├── features/
│   ├── agent-browser/
│   │   ├── devcontainer-feature.json
│   │   ├── install.sh
│   │   └── README.md
│   └── notify-hook/
│       ├── devcontainer-feature.json
│       ├── install.sh
│       └── README.md
└── plugins/devs-marketplace/plugins/
    ├── auto-formatter/
    │   ├── .claude-plugin/plugin.json
    │   ├── hooks/hooks.json
    │   └── scripts/format-file.py
    ├── auto-linter/
    │   ├── .claude-plugin/plugin.json
    │   ├── hooks/hooks.json
    │   └── scripts/lint-file.py
    ├── claudepod-lsp/
    │   └── .claude-plugin/plugin.json
    ├── dangerous-command-blocker/
    │   ├── .claude-plugin/plugin.json
    │   ├── hooks/hooks.json
    │   └── scripts/block-dangerous.py
    ├── notify-hook/
    │   ├── .claude-plugin/plugin.json
    │   └── hooks/hooks.json
    ├── planning-reminder/
    │   ├── .claude-plugin/plugin.json
    │   └── hooks/hooks.json
    ├── protected-files-guard/
    │   ├── .claude-plugin/plugin.json
    │   ├── hooks/hooks.json
    │   └── scripts/guard-protected.py
    └── ticket-workflow/
        └── .claude-plugin/
            ├── plugin.json
            ├── system-prompt.md
            └── commands/
                ├── ticket:new.md
                ├── ticket:work.md
                ├── ticket:review-commit.md
                └── ticket:create-pr.md
```

### Files Modified

- `.devcontainer/devcontainer.json` - Added features, VS Code settings, dynamic name
- `.devcontainer/config/main-system-prompt.md` - Tools reference, browser automation
- `.devcontainer/scripts/setup-aliases.sh` - Claude function override, ccraw alias
- `.devcontainer/scripts/setup-lsp.sh` - Dynamic plugin discovery
- `.devcontainer/scripts/setup-plugins.sh` - Trimmed to frontend-design only
- `.devcontainer/features/lsp-servers/install.sh` - Added gopls installation
- `.devcontainer/features/lsp-servers/devcontainer-feature.json` - Added goplsVersion
- `.devcontainer/plugins/devs-marketplace/.claude-plugin/marketplace.json` - All new plugins
- `.devcontainer/CLAUDE.md` - Updated plugin docs, local marketplace section
- `.devcontainer/README.md` - Added agent-browser, Go to tools tables

---

## [v1.2.3] - 2025-01-19

### Changed
- Added `--force` flag support
- Removed devpod references

---

## [v1.2.0] - 2025-01-19

### Added
- **GitHub CLI**: Added `ghcr.io/devcontainers/features/github-cli:1` feature
- **Official Anthropic Plugins**: New `setup-plugins.sh` script
- **SETUP_PLUGINS** environment variable
- **GitHub CLI Credential Persistence**: `GH_CONFIG_DIR=/workspaces/.gh`
- **README.md**: Comprehensive documentation
- **CLAUDE.md**: Development guide for Claude Code

### Changed
- **Plan Mode Default**: Changed `defaultMode` from `"dontAsk"` to `"plan"`
- **cc Command**: Replaced simple alias with smart function

### Removed
- **Specwright**: Completely removed (setup script, aliases, plugin files, ORCHESTRATOR.md)
