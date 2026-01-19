#!/bin/bash
set -euo pipefail

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Claude Code CLI Installation Script
# Supports both native binary (default) and npm installation methods
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# === SECTION 1: CLEANUP TRAP ===
cleanup() {
    rm -f /tmp/claude 2>/dev/null || true
    rm -f /tmp/claude-manifest.json 2>/dev/null || true
}
trap cleanup EXIT

# === SECTION 2: IMPORT OPTIONS ===
# NOTE: DevContainer converts camelCase to UPPERCASE without underscores
INSTALL_METHOD="${INSTALLMETHOD:-native}"
VERSION="${VERSION:-latest}"
USERNAME="${USERNAME:-automatic}"
OVERWRITE_SETTINGS="${OVERWRITESETTINGS:-false}"
OVERWRITE_SYSTEM_PROMPT="${OVERWRITESYSTEMPROMPT:-false}"

echo "[claude-code] Starting Claude Code CLI installation..."
echo "[claude-code] Install method: ${INSTALL_METHOD}"
echo "[claude-code] Version: ${VERSION}"

# === SECTION 3: VALIDATE DEPENDENCIES ===
echo "[claude-code] Validating dependencies..."

# Source NVM if using npm install method (Node is installed via NVM by the node feature)
if [ "${INSTALL_METHOD}" = "npm" ]; then
    if [ -f /usr/local/share/nvm/nvm.sh ]; then
        source /usr/local/share/nvm/nvm.sh
    fi
fi

# jq is always required (for manifest parsing or other JSON ops)
if ! command -v jq &>/dev/null; then
    echo "[claude-code] ERROR: jq not available"
    echo "  Install common-utils feature: ghcr.io/devcontainers/features/common-utils:2"
    exit 1
fi

# Method-specific validation
if [ "${INSTALL_METHOD}" = "npm" ]; then
    if ! command -v npm &>/dev/null; then
        echo "[claude-code] ERROR: npm not available for npm installation"
        echo "  Add feature: ghcr.io/devcontainers/features/node:1"
        echo "  NVM path: /usr/local/share/nvm/nvm.sh"
        exit 1
    fi

    if [ ! -f /usr/local/share/nvm/nvm.sh ]; then
        echo "[claude-code] ERROR: NVM not found at /usr/local/share/nvm/nvm.sh"
        echo "  Ensure node feature installed with nvmInstallPath set to /usr/local/share/nvm"
        exit 1
    fi
elif [ "${INSTALL_METHOD}" = "native" ]; then
    # Validate we have curl for downloading
    if ! command -v curl &>/dev/null; then
        echo "[claude-code] ERROR: curl not available for native installation"
        echo "  Install via: apt-get install -y curl"
        exit 1
    fi

    # Validate we have sha256sum for checksum verification
    if ! command -v sha256sum &>/dev/null; then
        echo "[claude-code] ERROR: sha256sum not available for checksum verification"
        echo "  Install via: apt-get install -y coreutils"
        exit 1
    fi
fi

# === SECTION 4: VALIDATE INPUT ===
# Validate install method
if [[ "${INSTALL_METHOD}" != "npm" ]] && [[ "${INSTALL_METHOD}" != "native" ]]; then
    echo "[claude-code] ERROR: installMethod must be 'npm' or 'native'"
    echo "  Provided: ${INSTALL_METHOD}"
    exit 1
fi

# === SECTION 5: DETECT USER (for npm method) ===
if [ "${INSTALL_METHOD}" = "npm" ]; then
    if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
        USERNAME=""
        for CURRENT_USER in vscode node codespace; do
            if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
                USERNAME=${CURRENT_USER}
                break
            fi
        done
        [ -z "${USERNAME}" ] && USERNAME=root
    elif [ "${USERNAME}" = "none" ] || ! id -u "${USERNAME}" >/dev/null 2>&1; then
        USERNAME=root
    fi

    echo "[claude-code] Installing for user: ${USERNAME}"
else
    echo "[claude-code] Native installation (global to /usr/local/bin)"
fi

