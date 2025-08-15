# GitHub MCP Server Security Guide

This document outlines security best practices for managing GitHub Personal Access Tokens (PATs) and the GitHub MCP Server in the ClaudePod environment.

## Environment Variable Security

### GitHub Personal Access Token Storage

**✅ Secure Practices:**
- Store PATs in `/workspace/.devcontainer/.env` file (automatically git-ignored)
- Use environment variables in devcontainer configuration
- Never hardcode tokens in scripts or configuration files
- Use the provided validation script to test token functionality

**❌ Avoid These Practices:**
- Never commit tokens to version control
- Don't store tokens in plain text files that might be shared
- Avoid logging tokens in container output
- Don't expose tokens through environment variable dumps

### Token Scope Management

**Recommended Minimum Scopes:**
- `repo` - Repository access (read/write to repositories)
- `read:packages` - Package registry access

**Additional Useful Scopes:**
- `workflow` - GitHub Actions management
- `read:org` - Organization information access
- `security_events` - Security analysis features
- `read:project` - Project board access

**Security Principle:** Always use the minimum scopes required for your use case.

### Token Rotation

**Best Practices:**
- Rotate tokens periodically (quarterly recommended)
- Immediately revoke tokens if compromised
- Use separate tokens for different environments (dev/staging/prod)
- Monitor token usage through GitHub's audit logs

## Container Security

### Environment Variable Handling

The devcontainer configuration uses secure environment variable forwarding:

```json
"containerEnv": {
  "GITHUB_PERSONAL_ACCESS_TOKEN": "${localEnv:GITHUB_PERSONAL_ACCESS_TOKEN}",
  "GITHUB_API_URL": "${localEnv:GITHUB_API_URL}",
  "GITHUB_TOOLSET": "${localEnv:GITHUB_TOOLSET}"
}
```

This pattern:
- ✅ Forwards variables from host environment to container
- ✅ Doesn't store tokens in container configuration
- ✅ Allows per-developer token management

### Docker Security

**GitHub MCP Server Docker Configuration:**
- Uses official GitHub image: `ghcr.io/github/github-mcp-server:latest`
- Runs with `--rm` flag to remove containers after use
- Passes environment variables securely through `-e` flags
- No persistent volumes mounted (stateless operation)

**Security Benefits:**
- ✅ Official, maintained container image
- ✅ Ephemeral containers (no persistent token storage)
- ✅ Isolated process execution
- ✅ Minimal attack surface

### Network Security

**API Communication:**
- All GitHub API calls use HTTPS (encrypted in transit)
- Token authentication via HTTP Authorization header
- Support for GitHub Enterprise Server with custom API URLs
- Certificate validation enabled by default

## Token Validation and Monitoring

### Automated Validation

The provided validation script (`validate-github-env.sh`) performs:

1. **Format Validation**
   - Checks token format patterns (ghp_, github_pat_, etc.)
   - Validates token length requirements

2. **Connectivity Testing**
   - Tests GitHub API access
   - Verifies authentication success
   - Checks API response codes

3. **Scope Analysis**
   - Examines current token scopes
   - Provides scope recommendations
   - Identifies missing permissions

### Usage Monitoring

**GitHub's Built-in Features:**
- Personal Access Token activity logs
- Organization security audit logs  
- Repository access monitoring
- API rate limit tracking

**Monitoring Commands:**
```bash
# Check token scopes and usage
bash /workspace/scripts/validate-github-env.sh

# List configured MCP servers
claude mcp list

# Test MCP server connectivity
claude mcp test github
```

## Incident Response

### If Token is Compromised

**Immediate Actions:**
1. Revoke the token immediately at https://github.com/settings/tokens
2. Generate a new token with minimal required scopes
3. Update the `.env` file with the new token
4. Restart any running Claude Code sessions
5. Review audit logs for unauthorized access

**Recovery Steps:**
```bash
# Remove old token from environment
unset GITHUB_PERSONAL_ACCESS_TOKEN

# Update .env file with new token
vim /workspace/.devcontainer/.env

# Validate new token
bash /workspace/scripts/validate-github-env.sh

# Reinstall GitHub MCP server with new token
claude mcp remove github
bash /workspace/scripts/install-github-mcp.sh
```

### Container Compromise

**If Container is Compromised:**
1. Stop and remove the container immediately
2. Revoke all GitHub tokens used in the environment
3. Rebuild container from clean base image
4. Review all repository access logs
5. Generate new tokens before resuming work

## Compliance and Auditing

### Data Handling

**What GitHub MCP Server Accesses:**
- Repository metadata and content
- Issue and pull request data
- GitHub Actions workflow information
- Organization and team membership
- Package registry information

**Data Processing:**
- All data processing happens locally in the container
- No data is sent to third-party services (except GitHub)
- Temporary data stored only in container memory
- No persistent data storage outside of mounted volumes

### Audit Trail

**Logging Points:**
- Token validation results
- MCP server installation/removal
- GitHub API access attempts
- Authentication failures

**Log Locations:**
- Container stdout/stderr (ephemeral)
- Claude Code MCP server logs
- GitHub audit logs (persistent)

## Security Configuration Checklist

**Initial Setup:**
- [ ] Generate GitHub PAT with minimal scopes
- [ ] Store token in `.env` file (git-ignored)
- [ ] Run token validation script
- [ ] Test GitHub MCP server installation
- [ ] Verify MCP server connectivity

**Ongoing Security:**
- [ ] Rotate tokens quarterly
- [ ] Monitor GitHub audit logs monthly
- [ ] Review and update token scopes as needed
- [ ] Keep container base image updated
- [ ] Regular security validation script runs

**Before Sharing Environment:**
- [ ] Ensure `.env` is in `.gitignore`
- [ ] Remove any hardcoded tokens
- [ ] Verify no tokens in environment dumps
- [ ] Test with fresh container build

## Additional Resources

- [GitHub Personal Access Token Documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [GitHub Security Best Practices](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure)
- [GitHub MCP Server Documentation](https://github.com/github/github-mcp-server)
- [Container Security Best Practices](https://docs.docker.com/develop/security-best-practices/)

---

**Remember:** Security is an ongoing process. Regular reviews and updates of security practices are essential for maintaining a secure development environment.