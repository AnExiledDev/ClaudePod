# API Keys Setup for ClaudePod

ClaudePod supports additional MCP servers that require API keys. This guide explains how to set them up securely.

## 🔧 Setup Process

### 1. Copy Environment Template
```bash
cp .devcontainer/.env.example .devcontainer/.env
```

### 2. Get API Keys

#### Tavily Search API Key
- Visit: https://tavily.com/
- Sign up for an account
- Navigate to API section
- Copy your API key

#### Ref.Tools API Key  
- Visit: https://ref.tools/
- Create an account
- Go to API settings
- Generate and copy your API key

### 3. Configure Environment
Edit your `.env` file:
```bash
# Required API keys
TAVILY_API_KEY=tvly-your-actual-api-key-here
REF_TOOLS_API_KEY=rt-your-actual-api-key-here
```

### 4. Rebuild Container
For DevPod to load the new environment variables:
```bash
# Delete current workspace
devpod delete <workspace-name>

# Recreate with new environment
devpod up .
```

## 🔒 Security Notes

- **Never commit API keys** - `.env` files are git-ignored
- **Use `.env.example`** for sharing configuration templates
- **Rotate keys regularly** as per provider recommendations
- **Check permissions** - ensure `.env` has restricted access

## ✅ Verification

After rebuilding, check that servers are installed:
```bash
claude mcp list
```

You should see:
- ✅ serena
- ✅ deepwiki
- ✅ tavily-search (if TAVILY_API_KEY set)
- ✅ ref-tools (if REF_TOOLS_API_KEY set)

## 🚨 Troubleshooting

**Server not appearing?**
- Check API key is correctly set in `.env`
- Verify container was rebuilt after adding keys
- Check container logs: `devpod logs <workspace>`

**Invalid API key errors?**
- Verify key is copied correctly (no extra spaces)
- Check key hasn't expired on provider website
- Ensure key has necessary permissions

**Container won't start?**
- Check `.env` file syntax (no spaces around =)
- Ensure no special characters need escaping
- Try removing problematic keys temporarily

## 📚 Adding More Servers

To add additional MCP servers:

1. **Add environment variable** to `devcontainer.json`:
   ```json
   "containerEnv": {
     "NEW_API_KEY": "${localEnv:NEW_API_KEY}"
   }
   ```

2. **Update `.env.example`** with the new key

3. **Add installation logic** to `post-start.sh`

4. **Update documentation** to include the new server