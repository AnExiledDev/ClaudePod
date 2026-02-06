#!/usr/bin/env python3
"""
Collect edited file paths for batch formatting at Stop.

Lightweight PostToolUse hook that appends the edited file path
to a session-scoped temp file. The auto-formatter Stop hook
reads this file to know which files need formatting.

Non-blocking: always exits 0. Runs in <10ms.
"""

import json
import os
import sys


def main():
    try:
        input_data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    session_id = input_data.get("session_id", "")
    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    if not file_path or not session_id:
        sys.exit(0)

    if not os.path.isfile(file_path):
        sys.exit(0)

    tmp_path = f"/tmp/claude-edited-files-{session_id}"
    try:
        with open(tmp_path, "a") as f:
            f.write(file_path + "\n")
    except OSError:
        pass  # non-critical, don't block Claude

    sys.exit(0)


if __name__ == "__main__":
    main()
