# AgentPod DevContainer Features

This directory contains DevContainer Features for AI coding agent environments. These features follow the [DevContainer Features specification](https://containers.dev/implementors/features/) and can be published to OCI registries for distribution.

## Available Features

### mcp-qdrant
Vector database integration via Qdrant MCP server. Enables semantic search, embeddings management, and RAG workflows.

**Status**: ✅ Complete
**Documentation**: [mcp-qdrant/README.md](./mcp-qdrant/README.md)

## Feature Structure

Each feature follows this structure:

```
feature-name/
├── devcontainer-feature.json   # Feature metadata and options
├── install.sh                  # Installation script (executable)
└── README.md                   # Feature documentation
```

## Development Workflow

### Creating a New Feature

1. **Create directory**: `mkdir features/feature-name`
2. **Add metadata**: Create `devcontainer-feature.json`
3. **Write installer**: Create `install.sh` (make executable)
4. **Document**: Create `README.md`
5. **Test locally**: Reference in devcontainer.json

### Local Testing

To test a feature locally before publishing:

```json
{
  "features": {
    "./features/feature-name": {
      "option1": "value1"
    }
  }
}
```

### Publishing Features

Features will be published to GitHub Container Registry (GHCR):

```
ghcr.io/yourorg/agentpod-features/feature-name:1
```

**Publishing workflow** (future):
- Push to main branch
- GitHub Actions builds and publishes
- Tags create versioned releases

## Feature Guidelines

### Granularity
- **One feature = One tool/service**
- Bundle only if tools are always used together
- See [AGENTPOD_ARCHITECTURE.md](../../AGENTPOD_ARCHITECTURE.md) for guidance

### Options
- Use clear, descriptive option names
- Provide sensible defaults
- Support environment variable substitution: `"${env:VAR}"`
- Document all options in README

### Installation
- Must be idempotent (safe to run multiple times)
- Check if already installed before installing
- Use appropriate user (not always root)
- Clean up on failure

### Configuration
- Generate necessary config files
- Provide helper scripts for manual setup
- Print clear installation summary
- Show next steps to user

## Migration from Modules

ClaudePod modules are being converted to DevContainer Features:

| Old Module | New Feature | Status |
|-----------|-------------|---------|
| mcp_qdrant | mcp-qdrant | ✅ Complete |
| mcp_browser | mcp-browser | 🔜 Planned |
| mcp_sourcerer | mcp-sourcerer | 🔜 Planned |
| mcp_reasoner | mcp-reasoner | 🔜 Planned |
| mcp_obsidian | mcp-obsidian | 🔜 Planned |
| mcp_code_runner | mcp-code-runner | 🔜 Planned |

## Resources

- [DevContainer Features Specification](https://containers.dev/implementors/features/)
- [Feature Authoring Guide](https://containers.dev/guide/author-a-feature)
- [Feature Best Practices](https://containers.dev/guide/feature-authoring-best-practices)
- [AgentPod Architecture](../../AGENTPOD_ARCHITECTURE.md)

## Contributing

Features are part of the AgentPod project. See main repository for contribution guidelines.

---

**Status**: Active Development
**Last Updated**: 2025-11-11
