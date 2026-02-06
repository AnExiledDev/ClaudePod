#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-latest}"

echo "[biome] Starting installation..."
echo "[biome] Version: ${VERSION}"

# Install Biome globally via npm
if [ "${VERSION}" = "latest" ]; then
    npm install -g @biomejs/biome
else
    npm install -g "@biomejs/biome@${VERSION}"
fi

# Verify installation
biome --version

echo "[biome] Installation complete"
