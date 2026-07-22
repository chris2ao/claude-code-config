#!/bin/bash
# platform: portable (macOS + Windows/Git Bash)
# wrap-up-survey.sh - Pre-compute git state of all repos + session artifacts before wrap-up
# Outputs valid JSON to stdout, errors to stderr
# No external dependencies (no jq, no python)
#
# Repos are AUTO-DISCOVERED: every directory under $PROJECTS_DIR (default
# ~/GitProjects) that contains a .git directory is surveyed. To skip a repo,
# add its directory name to wrap-up-exclude.txt in this script's directory
# (one name per line, # comments allowed).

set -euo pipefail

# Start timing
START_TIME=$SECONDS

# Source environment variables (may set PROJECTS_DIR)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/env.sh" ]]; then
    source "$SCRIPT_DIR/env.sh"
fi

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/GitProjects}"
EXCLUDE_FILE="$SCRIPT_DIR/wrap-up-exclude.txt"

# get_repo_info runs in a command-substitution subshell, so it reports health
# facts through a temp file instead of shell globals. This keeps the git
# queries single-pass (the old script re-ran status and rev-list per repo in
# a second health loop).
HEALTH_TMP=$(mktemp)
trap 'rm -f "$HEALTH_TMP"' EXIT

# Function to escape JSON strings (strips control chars; BSD sed lacks \t)
json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\000-\037'
}

