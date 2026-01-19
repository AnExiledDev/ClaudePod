# Claude Code CLI

**Installs Claude Code CLI for AI-powered coding assistance in your DevContainer**

This DevContainer feature provides a streamlined way to install Claude Code CLI with support for both native binary installation (recommended) and npm-based installation methods.

## Features

- ✅ **Dual Installation Methods**: Native binary (default) or npm
- ✅ **SHA256 Checksum Verification**: Native method verifies binary integrity
- ✅ **Version Selection**: Install latest or specific version
- ✅ **Platform Auto-Detection**: Supports x64/arm64, glibc/musl
- ✅ **Idempotent**: Safe to run multiple times
- ✅ **Multi-user Support**: NPM method supports user-specific installs
- ✅ **Minimal Dependencies**: Native method only requires jq and curl

## Quick Start

### Recommended: Native Installation

The native method is recommended as it has minimal dependencies and includes SHA256 checksum verification.

```json
{
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/yourorg/features/claude-code:1": {}
  }
}
```

### NPM Installation

For Node.js projects or when you prefer npm package management:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "nvmInstallPath": "/usr/local/share/nvm"
    },
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/yourorg/features/claude-code:1": {
      "installMethod": "npm"
    }
  }
}
```

### Specific Version

Install a specific version of Claude Code:

```json
{
  "features": {
    "ghcr.io/yourorg/features/claude-code:1": {
      "version": "2.0.42"
    }
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `installMethod` | string | `"native"` | Installation method: `"npm"` or `"native"` |
| `version` | string | `"latest"` | Claude Code version (e.g., `"2.0.42"` or `"latest"`) |
| `username` | string | `"automatic"` | Container user to install for (npm method only; native installs globally) |

### installMethod

Determines how Claude Code CLI is installed:

- **`native`** (default): Downloads pre-built binary from official distribution
  - No Node.js dependency required
  - SHA256 checksum verification
  - Installs globally to `/usr/local/bin/claude`
  - Smaller installation footprint

- **`npm`**: Installs via npm package manager
  - Requires Node.js feature
  - Installs to `~/.npm-global/bin/claude`
  - User-specific installation
  - Familiar to Node.js developers

### version

Specifies which version of Claude Code to install:

- **`latest`** (default): Automatically fetches and installs the current stable version
- **Specific version** (e.g., `"2.0.42"`): Installs the exact version specified

### username

Only applies to npm installation method:

- **`automatic`** (default): Auto-detects container user (vscode, node, codespace, or root)
- **Specific username**: Installs for the specified user
- **Native method**: This option is ignored as native installation is global

## Installation Methods Comparison

| Feature | Native | NPM |
|---------|--------|-----|
| **Speed** | ⚡⚡⚡ Fast download | ⚡⚡ Slower (npm overhead) |
| **Size** | ~200MB binary | ~200MB+ (with npm deps) |
| **Dependencies** | jq, curl, sha256sum | Node.js + npm + NVM + jq |
| **Install Location** | `/usr/local/bin/claude` (global) | `~/.npm-global/bin/claude` (user) |
| **Checksum Verification** | ✅ SHA256 verified | ❌ Via npm only |
| **Updates** | Manual or via feature | `npm update -g` |
| **Recommended** | ✅ Yes | For Node.js projects |

## Supported Platforms

The native installation method supports the following platforms:

| Platform | Architecture | C Library | Status |
|----------|--------------|-----------|--------|
| `linux-x64` | x86_64 | glibc | ✅ Fully supported |
| `linux-arm64` | ARM64/aarch64 | glibc | ✅ Fully supported |
| `linux-x64-musl` | x86_64 | musl | ✅ Alpine Linux |
| `linux-arm64-musl` | ARM64/aarch64 | musl | ✅ Alpine Linux |

The feature automatically detects your platform and downloads the appropriate binary.

## Dependencies

### Native Method

- `jq` - JSON parsing (provided by common-utils feature)
- `curl` - Downloading binaries
- `sha256sum` - Checksum verification

### NPM Method

- `jq` - JSON parsing (provided by common-utils feature)
- Node.js 18+ (provided by node feature)
- npm (included with Node.js)
- NVM at `/usr/local/share/nvm/nvm.sh`

## Usage Examples

### Basic Native Installation

```json
{
  "name": "My Dev Container",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/yourorg/features/claude-code:1": {}
  }
}
```

### NPM Installation with Specific User

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "20",
      "nvmInstallPath": "/usr/local/share/nvm"
    },
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/yourorg/features/claude-code:1": {
      "installMethod": "npm",
      "username": "vscode"
    }
  }
}
```

### Pinned Version Installation

```json
{
  "features": {
    "ghcr.io/yourorg/features/claude-code:1": {
      "installMethod": "native",
      "version": "2.0.42"
    }
  }
}
```

### Complete Example with Multiple Features

```json
{
  "name": "Full Stack Dev Container",
  "image": "mcr.microsoft.com/devcontainers/typescript-node:20",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {
      "installZsh": true,
      "username": "vscode"
    },
    "ghcr.io/devcontainers/features/node:1": {
      "version": "20",
      "nvmInstallPath": "/usr/local/share/nvm"
    },
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/yourorg/features/claude-code:1": {
      "installMethod": "native",
      "version": "latest"
    }
  }
}
```

## Post-Installation

After the container is built, you can verify the installation:

```bash
# Check version
claude --version

# Authenticate with Claude
claude auth login

