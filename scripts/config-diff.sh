#!/bin/bash
# config-diff.sh - Compare local ~/.claude/ against git (master branch)
# Outputs valid JSON to stdout, errors to stderr
# No external dependencies (no jq, no python)

set -euo pipefail

# Parse flags
SUMMARY_ONLY=false
if [[ "${1:-}" == "--summary-only" ]]; then
    SUMMARY_ONLY=true
fi

# Repository path (MSYS2 format)
CLAUDE_CONFIG="$HOME/.claude"

# Function to escape JSON strings
json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n'
}

# Check if directory exists and is a git repo
if [[ ! -d "$CLAUDE_CONFIG/.git" ]]; then
    echo "{\"error\":\"$CLAUDE_CONFIG is not a git repo\"}" >&2
    exit 1
fi

cd "$CLAUDE_CONFIG" 2>/dev/null || exit 1

# Get timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get branch
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# Parse git status
declare -a modified_files=()
declare -a modified_staged=()
declare -a new_files=()
declare -a deleted_files=()

MODIFIED_COUNT=0
NEW_COUNT=0
DELETED_COUNT=0

while IFS= read -r line; do
    if [[ -z "$line" ]]; then continue; fi

    status="${line:0:2}"
    file="${line:3}"

    # Modified files (staged or unstaged)
    if [[ "$status" =~ ^M.$ ]] || [[ "$status" =~ ^.M$ ]]; then
        modified_files+=("$file")
        if [[ "${status:0:1}" == "M" ]]; then
            modified_staged+=("true")
        else
            modified_staged+=("false")
        fi
        MODIFIED_COUNT=$((MODIFIED_COUNT + 1))
    # New files (untracked or added)
    elif [[ "$status" == "??" ]] || [[ "$status" =~ ^A.$ ]]; then
        new_files+=("$file")
        NEW_COUNT=$((NEW_COUNT + 1))
    # Deleted files
    elif [[ "$status" =~ ^D.$ ]] || [[ "$status" =~ ^.D$ ]]; then
        deleted_files+=("$file")
        DELETED_COUNT=$((DELETED_COUNT + 1))
    fi
done < <(git status --porcelain 2>/dev/null)

TOTAL_CHANGES=$((MODIFIED_COUNT + NEW_COUNT + DELETED_COUNT))

# Check if requires commit/push
REQUIRES_COMMIT=false
if [[ $TOTAL_CHANGES -gt 0 ]]; then
    REQUIRES_COMMIT=true
fi

REQUIRES_PUSH=false
COMMITS_AHEAD=0
if git rev-parse @{u} >/dev/null 2>&1; then
    COMMITS_AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    if [[ $COMMITS_AHEAD -gt 0 ]]; then
        REQUIRES_PUSH=true
    fi
fi

# Begin JSON output
printf '{\n'
printf '  "timestamp":"%s",\n' "$TIMESTAMP"
printf '  "local_path":"%s",\n' "$CLAUDE_CONFIG"
printf '  "branch":"%s",\n' "$BRANCH"

# Summary section
printf '  "summary":{\n'
printf '    "modified_count":%d,\n' "$MODIFIED_COUNT"
printf '    "new_count":%d,\n' "$NEW_COUNT"
printf '    "deleted_count":%d,\n' "$DELETED_COUNT"
printf '    "total_changes":%d,\n' "$TOTAL_CHANGES"
printf '    "requires_commit":%s,\n' "$REQUIRES_COMMIT"
printf '    "requires_push":%s\n' "$REQUIRES_PUSH"
printf '  }'

# If summary-only, stop here
if [[ "$SUMMARY_ONLY" == true ]]; then
    printf '\n}\n'
    exit 0
fi

# Modified files array
printf ',\n  "modified_files":[\n'
for i in "${!modified_files[@]}"; do
    if [[ $i -gt 0 ]]; then printf ',\n'; fi
    printf '    {"path":"%s","staged":%s}' \
        "$(json_escape "${modified_files[$i]}")" \
        "${modified_staged[$i]}"
done
printf '\n  ]'

# New files array
printf ',\n  "new_files":[\n'
for i in "${!new_files[@]}"; do
    if [[ $i -gt 0 ]]; then printf ',\n'; fi
    printf '    {"path":"%s"}' "$(json_escape "${new_files[$i]}")"
done
printf '\n  ]'

# Deleted files array
printf ',\n  "deleted_files":[\n'
for i in "${!deleted_files[@]}"; do
    if [[ $i -gt 0 ]]; then printf ',\n'; fi
    printf '    {"path":"%s"}' "$(json_escape "${deleted_files[$i]}")"
done
printf '\n  ]'

printf '\n}\n'

exit 0
