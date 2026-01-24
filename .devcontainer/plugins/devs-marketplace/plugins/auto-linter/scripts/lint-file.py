#!/usr/bin/env python3
"""
Auto-lint files after editing.

Reads tool input from stdin, detects file type by extension,
runs appropriate linter if available.
Outputs JSON with additionalContext containing lint warnings.
Non-blocking: exit 0 regardless of lint result.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

# Linter configuration: extension -> (command, args, name, parser)
PYTHON_EXTENSIONS = {".py", ".pyi"}


def lint_python(file_path: str) -> tuple[bool, str]:
    """Run pyright on a Python file.

    Returns:
        (success, message)
    """
    pyright_cmd = "pyright"

    # Check if pyright is available
    try:
        subprocess.run(
            ["which", pyright_cmd],
            capture_output=True,
            check=True
        )
    except subprocess.CalledProcessError:
        return True, ""  # Pyright not available

    try:
        result = subprocess.run(
            [pyright_cmd, "--outputjson", file_path],
            capture_output=True,
            text=True,
            timeout=55
        )

        # Parse pyright JSON output
        try:
            output = json.loads(result.stdout)
            diagnostics = output.get("generalDiagnostics", [])

            if not diagnostics:
                return True, "[Auto-linter] Pyright: No issues found"

            # Format diagnostics
            issues = []
            for diag in diagnostics[:5]:  # Limit to first 5 issues
                severity = diag.get("severity", "info")
                message = diag.get("message", "")
                line = diag.get("range", {}).get("start", {}).get("line", 0) + 1

                if severity == "error":
                    icon = "✗"
                elif severity == "warning":
                    icon = "!"
                else:
                    icon = "•"

                issues.append(f"  {icon} Line {line}: {message}")

            total = len(diagnostics)
            shown = min(5, total)
            header = f"[Auto-linter] Pyright: {total} issue(s)"
            if total > shown:
                header += f" (showing first {shown})"

            return True, header + "\n" + "\n".join(issues)

        except json.JSONDecodeError:
            # Pyright output not JSON, might be an error
            if result.stderr:
                return True, f"[Auto-linter] Pyright error: {result.stderr.strip()[:100]}"
            return True, ""

    except subprocess.TimeoutExpired:
        return True, "[Auto-linter] Pyright timed out"
    except Exception as e:
        return True, f"[Auto-linter] Error: {e}"


def lint_file(file_path: str) -> tuple[bool, str]:
    """Run appropriate linter for file.

    Returns:
        (success, message)
    """
    ext = Path(file_path).suffix.lower()

    if ext in PYTHON_EXTENSIONS:
        return lint_python(file_path)

    # No linter available for this file type
    return True, ""


def main():
    try:
        input_data = json.load(sys.stdin)
        tool_input = input_data.get("tool_input", {})
        file_path = tool_input.get("file_path", "")

        if not file_path:
            sys.exit(0)

        # Check if file exists
        if not os.path.exists(file_path):
            sys.exit(0)

        _, message = lint_file(file_path)

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
