#
# Connect to CodeForge devcontainer from external terminal with tmux
# For Claude Code Agent Teams split-pane support
#
# Usage: .\connect-external-terminal.ps1
#
# Prerequisites:
#   - Docker Desktop installed and running
#   - Devcontainer already running (via VS Code or CLI)
#
# This script will:
#   1. Auto-detect your running devcontainer
#   2. Attach to it with an interactive shell
#   3. Start or attach to a tmux session named "claude-teams"
#

$ErrorActionPreference = "Stop"

$TMUX_SESSION = "claude-teams"
$CONTAINER_LABEL = "devcontainer.local_folder"

Write-Host "======================================"
Write-Host "  CodeForge External Terminal Connect"
Write-Host "======================================"
Write-Host ""

# Find the devcontainer
Write-Host "Searching for running devcontainer..."

try {
    $CONTAINER_ID = docker ps --filter "label=$CONTAINER_LABEL" --format "{{.ID}}" | Select-Object -First 1
} catch {
    Write-Host ""
    Write-Host "ERROR: Docker command failed. Is Docker Desktop running?" -ForegroundColor Red
    Write-Host ""
    exit 1
}

if ([string]::IsNullOrWhiteSpace($CONTAINER_ID)) {
    Write-Host ""
    Write-Host "ERROR: No running devcontainer found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure your devcontainer is running:"
    Write-Host "  1. Open VS Code"
    Write-Host "  2. Open the folder containing .devcontainer/"
    Write-Host "  3. Use 'Dev Containers: Reopen in Container'"
    Write-Host ""
    exit 1
}

# Get container name for display
$CONTAINER_NAME = docker ps --filter "id=$CONTAINER_ID" --format "{{.Names}}"
Write-Host "Found container: $CONTAINER_NAME ($CONTAINER_ID)"
Write-Host ""

# Check if tmux is available in the container
$tmuxCheck = docker exec $CONTAINER_ID which tmux 2>$null
if ([string]::IsNullOrWhiteSpace($tmuxCheck)) {
    Write-Host "ERROR: tmux is not installed in the container." -ForegroundColor Red
    Write-Host "Rebuild the devcontainer to install the tmux feature."
    exit 1
}

Write-Host "Connecting to tmux session '$TMUX_SESSION'..."
Write-Host ""
Write-Host "Tips:"
Write-Host "  - Agent Teams will use this terminal for split panes"
Write-Host "  - Run 'claude' to start Claude Code"
Write-Host "  - Press Ctrl+B then D to detach (keeps session running)"
Write-Host "  - Mouse support is enabled for pane selection"
Write-Host ""
Write-Host "======================================"
Write-Host ""

# Connect to container with tmux
# -A attaches to existing session or creates new one
docker exec -it $CONTAINER_ID tmux new-session -A -s $TMUX_SESSION