# === SECTION 6: INSTALL CLAUDE CODE ===
if [ "${INSTALL_METHOD}" = "native" ]; then
    echo "[claude-code] Using native installation method..."

    # Base URL for Claude Code distribution
    BASE_URL="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

    # Resolve "latest" to actual version number BEFORE skip check
    if [ "${VERSION}" = "latest" ]; then
        echo "[claude-code] Fetching latest version..."
        VERSION=$(curl -fsSL "${BASE_URL}/stable")
        if [ -z "${VERSION}" ]; then
            echo "[claude-code] ERROR: Failed to fetch latest version"
            exit 1
        fi
        echo "[claude-code] Latest version: ${VERSION}"
    fi

    # Check if already installed with same version
    if command -v claude &>/dev/null; then
        CURRENT_VERSION=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
        echo "[claude-code] Claude Code already installed: ${CURRENT_VERSION}"

        if [ "${CURRENT_VERSION}" = "${VERSION}" ]; then
            echo "[claude-code] Version ${VERSION} already installed, skipping..."
            exit 0
        else
            echo "[claude-code] Updating from ${CURRENT_VERSION} to ${VERSION}..."
        fi
    fi

    echo "[claude-code] Installing native Claude Code CLI..."

    # Detect platform
    ARCH=$(uname -m)
    case "${ARCH}" in
        x86_64)
            PLATFORM="linux-x64"
            ;;
        aarch64|arm64)
            PLATFORM="linux-arm64"
            ;;
        *)
            echo "[claude-code] ERROR: Unsupported architecture: ${ARCH}"
            echo "  Supported: x86_64, aarch64, arm64"
            exit 1
            ;;
    esac

    # Detect musl (Alpine Linux)
    if ldd --version 2>&1 | grep -qi musl; then
        echo "[claude-code] Detected musl libc (Alpine)"
        PLATFORM="${PLATFORM}-musl"
    fi

    echo "[claude-code] Platform: ${PLATFORM}"

    # Fetch manifest
    MANIFEST_URL="${BASE_URL}/${VERSION}/manifest.json"
    echo "[claude-code] Fetching manifest from ${MANIFEST_URL}..."

    if ! curl -fsSL "${MANIFEST_URL}" -o /tmp/claude-manifest.json; then
        echo "[claude-code] ERROR: Failed to download manifest"
        echo "  URL: ${MANIFEST_URL}"
        exit 1
    fi

    # Extract checksum for platform
    EXPECTED_CHECKSUM=$(jq -r ".platforms.\"${PLATFORM}\".checksum" /tmp/claude-manifest.json)
    if [ -z "${EXPECTED_CHECKSUM}" ] || [ "${EXPECTED_CHECKSUM}" = "null" ]; then
        echo "[claude-code] ERROR: Platform ${PLATFORM} not found in manifest"
        echo "  Available platforms:"
        jq -r '.platforms | keys[]' /tmp/claude-manifest.json
        exit 1
    fi

    echo "[claude-code] Expected SHA256: ${EXPECTED_CHECKSUM}"

    # Download binary
    BINARY_URL="${BASE_URL}/${VERSION}/${PLATFORM}/claude"
    echo "[claude-code] Downloading from ${BINARY_URL}..."

    if ! curl -fsSL "${BINARY_URL}" -o /tmp/claude; then
        echo "[claude-code] ERROR: Failed to download binary"
        echo "  URL: ${BINARY_URL}"
        exit 1
    fi

    # Verify checksum
    echo "[claude-code] Verifying checksum..."
    ACTUAL_CHECKSUM=$(sha256sum /tmp/claude | cut -d' ' -f1)

    if [ "${ACTUAL_CHECKSUM}" != "${EXPECTED_CHECKSUM}" ]; then
        echo "[claude-code] ERROR: Checksum verification failed"
        echo "  Expected: ${EXPECTED_CHECKSUM}"
        echo "  Actual:   ${ACTUAL_CHECKSUM}"
        exit 1
    fi

    echo "[claude-code] ✓ Checksum verified"

    # Install to /usr/local/bin
    chmod +x /tmp/claude
    mv /tmp/claude /usr/local/bin/claude

    # Verify installation
    if ! command -v claude &>/dev/null; then
        echo "[claude-code] ERROR: Installation failed - claude command not found"
        exit 1
    fi

    INSTALLED_VERSION=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    echo "[claude-code] ✓ Claude Code ${INSTALLED_VERSION} installed (native)"

