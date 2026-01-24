#!/usr/bin/env python3
"""
Auto-format files after editing.

Reads tool input from stdin, detects file type by extension,
runs appropriate formatter if available.
Outputs JSON with additionalContext on success.
Non-blocking: exit 0 regardless of formatting result.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

# Formatter configuration: extension -> (command, args, name)
FORMATTERS = {
    ".py": ("/usr/local/py-utils/bin/black", ["--quiet"], "Black"),
    ".pyi": ("/usr/local/py-utils/bin/black", ["--quiet"], "Black"),
    ".go": ("/usr/local/go/bin/gofmt", ["-w"], "gofmt"),
}


def get_formatter(file_path: str) -> tuple[str, list[str], str] | None:
    """Get formatter config for file extension."""
    ext = Path(file_path).suffix.lower()
    return FORMATTERS.get(ext)


def format_file(file_path: str) -> tuple[bool, str]:
    """Run formatter on file.

    Returns:
        (success, message)
    """
    formatter = get_formatter(file_path)
    if formatter is None:
        return True, ""  # No formatter available, that's OK

    cmd_path, args, name = formatter

    # Check if formatter exists
    if not os.path.exists(cmd_path):
        return True, f"[Auto-formatter] {name} not found, skipping"

    # Check if file exists
    if not os.path.exists(file_path):
        return True, ""

    try:
        # Run formatter
        cmd = [cmd_path] + args + [file_path]
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=25
        )

        if result.returncode == 0:
            return True, f"[Auto-formatter] Formatted with {name}"
        else:
            # Formatting failed, but don't block
            error = result.stderr.strip() if result.stderr else "Unknown error"
            return True, f"[Auto-formatter] {name} warning: {error}"

    except subprocess.TimeoutExpired:
        return True, f"[Auto-formatter] {name} timed out"
    except Exception as e:
        return True, f"[Auto-formatter] Error: {e}"


def main():
    try:
        input_data = json.load(sys.stdin)
        tool_input = input_data.get("tool_input", {})
        file_path = tool_input.get("file_path", "")

        if not file_path:
            sys.exit(0)

        _, message = format_file(file_path)

        if message:
            # Output context for Claude
            print(json.dumps({
                "additionalContext": message
            }))

        sys.exit(0)

    except json.JSONDecodeError:
        sys.exit(0)
    except Exception as e:
        print(f"Hook error: {e}", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()
