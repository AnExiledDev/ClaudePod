# Splitrail Token Usage Tracker Feature

A DevContainer Feature that installs Splitrail - a real-time AI token usage tracker and cost monitor for AI coding agents.

## Quick Start

```json
{
  "features": {
    "ghcr.io/devcontainers/features/rust:1": {},
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "./features/splitrail": {}
  }
}
```

**Note:** This feature requires Rust and common-utils features to be installed first.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `repoUrl` | string | `https://github.com/Piebald-AI/splitrail.git` | Git repository URL |
| `branch` | string | `main` | Git branch to checkout |
| `username` | string | `automatic` | User to install for (auto-detects: vscode, node, codespace, or root) |

## What This Feature Installs

- **splitrail**: Compiled from source (Rust)
- **Binary Location**: `/home/{username}/.cargo/bin/splitrail`
- **Compile Time**: 2-3 minutes on first build
- **Disk Usage**: ~50MB source + build artifacts

## Requirements

This feature has explicit dependencies that **must** be installed first:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/rust:1": {},
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "./features/splitrail": {}
  }
}
```

**Required by this feature:**
- **Rust + Cargo**: For compiling splitrail from source
- **Git**: For cloning the repository

The feature will validate these are present and exit with an error if missing.

## Features

- ✅ **Real-time Tracking**: Monitor token usage as you code
- ✅ **Cost Monitoring**: Track costs for different AI models
- ✅ **Multi-agent Support**: Supports Claude Code, Gemini, Codex
- ✅ **Cloud Upload**: Optional private cloud aggregation across machines
- ✅ **Fast Performance**: Written in Rust for minimal overhead
- ✅ **Idempotent**: Safe to run multiple times
- ✅ **Multi-user**: Automatically detects container user

## Usage

### Start Monitoring

```bash
splitrail
```

### Check Version

```bash
splitrail --version
```

### View Help

```bash
splitrail --help
```

## Architecture

```
AI Agent (Claude Code, etc.)
    ↓
Splitrail monitors usage
    ↓
Real-time display + optional cloud upload
```

## Troubleshooting

### Compilation Fails

**Cause:** Rust/Cargo not available

**Solution:** Ensure Rust feature is installed first:
```json
{
  "features": {
    "ghcr.io/devcontainers/features/rust:1": {},
    "./features/splitrail": {}
  }
}
```

### Binary Not Found

**Symptom:** `splitrail: command not found`

**Solution:** Check the binary location:
```bash
ls -la /home/node/.cargo/bin/splitrail
# Should exist

# Verify PATH includes cargo bin
echo $PATH | grep cargo
```

### Build Errors

**Symptom:** Cargo build fails during compilation

**Checks:**
- Verify Rust version: `rustc --version`
- Check cargo: `cargo --version`
- Review build output for specific errors
- Try cleaning: `cd ~/splitrail && cargo clean && cargo build --release`

## Resources

- [Splitrail GitHub](https://github.com/Piebald-AI/splitrail)
- [Rust Language](https://www.rust-lang.org/)

## License

MIT License - See repository for details.
