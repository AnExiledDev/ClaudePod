# Claude MCP Server Configuration Examples

This file contains examples of additional MCP servers you can add to your ClaudePod environment.

## API-Dependent MCP Servers

### Environment Variables Setup
Add these to your `devcontainer.json`:

```json
{
  "containerEnv": {
    "TAVILY_API_KEY": "${localEnv:TAVILY_API_KEY}",
    "GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN}",
    "GOOGLE_MAPS_API_KEY": "${localEnv:GOOGLE_MAPS_API_KEY}"
  }
}
```

Then set the environment variables on your host machine:
```bash
export TAVILY_API_KEY="your_tavily_api_key"
export GITHUB_TOKEN="your_github_token" 
export GOOGLE_MAPS_API_KEY="your_google_maps_key"
```

## Additional MCP Server Examples

### Search Capabilities
```bash
# Tavily Search (requires API key)
claude mcp add tavily-search --env TAVILY_API_KEY=$TAVILY_API_KEY -- npx @tavily/mcp-server

# Brave Search (requires API key) 
claude mcp add brave-search --env BRAVE_SEARCH_API_KEY=$BRAVE_SEARCH_API_KEY -- npx @brave/mcp-server
```

### Database Access
```bash
# SQLite MCP server
claude mcp add sqlite -- npx @modelcontextprotocol/server-sqlite /workspace/database.db

# PostgreSQL MCP server
claude mcp add postgres --env DATABASE_URL=$DATABASE_URL -- npx @modelcontextprotocol/server-postgres
```

### Development Tools
```bash
# Puppeteer automation
claude mcp add puppeteer -- npx @modelcontextprotocol/server-puppeteer

# Docker MCP server
claude mcp add docker -- npx @modelcontextprotocol/server-docker

# Kubernetes MCP server  
claude mcp add kubernetes -- npx @modelcontextprotocol/server-kubernetes
```

### Cloud Services
```bash
# AWS MCP server
claude mcp add aws --env AWS_REGION=us-east-1 -- npx @modelcontextprotocol/server-aws

# Azure MCP server
claude mcp add azure -- npx @modelcontextprotocol/server-azure

# Google Cloud MCP server
claude mcp add gcp -- npx @modelcontextprotocol/server-gcp
```

## Custom MCP Server Development

### Local Development Server
```bash
# Run your own MCP server
claude mcp add my-server -- node /workspace/my-mcp-server/index.js

# Python MCP server
claude mcp add python-server -- python /workspace/my_mcp_server.py

# HTTP MCP server
claude mcp add --transport http my-http-server http://localhost:8000/mcp
```

### MCP Server Template Structure
```
my-mcp-server/
├── package.json
├── index.js          # Main server implementation
├── tools/             # Tool definitions
│   ├── file-ops.js
│   └── api-calls.js
└── resources/         # Resource definitions
    └── data.js
```

## Managing MCP Servers

### Common Commands
```bash
# List all configured servers
claude mcp list

# Remove a server
claude mcp remove server-name

# Test server connectivity  
claude mcp test server-name

# Restart a server
claude mcp restart server-name

# View server logs
claude mcp logs server-name
```

### Troubleshooting MCP Servers

**Server fails to start:**
1. Check command syntax: `claude mcp add name -- command`
2. Verify all dependencies are installed
3. Check environment variables are set
4. Review server logs

**Connection issues:**
1. Ensure server process is running
2. Check network connectivity for HTTP servers
3. Verify API keys and authentication
4. Test with minimal configuration

**Performance issues:**
1. Monitor server resource usage
2. Check for memory leaks in custom servers
3. Optimize tool and resource implementations
4. Consider server restart schedules

## Best Practices

### Security
- Store API keys in environment variables, not in code
- Use minimal required permissions for API tokens
- Regularly rotate API keys
- Audit MCP server access to sensitive data

### Performance  
- Only install MCP servers you actively use
- Use HTTP transport for remote servers when possible
- Implement proper caching in custom servers
- Monitor server startup times

### Development
- Test MCP servers in isolation before adding to Claude
- Use TypeScript for better type safety in custom servers
- Implement proper error handling and logging
- Document your custom MCP server APIs

## Resources

- [MCP Specification](https://spec.modelcontextprotocol.io/)
- [MCP Server Examples](https://github.com/modelcontextprotocol/servers)
- [Claude Code MCP Documentation](https://docs.anthropic.com/en/docs/claude-code/mcp)