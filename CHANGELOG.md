# ClaudePod Changelog

## Version 1.0.0

### 🚀 Core Features

#### Development Environment
- **Base**: Ubuntu 22.04 with optimized DevContainer configuration
- **Development Stack**: Node.js 20, Python 3.13, Git, GitHub CLI
- **User Configuration**: `node` user for proper permissions and compatibility
- **Persistent Storage**: Claude config, shell history, and npm cache survive container rebuilds

#### Claude Code Integration
- **Claude Code CLI**: Pre-installed with optimized tool configuration
- **Tool Optimization**: 79 essential tools pre-allowed (51% reduction from 161 total)
- **Zero Permission Prompts**: Streamlined workflow for common development tasks
- **Smart Tool Selection**: Prioritizes powerful MCP tools over basic built-ins

#### MCP Server Ecosystem
**Pre-installed (no API keys required):**
- **Serena** (20 tools) - Advanced code analysis and semantic search
- **DeepWiki** (3 tools) - GitHub repository documentation search
- **TaskMaster AI** (39 tools) - AI-powered project management and autonomous development
- **Sequential Thinking** - Structured problem-solving framework
- **ccusage** - Claude Code usage analytics and cost tracking

**Available with API keys:**
- **GitHub MCP** (80 tools) - Complete GitHub API integration
- **Tavily Search** (4 tools) - Web search and content extraction
- **Ref.Tools** - Documentation and API reference tools

#### Development Tools
- **git-delta**: Enhanced git diffs with syntax highlighting and side-by-side view
- **Shell Aliases**: Git shortcuts (`gs`, `gd`, `gc`, `gp`, `gl`) for faster workflow
- **uv/uvx**: Fast Python package management
- **VS Code Extensions**: Pre-configured extensions for remote development

### 🔧 Architecture

#### Container Design
- **DevContainer Features**: Leverages official features for reliable, cached builds
- **Two-phase Setup**: Post-create installs tools, post-start configures MCP servers
- **User Permissions**: Proper `node` user setup with sudo access
- **Network Configuration**: Host network mode for optimal development server performance

#### Reliability Features
- **Graceful Degradation**: Container functions even if optional components fail
- **Retry Logic**: Automatic retry for network-dependent operations
- **Health Checks**: Built-in verification scripts for troubleshooting
- **Error Recovery**: Clear error messages and recovery procedures

### 🔒 Security & Best Practices
- **Non-root User**: All operations run as `node` user for security
- **Environment Variables**: API keys handled securely via environment variables
- **Volume Isolation**: Proper permissions and isolated storage
- **Clean Images**: No secrets or credentials baked into container images

### 📋 Requirements
- **DevPod**: Container orchestration and deployment
- **VS Code**: With Remote Development Extension Pack for IDE integration
- **Docker**: Required by DevPod for container operations

### 🏗️ Installation
```bash
# Install in any project
npx claudepod-devcontainer

# Start container
devpod up .

# Connect with VS Code
devpod ssh <workspace-name> --ide vscode
```

### 🔑 Optional API Keys
- `GITHUB_PERSONAL_ACCESS_TOKEN` - For GitHub MCP integration
- `TAVILY_API_KEY` - For web search capabilities
- `REF_TOOLS_API_KEY` - For documentation tools

### 🤝 Contributing
The container is designed for maximum compatibility and ease of use. Future updates will maintain backward compatibility with:
- Persistent volume data (Claude config, shell history)
- Core container interface (workspace mounting, user permissions)  
- MCP server configurations