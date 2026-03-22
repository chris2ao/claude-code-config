#!/usr/bin/env bash
# Cross-platform hook dispatcher
# Usage: dispatch.sh <hook-name>
# Runs .sh on macOS/Linux, .ps1 via PowerShell on Windows
set -uo pipefail

SCRIPT_NAME="$1"
HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "$OSTYPE" == darwin* || "$OSTYPE" == linux* ]]; then
    exec bash "$HOOKS_DIR/${SCRIPT_NAME}.sh"
else
    # Windows (MSYS2 / Git Bash)
    WIN_PATH="$(cygpath -w "$HOOKS_DIR/${SCRIPT_NAME}.ps1" 2>/dev/null || echo "$HOOKS_DIR/${SCRIPT_NAME}.ps1")"
    exec powershell -Command ". '${WIN_PATH}'"
fi