elif [ "${INSTALL_METHOD}" = "npm" ]; then
    echo "[claude-code] Using npm installation method..."

    # Resolve "latest" to actual version number BEFORE skip check
    if [ "${VERSION}" = "latest" ]; then
        echo "[claude-code] Fetching latest version from npm registry..."
        VERSION=$(curl -fsSL "https://registry.npmjs.org/@anthropic-ai/claude-code/latest" | jq -r '.version')
        if [ -z "${VERSION}" ] || [ "${VERSION}" = "null" ]; then
            echo "[claude-code] ERROR: Failed to fetch latest version from npm"
            exit 1
        fi
        echo "[claude-code] Latest version: ${VERSION}"
    fi

    # Check if already installed with same version
    if sudo -u "${USERNAME}" bash -c 'command -v claude' &>/dev/null; then
        CURRENT_VERSION=$(sudo -u "${USERNAME}" bash -c 'claude --version 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1' || echo "unknown")
        echo "[claude-code] Claude Code already installed: ${CURRENT_VERSION}"

        if [ "${CURRENT_VERSION}" = "${VERSION}" ]; then
            echo "[claude-code] Version ${VERSION} already installed, skipping..."
            exit 0
        else
            echo "[claude-code] Updating from ${CURRENT_VERSION} to ${VERSION}..."
        fi
    fi

    echo "[claude-code] Installing Claude Code CLI via npm..."

    INSTALL_CMD="@anthropic-ai/claude-code@${VERSION}"

    echo "[claude-code] Installing: ${INSTALL_CMD}"

    sudo -u "${USERNAME}" bash -c "
        source /usr/local/share/nvm/nvm.sh
        npm install -g --prefix ~/.npm-global ${INSTALL_CMD}
    "

    # Verify installation
    if [[ ! -f "/home/${USERNAME}/.npm-global/bin/claude" ]]; then
        echo "[claude-code] ERROR: Installation failed"
        echo "  Expected: /home/${USERNAME}/.npm-global/bin/claude"
        exit 1
    fi

    INSTALLED_VERSION=$(sudo -u "${USERNAME}" bash -c 'source /usr/local/share/nvm/nvm.sh && claude --version 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1' || echo "unknown")
    echo "[claude-code] ✓ Claude Code ${INSTALLED_VERSION} installed (npm)"

    # === SECTION 7: CONFIGURE PATH (NPM ONLY) ===
    echo "[claude-code] Configuring PATH for npm installation..."

    PATH_EXPORT='export PATH="$HOME/.npm-global/bin:$PATH"'

    for SHELL_RC in .bashrc .zshrc; do
        RC_FILE="/home/${USERNAME}/${SHELL_RC}"
        if [ -f "${RC_FILE}" ]; then
            if ! grep -q ".npm-global/bin" "${RC_FILE}"; then
                echo "${PATH_EXPORT}" >> "${RC_FILE}"
                echo "[claude-code] ✓ Added to ${SHELL_RC}"
            else
                echo "[claude-code] PATH already configured in ${SHELL_RC}"
            fi
        fi
    done
fi

# === SECTION 7: CREATE POST-START HOOK FOR CONFIGURATION ===
echo "[claude-code] Creating post-start hook for configuration..."

# Get feature directory (where this script is located)
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create post-start hook directory (standard pattern for DevContainer features)
mkdir -p /usr/local/devcontainer-poststart.d

# Create post-start hook script for configuration and alias
# Runs on EVERY container start to ensure configs are copied and alias is set
# Note: Uses prefix 40 to run before MCP servers (50-51)
cat > /usr/local/devcontainer-poststart.d/40-claude-code.sh <<'HOOK_EOF'
#!/bin/bash
set -euo pipefail

echo "[claude-code] Auto-configuring Claude Code..."

# Get feature directory
FEATURE_DIR="/usr/local/share/claude-code"

# Determine user - use SUDO_USER since _REMOTE_USER isn't set in post-start hooks
# This hook runs as the remoteUser, so SUDO_USER will be set to the actual user
USERNAME="${SUDO_USER:-vscode}"
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    # Auto-detect user if needed
    USERNAME=""
    for CURRENT_USER in vscode node codespace; do
        if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    [ -z "${USERNAME}" ] && USERNAME=root
elif [ "${USERNAME}" = "none" ] || ! id -u "${USERNAME}" >/dev/null 2>&1; then
    USERNAME=root
fi

# Ensure .claude directory exists in workspace
mkdir -p /workspaces/.claude
mkdir -p /workspaces/.claude/commands
mkdir -p /workspaces/.claude/hooks
mkdir -p /workspaces/.claude/output-styles

# Copy settings.json (respect OVERWRITE_SETTINGS env var, default false)
OVERWRITE_SETTINGS="${OVERWRITE_SETTINGS:-false}"
if [ -f "${FEATURE_DIR}/settings.json" ]; then
    if [ ! -f "/workspaces/.claude/settings.json" ] || [ "${OVERWRITE_SETTINGS}" = "true" ]; then
        cp "${FEATURE_DIR}/settings.json" /workspaces/.claude/settings.json
        chmod 644 /workspaces/.claude/settings.json
        chown "${USERNAME}:${USERNAME}" /workspaces/.claude/settings.json 2>/dev/null || true
        if [ "${OVERWRITE_SETTINGS}" = "true" ]; then
            echo "[claude-code] ✓ Overwritten settings.json"
        else
            echo "[claude-code] ✓ Copied settings.json"
        fi
    else
        echo "[claude-code] Skipped settings.json (exists, overwriteSettings=false)"
    fi
fi

