# MCP Reasoner Server Feature

A DevContainer Feature that installs and configures the MCP Reasoner server for enhanced AI reasoning capabilities.

## Quick Start

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "./features/mcp-reasoner": {}
  }
}
```

**Note:** This feature requires Node.js and common-utils features to be installed first.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `username` | string | `automatic` | User to install for (auto-detects: vscode, node, codespace, or root) |

## What This Feature Installs

- **mcp-reasoner**: Cloned from GitHub and built locally
- **Native MCP Support**: Uses devcontainer native `mcpServers` configuration (declarative)
- **Install Location**: `/home/{username}/mcp-reasoner`

## Requirements

This feature has explicit dependencies that **must** be installed first:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "./features/mcp-reasoner": {}
  }
}
```

**Required by this feature:**
- **Node.js + npm**: For building mcp-reasoner
- **jq**: For safe JSON generation (from common-utils)

The feature will validate these are present and exit with an error if missing.

## Features

- ✅ **Automatic Installation**: Clones and builds mcp-reasoner
- ✅ **Idempotent**: Safe to run multiple times
- ✅ **Multi-user**: Automatically detects container user
- ✅ **Native DevContainer Support**: Uses native `mcpServers` configuration for declarative setup

## Configuration

### Native DevContainer MCP Support

This feature uses the native devcontainer `mcpServers` configuration pattern, which means the MCP server is declared in the `devcontainer.json` settings automatically. The configuration is applied when the devcontainer is created:

```json
{
  "customizations": {
    "vscode": {
      "settings": {
        "mcp": {
          "servers": {
            "reasoner": {
              "type": "stdio",
              "command": "node",
              "args": ["${userHome}/mcp-reasoner/dist/index.js"]
            }
          }
        }
      }
    }
  }
}
```

**No manual steps required!** The MCP server is automatically available to your AI agent once the devcontainer starts.

### Verify It Worked

**1. Start your AI agent** (Claude Code or other MCP-compatible agent)

**2. Verify the server is available:**

Ask your AI agent:
```
"Show me what MCP servers you have available"
```

You should see `reasoner` listed among the available MCP servers.

**3. Test directly (optional):**
```bash
node ~/mcp-reasoner/dist/index.js
```

## Usage with AI Agents

### Claude Code

The MCP Reasoner server provides enhanced reasoning capabilities for your AI agent.

## Architecture

```
AI Agent (Claude Code, etc.)
    ↓
Model Context Protocol
    ↓
mcp-reasoner (Node.js)
    ↓
Reasoning capabilities
```

## Troubleshooting

### Server Not Appearing in AI Agent

**Symptom:** Installation succeeds but agent doesn't see MCP Reasoner server

**Solution:**
1. Ensure the devcontainer is running the latest image (rebuild if needed)
2. Restart your AI agent to reload MCP server configurations
3. Check that the dist file exists: `ls -la ~/mcp-reasoner/dist/index.js`

### Installation Fails: "node is not available"

**Cause:** Node feature not installed first

**Solution:** Add Node feature before mcp-reasoner:
```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {},
    "./features/mcp-reasoner": {}
  }
}
```

### Installation Fails: "jq is not available"

**Cause:** common-utils feature not installed

**Solution:** Add common-utils feature:
```json
{
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {},
    "./features/mcp-reasoner": {}
  }
}
```

### Build Fails

**Symptom:** npm build errors during installation

**Checks:**
- Verify Node.js version is compatible: `node --version`
- Check npm is available: `npm --version`
- Review build output for specific errors

## Resources

- [MCP Reasoner GitHub](https://github.com/Jacck/mcp-reasoner)
- [Model Context Protocol](https://modelcontextprotocol.io)

## License

MIT License - See repository for details.
