#!/usr/bin/env python3
"""
Unified batch formatter — runs as a Stop hook.

Reads file paths collected by collect-edited-files.py during the
conversation turn, deduplicates them, and formats each based on
extension:
  .py / .pyi       → Black
  .go              → gofmt
  .js/.jsx/.ts/.tsx/.mjs/.cjs/.mts/.cts/.css → Biome (safe mode)

Always cleans up the temp file. Always exits 0.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

# Formatter dispatch by extension
PYTHON_EXTS = {".py", ".pyi"}
GO_EXTS = {".go"}
BIOME_EXTS = {
    ".js",
    ".jsx",
    ".ts",
    ".tsx",
    ".mjs",
    ".cjs",
    ".mts",
    ".cts",
    ".css",
}

BLACK_PATH_FALLBACK = "/usr/local/py-utils/bin/black"
GOFMT_PATH_FALLBACK = "/usr/local/go/bin/gofmt"


def _resolve_tool(name: str, fallback: str) -> str | None:
    """Find tool via PATH first, fall back to hardcoded path."""
    try:
        result = subprocess.run(["which", name], capture_output=True, text=True)
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    if os.path.exists(fallback):
        return fallback
    return None


def find_tool_upward(file_path: str, tool_name: str) -> str | None:
    """Walk up from file directory looking for node_modules/.bin/<tool>."""
    current = Path(file_path).parent
    for _ in range(20):
        candidate = current / "node_modules" / ".bin" / tool_name
        if candidate.is_file():
            return str(candidate)
        parent = current.parent
        if parent == current:
            break
        current = parent
    return None


def find_global_tool(tool_name: str) -> str | None:
    """Check if tool is available globally."""
    try:
        result = subprocess.run(
            ["which", tool_name],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return None


def find_biome(file_path: str) -> str | None:
    """Find biome binary: project-local first, then global."""
    local = find_tool_upward(file_path, "biome")
    if local:
        return local
    return find_global_tool("biome")


def format_python(file_path: str) -> None:
    """Format with Black (quiet mode)."""
    black = _resolve_tool("black", BLACK_PATH_FALLBACK)
    if not black:
        return
    try:
        subprocess.run(
            [black, "--quiet", file_path],
            capture_output=True,
            timeout=10,
        )
    except (subprocess.TimeoutExpired, OSError):
        pass


def format_go(file_path: str) -> None:
    """Format with gofmt."""
    gofmt = _resolve_tool("gofmt", GOFMT_PATH_FALLBACK)
    if not gofmt:
        return
    try:
        subprocess.run(
            [gofmt, "-w", file_path],
            capture_output=True,
            timeout=10,
        )
    except (subprocess.TimeoutExpired, OSError):
        pass


def format_biome(file_path: str) -> None:
    """Format with Biome in safe mode (no --unsafe)."""
    biome = find_biome(file_path)
    if not biome:
        return
    try:
        subprocess.run(
            [biome, "check", "--write", file_path],
            capture_output=True,
            timeout=12,
        )
    except (subprocess.TimeoutExpired, OSError):
        pass


def format_file(file_path: str) -> None:
    """Dispatch to the correct formatter based on extension."""
    ext = Path(file_path).suffix.lower()
    if ext in PYTHON_EXTS:
        format_python(file_path)
    elif ext in GO_EXTS:
        format_go(file_path)
    elif ext in BIOME_EXTS:
        format_biome(file_path)


def main():
    try:
        input_data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    # Prevent infinite loops if Stop hook triggers another stop
    if input_data.get("stop_hook_active"):
        sys.exit(0)

    session_id = input_data.get("session_id", "")
    if not session_id:
        sys.exit(0)

    tmp_path = f"/tmp/claude-edited-files-{session_id}"

    try:
        with open(tmp_path) as f:
            raw_paths = f.read().splitlines()
    except FileNotFoundError:
        sys.exit(0)
    except OSError:
        sys.exit(0)
    finally:
        # Always clean up the temp file
        try:
            os.unlink(tmp_path)
        except OSError:
            pass

    # Deduplicate while preserving order, filter to existing files
    seen: set[str] = set()
    paths: list[str] = []
    for p in raw_paths:
        p = p.strip()
        if p and p not in seen and os.path.isfile(p):
            seen.add(p)
            paths.append(p)

    for path in paths:
        format_file(path)

    sys.exit(0)


if __name__ == "__main__":
    main()