# Copy system-prompt.md (respect OVERWRITE_SYSTEM_PROMPT env var, default false)
OVERWRITE_SYSTEM_PROMPT="${OVERWRITE_SYSTEM_PROMPT:-false}"
if [ -f "${FEATURE_DIR}/system-prompt.md" ]; then
    if [ ! -f "/workspaces/.claude/system-prompt.md" ] || [ "${OVERWRITE_SYSTEM_PROMPT}" = "true" ]; then
        cp "${FEATURE_DIR}/system-prompt.md" /workspaces/.claude/system-prompt.md
        chmod 644 /workspaces/.claude/system-prompt.md
        chown "${USERNAME}:${USERNAME}" /workspaces/.claude/system-prompt.md 2>/dev/null || true
        if [ "${OVERWRITE_SYSTEM_PROMPT}" = "true" ]; then
            echo "[claude-code] ✓ Overwritten system-prompt.md"
        else
            echo "[claude-code] ✓ Copied system-prompt.md"
        fi
    else
        echo "[claude-code] Skipped system-prompt.md (exists, overwriteSystemPrompt=false)"
    fi
fi

# Ensure proper ownership
chown -R "${USERNAME}:${USERNAME}" /workspaces/.claude 2>/dev/null || true

# Create claude alias
echo "[claude-code] Setting up claude alias..."

# Determine prompt flag based on CLAUDE_PROMPT_MODE environment variable
if [ "${CLAUDE_PROMPT_MODE:-system}" = "append" ]; then
    PROMPT_FLAG="--append-system-prompt-file"
else
    PROMPT_FLAG="--system-prompt-file"
fi

# Create alias command
ALIAS_CMD="alias claude='claude --dangerously-skip-permissions ${PROMPT_FLAG} \"/workspaces/.claude/system-prompt.md\"'"

# Add to shell config files - use $HOME for better portability
for SHELL_RC in .bashrc .zshrc; do
    RC_FILE="$HOME/${SHELL_RC}"
    if [ -f "${RC_FILE}" ]; then
        if ! grep -q "claude --dangerously-skip-permissions" "${RC_FILE}" 2>/dev/null; then
            echo "${ALIAS_CMD}" >> "${RC_FILE}"
            echo "[claude-code] ✓ Added alias to ${SHELL_RC}"
        else
            echo "[claude-code] Alias already in ${SHELL_RC}"
        fi
    fi
done

# Run claude install as the vscode user
# echo "[claude-code] Running claude install..."
# if su - ${USERNAME} -c "claude install" 2>&1; then
#     echo "[claude-code] ✓ claude install completed"
# else
#     echo "[claude-code] WARNING: claude install failed (may be harmless)"
# fi

echo "[claude-code] ✓ Configuration complete"
HOOK_EOF

chmod +x /usr/local/devcontainer-poststart.d/40-claude-code.sh

# Copy config files to system location for post-start hook to access
mkdir -p /usr/local/share/claude-code
if [ -f "${FEATURE_DIR}/config/settings.json" ]; then
    cp "${FEATURE_DIR}/config/settings.json" /usr/local/share/claude-code/settings.json
    chmod 644 /usr/local/share/claude-code/settings.json
    echo "[claude-code] ✓ Config files staged for post-start hook"
else
    echo "[claude-code] WARNING: settings.json not found at ${FEATURE_DIR}/config/settings.json"
fi

if [ -f "${FEATURE_DIR}/config/system-prompt.md" ]; then
    cp "${FEATURE_DIR}/config/system-prompt.md" /usr/local/share/claude-code/system-prompt.md
    chmod 644 /usr/local/share/claude-code/system-prompt.md
else
    echo "[claude-code] WARNING: system-prompt.md not found at ${FEATURE_DIR}/config/system-prompt.md"
fi

echo "[claude-code] ✓ Post-start hook created at /usr/local/devcontainer-poststart.d/40-claude-code.sh"

# === SECTION 8: SUMMARY ===
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Claude Code CLI Installation Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configuration:"
echo "  • Method: ${INSTALL_METHOD}"
echo "  • Version: ${INSTALLED_VERSION:-${VERSION}}"

if [ "${INSTALL_METHOD}" = "native" ]; then
    echo "  • Binary: /usr/local/bin/claude"
    echo "  • Platform: ${PLATFORM}"
else
    echo "  • Binary: /home/${USERNAME}/.npm-global/bin/claude"
    echo "  • User: ${USERNAME}"
fi

echo ""
echo "Post-Start Configuration:"
echo "  • Hook: /usr/local/devcontainer-poststart.d/40-claude-code.sh"
echo "  • Will copy settings.json and system-prompt.md on container start"
echo "  • Will create claude alias with system prompt integration"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Next Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Container will auto-configure on start (postStartCommand)"
echo ""
echo "2. After container starts, verify:"
echo "   claude --version"
echo "   ls /workspaces/.claude/system-prompt.md"
echo "   alias | grep claude"
echo ""
echo "3. Authenticate:"
echo "   claude auth login"
echo ""
echo "4. Use Claude Code (alias includes system prompt):"
echo "   claude"
echo ""
echo "5. Customize system prompt:"
echo "   Edit /workspaces/.claude/system-prompt.md"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