# Check the exclude list for a repo directory name.
# Single-pass read (no grep pipeline: pipefail + grep -q can SIGPIPE),
# tolerant of CRLF endings and surrounding whitespace.
is_excluded() {
    local name="$1" line
    [[ -f "$EXCLUDE_FILE" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        if [[ -z "$line" || "$line" == \#* ]]; then continue; fi
        if [[ "$line" == "$name" ]]; then return 0; fi
    done < "$EXCLUDE_FILE"
    return 1
}

# Function to get repo info
get_repo_info() {
    local name="$1"
    local path="$2"

    if [[ ! -d "$path/.git" ]]; then
        echo "  {\"name\":\"$name\",\"path\":\"$path\",\"error\":\"not a git repo\"}" >&2
        return
    fi

    # return 0 so a cd failure cannot abort the whole survey under set -e
    cd "$path" 2>/dev/null || return 0

    # Get branch (empty on detached HEAD, so fall back explicitly)
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    if [[ -z "$branch" ]]; then branch="detached"; fi

    # Get status. Any non-empty porcelain line means the repo is dirty:
    # ?? is untracked, everything else (M/A/D/R/C/T/U combos) counts as modified.
    local modified_files=()
    local untracked_files=()
    local clean=true

    while IFS= read -r line; do
        if [[ -z "$line" ]]; then continue; fi
        local status="${line:0:2}"
        local file="${line:3}"

        if [[ "$status" == "??" ]]; then
            untracked_files+=("$file")
            clean=false
        else
            modified_files+=("$file")
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

    # Report health facts to the parent shell (subshell-safe)
    printf '%s %s %s\n' "$clean" "$commits_ahead" "$commits_behind" >> "$HEALTH_TMP"

    # Build modified_files JSON array
    local modified_json="["
    local first=true
    if [[ ${#modified_files[@]} -gt 0 ]]; then
        for f in "${modified_files[@]}"; do
            if [[ "$first" == true ]]; then
                first=false
            else
                modified_json+=","
            fi
            modified_json+="\"$(json_escape "$f")\""
        done
    fi
    modified_json+="]"

    # Build untracked_files JSON array
    local untracked_json="["
    first=true
    if [[ ${#untracked_files[@]} -gt 0 ]]; then
        for f in "${untracked_files[@]}"; do
            if [[ "$first" == true ]]; then
                first=false
            else
                untracked_json+=","
            fi
            untracked_json+="\"$(json_escape "$f")\""
        done
    fi
    untracked_json+="]"

    # Output JSON object
    printf '    {\n'
    printf '      "name":"%s",\n' "$(json_escape "$name")"
    printf '      "path":"%s",\n' "$(json_escape "$path")"
    printf '      "branch":"%s",\n' "$(json_escape "$branch")"
    printf '      "clean":%s,\n' "$clean"
    printf '      "modified_files":%s,\n' "$modified_json"
    printf '      "untracked_files":%s,\n' "$untracked_json"
    printf '      "last_commit":"%s",\n' "$(json_escape "$last_commit")"
    printf '      "last_commit_date":"%s",\n' "$last_commit_date"
    printf '      "commits_ahead":%d,\n' "$commits_ahead"
    printf '      "commits_behind":%d\n' "$commits_behind"
    printf '    }'
}

# Get timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Begin JSON output
printf '{\n'
printf '  "timestamp":"%s",\n' "$TIMESTAMP"

# Auto-discover and survey repos
REPO_OUTPUT=""
for path in "$PROJECTS_DIR"/*/; do
    path="${path%/}"
    [[ -d "$path/.git" ]] || continue
    name="$(basename "$path")"

    if is_excluded "$name"; then
        echo "wrap-up-survey: skipping excluded repo $name" >&2
        continue
    fi

    repo_json=$(get_repo_info "$name" "$path") || repo_json=""
    if [[ -n "$repo_json" ]]; then
        if [[ -n "$REPO_OUTPUT" ]]; then
            REPO_OUTPUT+=$',\n'
        fi
        REPO_OUTPUT+="$repo_json"
    fi
done

echo '  "repos":['
printf '%s\n' "$REPO_OUTPUT"
echo '  ],'

# Compute health checks from the single-pass data
ALL_CLEAN=true
ANY_AHEAD=false
ANY_BEHIND=false
while IFS=' ' read -r r_clean r_ahead r_behind; do
    if [[ "$r_clean" == "false" ]]; then ALL_CLEAN=false; fi
    if [[ "$r_ahead" -gt 0 ]]; then ANY_AHEAD=true; fi
    if [[ "$r_behind" -gt 0 ]]; then ANY_BEHIND=true; fi
done < "$HEALTH_TMP"

# Session artifacts
TRANSCRIPT_COUNT=0
if [[ -d "$HOME/.claude/projects" ]]; then
    TRANSCRIPT_COUNT=$(find "$HOME/.claude/projects" -name "*.jsonl" 2>/dev/null | wc -l)
fi

TODO_COUNT=0
if [[ -d "$HOME/.claude/todos" ]]; then
    TODO_COUNT=$(find "$HOME/.claude/todos" -name "*.json" 2>/dev/null | wc -l)
fi

ACTIVITY_LOG="${ACTIVITY_LOG:-$PROJECTS_DIR/CJClaude_1/activity_log.txt}"
ACTIVITY_LOG_LINES=0
if [[ -f "$ACTIVITY_LOG" ]]; then
    ACTIVITY_LOG_LINES=$(wc -l < "$ACTIVITY_LOG" 2>/dev/null || echo 0)
fi

printf '  "session_artifacts":{\n'
printf '    "transcript_count":%d,\n' "$TRANSCRIPT_COUNT"
printf '    "todo_count":%d,\n' "$TODO_COUNT"
printf '    "activity_log_lines":%d\n' "$ACTIVITY_LOG_LINES"
printf '  },\n'

# Component change detection
MARKER="$HOME/.claude/.last-wrap-up-timestamp"
printf '  "component_changes":[\n'

COMP_FIRST=true
if [[ -f "$MARKER" ]]; then
    for comp_dir_type in "agents|Agent" "skills|Skill" "hooks|Hook" "commands|Command" "scripts|Script"; do
        dir="${comp_dir_type%%|*}"
        type="${comp_dir_type#*|}"
        comp_path="$HOME/.claude/$dir"
        [[ -d "$comp_path" ]] || continue

        while IFS= read -r filepath; do
            [[ -z "$filepath" ]] && continue
            # For skills, use parent dir name (e.g., wrap-up/SKILL.md -> wrap-up)
            if [[ "$type" == "Skill" ]]; then
                fname=$(basename "$(dirname "$filepath")")
            else
                fname=$(basename "$filepath" | sed 's/\.[^.]*$//')
            fi
            if [[ "$COMP_FIRST" == true ]]; then
                COMP_FIRST=false
            else
                printf ',\n'
            fi
            printf '    {"path":"%s","type":"%s","name":"%s"}' \
                "$(json_escape "$filepath")" "$type" "$(json_escape "$fname")"
        done < <(find "$comp_path" -maxdepth 2 -newer "$MARKER" -type f \
                    \( -name "*.sh" -o -name "*.md" -o -name "*.py" \) 2>/dev/null)
    done
fi

printf '\n  ],\n'

# Config drift detection
DRIFT_COUNT=0
CONFIG_REPO="${REPO_CONFIG:-$PROJECTS_DIR/claude-code-config}"
for check_dir in agents skills hooks commands scripts rules; do
    if [[ -d "$HOME/.claude/$check_dir" ]] && [[ -d "$CONFIG_REPO/$check_dir" ]]; then
        dir_drift=$(diff -rq "$HOME/.claude/$check_dir" "$CONFIG_REPO/$check_dir" 2>/dev/null | wc -l) || true
        DRIFT_COUNT=$((DRIFT_COUNT + dir_drift))
    fi
done

printf '  "config_drift":{"detected":%s,"file_count":%d},\n' \
    "$( [[ $DRIFT_COUNT -gt 0 ]] && echo true || echo false )" "$DRIFT_COUNT"

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
