# MCP Server Setup Commands

This document provides the correct `claude mcp add` commands for setting up MCP servers in the ClaudePod environment.

## Automatic Installation

Most MCP servers are automatically installed during container startup via the post-start script. However, you can manually add or remove servers as needed.

## GitHub MCP Server

The GitHub MCP Server is automatically installed during container startup if you have a `GITHUB_PERSONAL_ACCESS_TOKEN` configured.

### Manual Installation

```bash
# Ensure Docker image is available
docker pull ghcr.io/github/github-mcp-server:latest

# Add GitHub MCP server with basic configuration
claude mcp add github -- docker run --rm -i \
    -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
    ghcr.io/github/github-mcp-server:latest

# Add GitHub MCP server with custom API URL (for GitHub Enterprise)
claude mcp add github -- docker run --rm -i \
    -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
    -e GITHUB_API_URL="https://api.github.example.com" \
    ghcr.io/github/github-mcp-server:latest

# Add GitHub MCP server with custom toolset
claude mcp add github -- docker run --rm -i \
    -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
    -e GITHUB_TOOLSET="context,issues,pull_requests" \
    ghcr.io/github/github-mcp-server:latest

# Full configuration with all options
claude mcp add github -- docker run --rm -i \
    -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
    -e GITHUB_API_URL="$GITHUB_API_URL" \
    -e GITHUB_TOOLSET="$GITHUB_TOOLSET" \
    ghcr.io/github/github-mcp-server:latest
```

### Available GitHub Toolsets

- `context` - Repository and file access
- `actions` - GitHub Actions management  
- `code_security` - Security analysis tools
- `dependabot` - Dependency management
- `discussions` - GitHub Discussions
- `issues` - Issue management
- `pull_requests` - PR management

## Other MCP Servers

### Task Master AI
```bash
# Automatically installed - supports Claude Code without additional API keys
claude mcp add taskmaster-ai -- npx -y --package=task-master-ai task-master-ai
```

### Serena (Code Analysis)
```bash
# Automatically installed - provides semantic code search and analysis
claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant --project /workspace
```

### DeepWiki (Documentation Search)
```bash
# HTTP-based server - no API key required
claude mcp add --transport http deepwiki https://mcp.deepwiki.com/mcp
```

### Sequential Thinking (Progressive Thinking)
```bash
# Automatically installed - structured thinking and problem-solving
claude mcp add sequential-thinking -- uvx --from git+https://github.com/arben-adm/mcp-sequential-thinking.git mcp-sequential-thinking
```

### Tavily Search (Web Search)
```bash
# Requires TAVILY_API_KEY environment variable
claude mcp add --transport http tavily-search "https://mcp.tavily.com/mcp/?tavilyApiKey=$TAVILY_API_KEY"
```

### Ref.Tools (Reference Documentation)
```bash
# Requires REF_TOOLS_API_KEY environment variable
claude mcp add --transport http ref-tools "https://api.ref.tools/mcp?apiKey=$REF_TOOLS_API_KEY"
```

## MCP Server Management Commands

```bash
# List all configured MCP servers
claude mcp list

# Remove a specific server
claude mcp remove github
claude mcp remove taskmaster-ai
claude mcp remove serena
claude mcp remove sequential-thinking

# Test server connectivity
claude mcp test github
claude mcp test taskmaster-ai
claude mcp test sequential-thinking

# Remove all servers and start fresh
claude mcp remove --all
```

## Environment Variables

Make sure these environment variables are set in your `/workspace/.devcontainer/.env` file:

```bash
# Required for GitHub MCP Server
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here

# Optional GitHub configurations
GITHUB_API_URL=https://api.github.com  # Default
GITHUB_TOOLSET=context,issues,pull_requests  # Default: all

# Optional API keys for other servers
TAVILY_API_KEY=your_tavily_key_here
REF_TOOLS_API_KEY=your_ref_tools_key_here

# Task Master AI uses Claude Code's API key automatically
```

## Troubleshooting

### GitHub MCP Server Issues

1. **Docker not available**:
   ```bash
   # Check if Docker is running
   docker --version
   docker ps
   ```

2. **Invalid GitHub PAT**:
   ```bash
   # Validate your token
   bash /workspace/scripts/validate-github-env.sh
   ```

3. **Server not starting**:
   ```bash
   # Remove and re-add the server
   claude mcp remove github
   claude mcp add github -- docker run --rm -i \
       -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
       ghcr.io/github/github-mcp-server:latest
   ```

### General MCP Issues

1. **Server not responding**:
   ```bash
   # Check server status
   claude mcp list
   claude mcp test <server-name>
   ```

2. **Clear all servers and reinstall**:
   ```bash
   # Remove all servers
   claude mcp remove --all
   
   # Restart container to reinstall automatically
   # Or run manual installation commands above
   ```

3. **Check container logs**:
   ```bash
   # Docker container logs (if running)
   docker logs <container-id>
   ```

## Notes

- The post-start script automatically installs all MCP servers during container startup
- GitHub MCP Server requires Docker and a valid GitHub Personal Access Token
- All other servers work without additional dependencies
- MCP server configurations persist in Claude Code's configuration directory
- Use environment variables to configure API keys securely