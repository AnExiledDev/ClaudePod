#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

function copyDirectory(src, dest) {
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
  }

  const entries = fs.readdirSync(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      copyDirectory(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

function main() {
  const args = process.argv.slice(2);
  const force = args.includes('--force') || args.includes('-f');

  const currentDir = process.cwd();
  const packageDir = __dirname;
  const devcontainerSrc = path.join(packageDir, '.devcontainer');
  const devcontainerDest = path.join(currentDir, '.devcontainer');

  console.log('🚀 Setting up ClaudePod DevContainer...');

  // Check if .devcontainer already exists
  if (fs.existsSync(devcontainerDest)) {
    if (force) {
      console.log('⚠️  Removing existing .devcontainer directory...');
      fs.rmSync(devcontainerDest, { recursive: true, force: true });
    } else {
      console.log('⚠️  .devcontainer directory already exists.');
      console.log('   Use --force to overwrite, or remove it manually.');
      process.exit(1);
    }
  }

  // Check if source .devcontainer exists
  if (!fs.existsSync(devcontainerSrc)) {
    console.error('❌ Error: .devcontainer source directory not found in package.');
    process.exit(1);
  }

  try {
    // Copy .devcontainer directory
    copyDirectory(devcontainerSrc, devcontainerDest);
    
    console.log('✅ ClaudePod DevContainer configuration installed!');
    console.log('');
    console.log('🔧 Next steps:');
    console.log('   1. Open this folder in VS Code');
    console.log('   2. Select "Reopen in Container" from the command palette');
    console.log('   3. Run: claude');
    console.log('');
    console.log('📚 Features included:');
    console.log('   • Claude Code CLI with optimized tool configuration');
    console.log('   • MCP servers: Qdrant (vector memory), Reasoner');
    console.log('   • Development tools: Node.js LTS, Python 3.14, Git with delta');
    console.log('   • Persistent configuration and shell history');
    console.log('');
    console.log('🔗 Documentation: See .devcontainer/README.md');

  } catch (error) {
    console.error('❌ Error copying .devcontainer:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { copyDirectory, main };