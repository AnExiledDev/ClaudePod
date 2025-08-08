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
  const currentDir = process.cwd();
  const packageDir = __dirname;
  const devcontainerSrc = path.join(packageDir, '.devcontainer');
  const devcontainerDest = path.join(currentDir, '.devcontainer');

  console.log('🚀 Setting up ClaudePod DevContainer...');

  // Check if .devcontainer already exists
  if (fs.existsSync(devcontainerDest)) {
    console.log('⚠️  .devcontainer directory already exists.');
    console.log('   Remove it first or run in a different directory.');
    process.exit(1);
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
    console.log('   1. devpod up .');
    console.log('   2. devpod ssh <workspace-name> --ide vscode');
    console.log('   3. Start coding with Claude: claude');
    console.log('');
    console.log('📚 Features included:');
    console.log('   • Claude Code CLI with optimized tool configuration');
    console.log('   • MCP servers: Serena, DeepWiki, TaskMaster AI, Sequential Thinking');
    console.log('   • Development tools: Node.js 20, Python 3.13, Git with delta');
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