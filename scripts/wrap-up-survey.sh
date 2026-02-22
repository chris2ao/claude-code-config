#!/bin/bash
# wrap-up-survey.sh - Pre-compute git state of all repos + session artifacts before wrap-up
# Outputs valid JSON to stdout, errors to stderr
# No external dependencies (no jq, no python)

set -euo pipefail

# Start timing
START_TIME=$SECONDS

# Repository paths (MSYS2 format)
CJCLAUDE="/d/Users/chris_dnlqpqd/OneDrive/AI_Projects/Claude/CJClaude_1"
CRYPTOFLEX="/d/Users/chris_dnlqpqd/OneDrive/AI_Projects/Claude/cryptoflexllc"
CRYPTOFLEX_OPS="/d/Users/chris_dnlqpqd/OneDrive/AI_Projects/Claude/cryptoflex-ops"
CLAUDE_CONFIG="$HOME/.claude"
THIRD_CONFLICT="/d/Users/chris_dnlqpqd/OneDrive/AI_Projects/Claude/Third-Conflict"

# Function to escape JSON strings
json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n'
}

# Function to get repo info
get_repo_info() {
    local name="$1"
    local path="$2"

    if [[ ! -d "$path/.git" ]]; then
        echo "  {\"name\":\"$name\",\"path\":\"$path\",\"error\":\"not a git repo\"}" >&2
        return
    fi

    cd "$path" 2>/dev/null || return

    # Get branch
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "unknown")

    # Get status
    local modified_files=()
    local untracked_files=()
    local clean=true

    while IFS= read -r line; do
        if [[ -z "$line" ]]; then continue; fi
        local status="${line:0:2}"
        local file="${line:3}"

        if [[ "$status" =~ ^[MAD].$ ]] || [[ "$status" =~ ^.[MAD]$ ]]; then
            modified_files+=("$file")
            clean=false
        elif [[ "$status" == "??" ]]; then
            untracked_files+=("$file")
            clean=false
        fi
    done < <(git status --porcelain 2>/dev/null)

    # Get last commit
    local last_commit
    last_commit=$(git log -1 --format='%h %s' 2>/dev/null || echo "none")

    # Get last commit date
    local last_commit_date
    last_commit_date=$(git log -1 --format='%aI' 2>/dev/null || echo "")

    # Get ahead/behind counts
    local commits_ahead=0
    local commits_behind=0

    if git rev-parse @{u} >/dev/null 2>&1; then
        commits_ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
        commits_behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    fi

    # Build modified_files JSON array
    local modified_json="["
    local first=true
    for f in "${modified_files[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            modified_json+=","
        fi
        modified_json+="\"$(json_escape "$f")\""
    done
    modified_json+="]"

    # Build untracked_files JSON array
    local untracked_json="["
    first=true
    for f in "${untracked_files[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            untracked_json+=","
        fi
        untracked_json+="\"$(json_escape "$f")\""
    done
    untracked_json+="]"

    # Output JSON object
    printf '    {\n'
    printf '      "name":"%s",\n' "$name"
    printf '      "path":"%s",\n' "$path"
    printf '      "branch":"%s",\n' "$branch"
    printf '      "clean":%s,\n' "$clean"
    printf '      "modified_files":%s,\n' "$modified_json"
    printf '      "untracked_files":%s,\n' "$untracked_json"
    printf '      "last_commit":"%s",\n' "$(json_escape "$last_commit")"
    printf '      "last_commit_date":"%s",\n' "$last_commit_date"
    printf '      "commits_ahead":%d,\n' "$commits_ahead"
    printf '      "commits_behind":%d\n' "$commits_behind"
    printf '    }'
}

# Health check accumulators
ALL_CLEAN=true
ANY_AHEAD=false
ANY_BEHIND=false

# Get timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Begin JSON output
printf '{\n'
printf '  "timestamp":"%s",\n' "$TIMESTAMP"

# Collect repo info into temp files so we can also track health
REPO_OUTPUT=""
for repo_pair in "CJClaude_1|$CJCLAUDE" "cryptoflexllc|$CRYPTOFLEX" "cryptoflex-ops|$CRYPTOFLEX_OPS" "Third-Conflict|$THIRD_CONFLICT" "claude-code-config|$CLAUDE_CONFIG"; do
    name="${repo_pair%%|*}"
    path="${repo_pair#*|}"

    repo_json=$(get_repo_info "$name" "$path")
    if [[ -n "$repo_json" ]]; then
        if [[ -n "$REPO_OUTPUT" ]]; then
            REPO_OUTPUT+=$',\n'
        fi
        REPO_OUTPUT+="$repo_json"
    fi

    # Check health from the repo
    if [[ -d "$path/.git" ]]; then
        cd "$path" 2>/dev/null || continue
        if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
            ALL_CLEAN=false
        fi
        if git rev-parse @{u} >/dev/null 2>&1; then
            local_ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
            local_behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
            if [[ "$local_ahead" -gt 0 ]]; then ANY_AHEAD=true; fi
            if [[ "$local_behind" -gt 0 ]]; then ANY_BEHIND=true; fi
        fi
    fi
done

echo '  "repos":['
printf '%s\n' "$REPO_OUTPUT"
echo '  ],'

# Session artifacts
TRANSCRIPT_COUNT=0
if [[ -d "$HOME/.claude/projects" ]]; then
    TRANSCRIPT_COUNT=$(find "$HOME/.claude/projects" -name "*.jsonl" 2>/dev/null | wc -l)
fi

TODO_COUNT=0
if [[ -d "$HOME/.claude/todos" ]]; then
    TODO_COUNT=$(find "$HOME/.claude/todos" -name "*.json" 2>/dev/null | wc -l)
fi

ACTIVITY_LOG_LINES=0
if [[ -f "$CJCLAUDE/activity_log.txt" ]]; then
    ACTIVITY_LOG_LINES=$(wc -l < "$CJCLAUDE/activity_log.txt" 2>/dev/null || echo 0)
fi

printf '  "session_artifacts":{\n'
printf '    "transcript_count":%d,\n' "$TRANSCRIPT_COUNT"
printf '    "todo_count":%d,\n' "$TODO_COUNT"
printf '    "activity_log_lines":%d\n' "$ACTIVITY_LOG_LINES"
printf '  },\n'

# Health checks (computed from repo data)
printf '  "health_checks":{\n'
printf '    "all_repos_clean":%s,\n' "$ALL_CLEAN"
printf '    "requires_push":%s,\n' "$ANY_AHEAD"
printf '    "requires_pull":%s\n' "$ANY_BEHIND"
printf '  },\n'

# Duration
DURATION=$((SECONDS - START_TIME))
printf '  "survey_duration_ms":%d\n' $((DURATION * 1000))

printf '}\n'

exit 0
