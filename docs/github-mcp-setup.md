# GitHub MCP Server Setup Guide

This guide explains how to set up the GitHub MCP Server in your ClaudePod development container for AI-powered GitHub integration.

## Overview

The GitHub MCP Server enables Claude Code to directly interact with GitHub repositories, providing capabilities for:

- Repository and file access
- Issue management and automation
- Pull request operations
- GitHub Actions integration
- Code security analysis
- Dependency management (Dependabot)
- GitHub Discussions

## Prerequisites

- ClaudePod development container running
- Docker available in the container
- GitHub Personal Access Token (PAT)
- Claude Code CLI installed

## Step 1: Create GitHub Personal Access Token

1. **Go to GitHub Settings**
   - Navigate to https://github.com/settings/tokens
   - Click "Generate new token (classic)"

2. **Configure Token Scopes**
   - **Minimum Required**: `repo`, `read:packages`
   - **Recommended Additional Scopes** (based on your needs):
     - `read:org` - For organization repositories
     - `read:user` - For user information
     - `read:project` - For GitHub Projects
     - `workflow` - For GitHub Actions (if needed)
     - `read:discussion` - For GitHub Discussions

3. **Generate and Copy Token**
   - Set appropriate expiration (recommend 90 days for security)
   - Click "Generate token"
   - **Important**: Copy the token immediately (you won't see it again)

## Step 2: Set Environment Variables

### Option A: Set in Current Session
```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"

# Optional configurations
export GITHUB_API_URL="https://api.github.com"  # Default GitHub.com API
export GITHUB_TOOLSET="context,issues,pull_requests,actions"  # Custom toolsets
```

### Option B: Add to DevContainer Configuration
Update your `devcontainer.json` with:
```json
{
  "containerEnv": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${localEnv:GITHUB_PERSONAL_ACCESS_TOKEN}",
    "GITHUB_API_URL": "${localEnv:GITHUB_API_URL}",
    "GITHUB_TOOLSET": "${localEnv:GITHUB_TOOLSET}"
  }
}
```

Then set the environment variables on your host machine:
```bash
# On your host machine (outside container)
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"
```

### Option C: Use .env File (Local Development)
Create a `.env` file in your project root:
```bash
# .env file (DO NOT COMMIT THIS FILE)
GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
GITHUB_TOOLSET=context,issues,pull_requests
```

Load it in your shell:
```bash
source .env
```

## Step 3: Install GitHub MCP Server

### Automatic Installation
Use the provided installation script:
```bash
/workspace/scripts/install-github-mcp.sh
```

### Manual Installation
```bash
# Ensure Docker is available
docker --version

# Install GitHub MCP server
claude mcp add github -- docker run --rm -i \
  -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
  ${GITHUB_API_URL:+-e GITHUB_API_URL="$GITHUB_API_URL"} \
  ${GITHUB_TOOLSET:+-e GITHUB_TOOLSET="$GITHUB_TOOLSET"} \
  ghcr.io/github/github-mcp-server:latest
```

### Verify Installation
```bash
# List all MCP servers
claude mcp list

# Should show 'github' in the list
```

## Step 4: Configure Toolsets (Optional)

GitHub MCP Server supports configurable toolsets to control API capabilities:

### Available Toolsets
- `context` - Repository and file access
- `actions` - GitHub Actions management  
- `code_security` - Security analysis tools
- `dependabot` - Dependency management
- `discussions` - GitHub Discussions
- `issues` - Issue management
- `pull_requests` - PR management
- `repository_management` - Repo settings and management

### Example Configurations
```bash
# Basic usage (repository access + issues)
export GITHUB_TOOLSET="context,issues"

# Full development workflow
export GITHUB_TOOLSET="context,issues,pull_requests,actions"

# Security-focused
export GITHUB_TOOLSET="context,code_security,dependabot"
```

## Step 5: Test the Integration

1. **Start Claude Code**
   ```bash
   claude
   ```

2. **Test Basic Commands**
   ```
   List my GitHub repositories
   Show the README of my main project repository
   Create a new issue in my repository called "test-repo"
   ```

3. **Verify Server Status**
   ```bash
   claude mcp list
   # Should show 'github' server as active
   ```

## Security Best Practices

### Token Management
- **Never commit tokens to version control**
- Use environment variables or secure secret management
- Set appropriate token expiration (90 days recommended)
- Rotate tokens regularly
- Use minimal necessary scopes

### Container Security
- Environment variables are isolated within the container
- Tokens are not persisted in container images
- Use Docker's security features (non-root user, read-only filesystems when possible)

### Access Control
- Review token scopes regularly
- Monitor token usage in GitHub settings
- Revoke unused or compromised tokens immediately
- Use separate tokens for different environments

## Troubleshooting

### Common Issues

#### "Authentication Failed"
```bash
# Check if token is set
echo $GITHUB_PERSONAL_ACCESS_TOKEN

# Verify token has correct scopes in GitHub settings
# Token should start with 'ghp_' for classic tokens
```

#### "Docker Not Found"
```bash
# Check Docker installation
docker --version

# If not available, Docker is required for GitHub MCP server
```

#### "Server Not Responding"
```bash
# Remove and reinstall server
claude mcp remove github
/workspace/scripts/install-github-mcp.sh
```

#### "Permission Denied"
- Check token scopes in GitHub settings
- Ensure token has access to the repository
- Verify organization permissions if using org repositories

### Debugging Commands
```bash
# Check MCP server logs
claude mcp logs github

# Test Docker command manually
docker run --rm -i \
  -e GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN" \
  ghcr.io/github/github-mcp-server:latest

# Verify network connectivity
curl -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" \
  https://api.github.com/user
```

## Advanced Configuration

### Custom GitHub Enterprise
```bash
export GITHUB_API_URL="https://github.example.com/api/v3"
export GITHUB_PERSONAL_ACCESS_TOKEN="your_enterprise_token"
```

### Multiple Repositories/Organizations
The server automatically has access to all repositories your token can access based on the scopes. No additional configuration needed.

### Integration with CI/CD
For automated environments, consider using:
- GitHub App authentication (more secure than PAT)
- Scoped tokens with minimal permissions
- Token rotation automation

## Usage Examples

Once installed, you can use Claude Code to:

```
# Repository operations
"Show me the file structure of my main repository"
"What are the recent commits in the develop branch?"
"Show me the GitHub Actions workflows in this repo"

# Issue management  
"Create a bug report issue for the login problem"
"List all open issues assigned to me"
"Close issue #123 with a comment"

# Pull request operations
"Create a PR from my feature branch to main"
"Review the changes in PR #45"
"Merge PR #67 after checks pass"

# Code analysis
"Analyze the security issues in this repository"
"Show me the Dependabot alerts"
"What are the code scanning results?"
```

## Next Steps

- Explore GitHub MCP server capabilities with Claude Code
- Set up automated workflows using the Actions toolset
- Configure organization-wide settings for team use
- Consider implementing GitHub App authentication for production use

## Support

- Check the [GitHub MCP Server repository](https://github.com/github/github-mcp-server) for updates
- Report issues or feature requests in the repository
- Consult GitHub API documentation for advanced usage patterns