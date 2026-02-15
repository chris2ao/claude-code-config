#!/bin/bash
# git-stats.sh - Recent git history stats for a given repo
# Usage: bash git-stats.sh [repo-path]
# Outputs valid JSON to stdout, errors to stderr
# No external dependencies (no jq, no python)

set -euo pipefail

# Default to CJClaude_1 path
REPO_PATH="${1:-/d/Users/chris_dnlqpqd/OneDrive/AI_Projects/Claude/CJClaude_1}"

# Function to escape JSON strings
json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n'
}

# Check if directory exists and is a git repo
if [[ ! -d "$REPO_PATH/.git" ]]; then
    echo "{\"error\":\"$REPO_PATH is not a git repo\"}" >&2
    exit 1
fi

cd "$REPO_PATH" 2>/dev/null || exit 1

# Get repo name (last component of path)
REPO_NAME=$(basename "$REPO_PATH")

# Get timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Commits in last 7 days
COMMITS_7D=$(git log --since="7 days ago" --oneline 2>/dev/null | wc -l)

# Commits today
COMMITS_TODAY=$(git log --since="midnight" --oneline 2>/dev/null | wc -l)

# Files changed in last 7 days (unique file paths)
FILES_CHANGED_7D=$(git log --since="7 days ago" --name-only --format="" 2>/dev/null | sort -u | grep -v '^$' | wc -l)

# Lines added/deleted in last 7 days
LINES_ADDED_7D=0
LINES_DELETED_7D=0

if git log --since="7 days ago" --oneline 2>/dev/null | grep -q .; then
    # Get shortstat for last 7 days
    STATS=$(git log --since="7 days ago" --shortstat --format="" 2>/dev/null | \
            awk '{files+=$1; inserted+=$4; deleted+=$6} END {print inserted, deleted}')

    if [[ -n "$STATS" ]]; then
        read -r LINES_ADDED_7D LINES_DELETED_7D <<< "$STATS"
        LINES_ADDED_7D=${LINES_ADDED_7D:-0}
        LINES_DELETED_7D=${LINES_DELETED_7D:-0}
    fi
fi

# Top authors (last 7 days)
declare -a author_names=()
declare -a author_counts=()

while IFS=$'\t' read -r count name; do
    author_counts+=("$count")
    author_names+=("$name")
done < <(git shortlog -sn --since="7 days ago" 2>/dev/null | head -5)

# Recent commits (last 10)
declare -a commit_hashes=()
declare -a commit_messages=()
declare -a commit_dates=()
declare -a commit_authors=()

while IFS='|' read -r hash msg date author; do
    commit_hashes+=("$hash")
    commit_messages+=("$msg")
    commit_dates+=("$date")
    commit_authors+=("$author")
done < <(git log -10 --format='%h|%s|%aI|%an' 2>/dev/null)

# Begin JSON output
printf '{\n'
printf '  "timestamp":"%s",\n' "$TIMESTAMP"
printf '  "repo":"%s",\n' "$REPO_NAME"
printf '  "path":"%s",\n' "$REPO_PATH"

# Stats section
printf '  "stats":{\n'
printf '    "commits_7d":%d,\n' "$COMMITS_7D"
printf '    "commits_today":%d,\n' "$COMMITS_TODAY"
printf '    "files_changed_7d":%d,\n' "$FILES_CHANGED_7D"
printf '    "lines_added_7d":%d,\n' "$LINES_ADDED_7D"
printf '    "lines_deleted_7d":%d,\n' "$LINES_DELETED_7D"

# Top authors array
printf '    "top_authors":[\n'
for i in "${!author_names[@]}"; do
    if [[ $i -gt 0 ]]; then printf ',\n'; fi
    printf '      {"name":"%s","commits":%d}' \
        "$(json_escape "${author_names[$i]}")" \
        "${author_counts[$i]}"
done
printf '\n    ]\n'
printf '  },\n'

# Recent commits array
printf '  "recent_commits":[\n'
for i in "${!commit_hashes[@]}"; do
    if [[ $i -gt 0 ]]; then printf ',\n'; fi
    printf '    {"hash":"%s","message":"%s","date":"%s","author":"%s"}' \
        "${commit_hashes[$i]}" \
        "$(json_escape "${commit_messages[$i]}")" \
        "${commit_dates[$i]}" \
        "$(json_escape "${commit_authors[$i]}")"
done
printf '\n  ]\n'

printf '}\n'

exit 0