# Start using Claude Code
claude
```

## Troubleshooting

### Native Installation Issues

#### "Failed to fetch latest version"

**Cause**: Network issue or GCS bucket unavailable

**Solution**:
- Check internet connectivity
- Retry the build
- Use a specific version instead of "latest"

```json
{
  "features": {
    "ghcr.io/yourorg/features/claude-code:1": {
      "version": "2.0.42"
    }
  }
}
```

#### "Checksum verification failed"

**Cause**: Corrupted download or network interference (proxy, firewall)

**Solution**:
- Retry the build
- Check network proxy settings
- Ensure no man-in-the-middle SSL inspection

#### "Platform not found in manifest"

**Cause**: Unsupported architecture or the specified version doesn't support your platform

**Solution**:
- Use a different version
- Switch to npm method
- Use a different base image

#### "Unsupported architecture"

**Cause**: Running on a non-x64/arm64 architecture

**Solution**:
- Use npm method instead
- Use a different base image (e.g., arm64 or x86_64)

### NPM Installation Issues

#### "npm not available"

**Cause**: Node feature not installed

**Solution**: Add the node feature before claude-code:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "nvmInstallPath": "/usr/local/share/nvm"
    },
    "ghcr.io/yourorg/features/claude-code:1": {
      "installMethod": "npm"
    }
  }
}
```

#### "NVM not found"

**Cause**: Node feature installed without correct nvmInstallPath

**Solution**: Ensure the node feature has the correct nvmInstallPath:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "nvmInstallPath": "/usr/local/share/nvm"
    }
  }
}
```

#### "Installation failed - claude command not found"

**Cause**: npm install succeeded but binary not in expected location

**Solution**:
- Check that `~/.npm-global/bin` exists
- Verify npm prefix configuration
- Check installation logs for errors

### General Issues

#### "jq not available"

**Cause**: common-utils feature not installed

**Solution**: Add common-utils feature:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/yourorg/features/claude-code:1": {}
  }
}
```

#### "command not found: claude" after installation

**Native method**: The command should work immediately as it's installed globally. If not:
- Verify `/usr/local/bin` is in your PATH
- Check that `/usr/local/bin/claude` exists and is executable

**NPM method**: You may need to reload your shell:
```bash
# Reload bash
source ~/.bashrc

# Or reload zsh
source ~/.zshrc

# Or start a new shell
exec bash
```

## Migration from Module-based Installation

If you're migrating from the old module-based installation, here are the key changes:

### Breaking Changes

1. **No settings.json management**
   - **Old**: Copied from `configurations/cc/settings.json`
   - **New**: Not handled by this feature
   - **Action**: Manage `~/.claude/settings.json` manually or via separate feature

2. **No system prompt handling**
   - **Old**: Created shell alias with `--system-prompt` flag
   - **New**: Not handled by this feature
   - **Action**: Configure manually if needed

3. **No shell alias creation**
   - **Old**: Created `alias claude=...`
   - **New**: Plain `claude` command only
   - **Action**: Create aliases manually if needed

4. **No MCP server injection**
   - **Old**: Injected Qdrant MCP config
   - **New**: Removed (mcp-qdrant feature handles this)
   - **Action**: Use dedicated MCP server features

5. **Install method selection**
   - **Old**: Always npm
   - **New**: Native by default, npm optional
   - **Action**: Set `installMethod: "npm"` if you need npm method

### Migration Example

**Old (module-based):**
```bash
# In postStartCommand.sh
source "$modules_path/claude_code/cc_install.sh"
source "$modules_path/claude_code/options/copy_local_settings.sh"
source "$modules_path/claude_code/cc_alias.sh"
```

**New (feature-based):**
```json
{
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/yourorg/features/claude-code:1": {}
  }
}
```

For NPM compatibility:
```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "nvmInstallPath": "/usr/local/share/nvm"
    },
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "ghcr.io/yourorg/features/claude-code:1": {
      "installMethod": "npm"
    }
  }
}
```

## Security

### Checksum Verification

The native installation method verifies SHA256 checksums for all downloaded binaries:

1. Fetches manifest.json containing expected checksums
2. Downloads the binary
3. Computes actual SHA256 checksum
4. Compares against expected value
5. Fails installation if mismatch detected

This ensures the binary hasn't been corrupted or tampered with during download.

### Official Distribution

All native binaries are downloaded from the official Claude Code distribution:

```
https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases
```

## Technical Details

### Version Resolution

When `version: "latest"` is specified, the feature:

1. Fetches the stable version from: `${BASE_URL}/stable`
2. Receives a plain text version number (e.g., "2.0.42")
3. Uses that version for manifest and binary URLs

### Platform Detection

The feature automatically detects your platform:

1. **Architecture**: Uses `uname -m` to detect x86_64 or arm64/aarch64
2. **C Library**: Uses `ldd --version` to detect musl (Alpine) vs glibc
3. **Platform String**: Combines to form platform identifier (e.g., "linux-x64-musl")

### Installation Paths

**Native method**:
- Binary: `/usr/local/bin/claude`
- Available globally to all users
- No PATH configuration needed

**NPM method**:
- Binary: `/home/{username}/.npm-global/bin/claude`
- User-specific installation
- PATH configured in `~/.bashrc` and `~/.zshrc`

### Idempotency

The feature is idempotent and handles re-runs gracefully:

- Checks if `claude` command already exists
- Compares installed version with requested version
- Skips installation if already present (for "latest")
- Skips installation if requested version already installed
- Proceeds with installation if different version requested

## Contributing

Issues and pull requests are welcome! Please follow the DevContainer Feature development guidelines.

## License

[Your License Here]

## See Also

- [Claude Code Documentation](https://claude.ai/docs)
- [DevContainer Features Specification](https://containers.dev/implementors/features/)
- [Common DevContainer Features](https://github.com/devcontainers/features)
