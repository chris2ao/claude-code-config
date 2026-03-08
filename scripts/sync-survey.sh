#!/bin/bash
# sync-survey.sh - Compare live ~/.claude/ against config repos
# Outputs valid JSON to stdout, errors to stderr
# No external dependencies (no jq, no python)

set -euo pipefail

# Paths (MSYS2 format for Git Bash on Windows)
CLAUDE_DIR="$HOME/.claude"
CONFIG_REPO="C:/ClaudeProjects/claude-code-config"
HOME_REPO="C:/ClaudeProjects/CJClaudin_home"
PROJECT_DIR="C:/ClaudeProjects/CJClaude_1"

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n'
}

# json_array ARRAY_NAME - prints JSON array of strings from a bash array
json_array() {
    local -n arr=$1
    printf '['
    local first=true
    for item in "${arr[@]+"${arr[@]}"}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            printf ','
        fi
        printf '"%s"' "$(json_escape "$item")"
    done
    printf ']'
}

# get_repo_status DIR - prints branch, requires_commit, requires_push, commits_ahead
get_repo_status() {
    local dir="$1"
    local branch="unknown"
    local requires_commit=false
    local requires_push=false
    local commits_ahead=0

    if [[ ! -d "$dir/.git" ]]; then
        printf '"exists":false,"branch":"none","requires_commit":false,"requires_push":false,"commits_ahead":0'
        return
    fi

    branch=$(cd "$dir" && git branch --show-current 2>/dev/null || echo "unknown")

    local changes
    changes=$(cd "$dir" && git status --porcelain 2>/dev/null | wc -l || echo 0)
    changes=$(echo "$changes" | tr -d ' ')
    if [[ "$changes" -gt 0 ]]; then
        requires_commit=true
    fi

    if cd "$dir" && git rev-parse @{u} >/dev/null 2>&1; then
        commits_ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
        commits_ahead=$(echo "$commits_ahead" | tr -d ' ')
        if [[ "$commits_ahead" -gt 0 ]]; then
            requires_push=true
        fi
    fi

    printf '"exists":true,"branch":"%s","requires_commit":%s,"requires_push":%s,"commits_ahead":%d' \
        "$branch" "$requires_commit" "$requires_push" "$commits_ahead"
}

# compare_trees SRC DST
# Finds all .md and .sh files recursively (excluding .backup, .git)
# Populates global arrays: CMP_NEW, CMP_MOD, CMP_DEL and counter CMP_UNCHANGED
compare_trees() {
    local src="$1"
    local dst="$2"

    CMP_NEW=()
    CMP_MOD=()
    CMP_DEL=()
    CMP_UNCHANGED=0

    if [[ ! -d "$src" ]]; then return; fi

    # Source files -> check against dest
    while IFS= read -r src_file; do
        [[ -z "$src_file" ]] && continue
        local rel="${src_file#$src/}"
        local dst_file="$dst/$rel"

        if [[ ! -f "$dst_file" ]]; then
            CMP_NEW+=("$rel")
        elif ! diff -q "$src_file" "$dst_file" >/dev/null 2>&1; then
            CMP_MOD+=("$rel")
        else
            CMP_UNCHANGED=$((CMP_UNCHANGED + 1))
        fi
    done < <(find "$src" \( -name "*.md" -o -name "*.sh" -o -name "*.json" \) \
        -type f ! -name "*.backup" ! -path "*/.git/*" 2>/dev/null || true)

    # Dest files not in source (deleted from source perspective)
    if [[ -d "$dst" ]]; then
        while IFS= read -r dst_file; do
            [[ -z "$dst_file" ]] && continue
            local rel="${dst_file#$dst/}"
            local src_file="$src/$rel"

            if [[ ! -f "$src_file" ]]; then
                CMP_DEL+=("$rel")
            fi
        done < <(find "$dst" \( -name "*.md" -o -name "*.sh" -o -name "*.json" \) \
            -type f ! -name "*.backup" ! -path "*/.git/*" 2>/dev/null || true)
    fi
}

# compare_flat SRC_DIR DST_DIR EXTENSION
# Compares files with a specific extension in two flat directories (no recursion)
compare_flat() {
    local src="$1" dst="$2" ext="$3"

    CMP_NEW=()
    CMP_MOD=()
    CMP_DEL=()
    CMP_UNCHANGED=0

    if [[ ! -d "$src" ]]; then return; fi

    for src_file in "$src"/*."$ext"; do
        [[ ! -f "$src_file" ]] && continue
        local name
        name=$(basename "$src_file")
        local dst_file="$dst/$name"

        if [[ ! -f "$dst_file" ]]; then
            CMP_NEW+=("$name")
        elif ! diff -q "$src_file" "$dst_file" >/dev/null 2>&1; then
            CMP_MOD+=("$name")
        else
            CMP_UNCHANGED=$((CMP_UNCHANGED + 1))
        fi
    done

    if [[ -d "$dst" ]]; then
        for dst_file in "$dst"/*."$ext"; do
            [[ ! -f "$dst_file" ]] && continue
            local name
            name=$(basename "$dst_file")
            if [[ ! -f "$src/$name" ]]; then
                CMP_DEL+=("$name")
            fi
        done
    fi
}

# ================================================================
# CLAUDE-CODE-CONFIG DRIFT
# ================================================================

# Accumulate all drift for config repo
CONFIG_NEW=()
CONFIG_MOD=()
CONFIG_DEL=()
CONFIG_UNCHANGED=0

# Rules (prefix with rules/)
compare_trees "$CLAUDE_DIR/rules" "$CONFIG_REPO/rules"
for f in "${CMP_NEW[@]+"${CMP_NEW[@]}"}"; do CONFIG_NEW+=("rules/$f"); done
for f in "${CMP_MOD[@]+"${CMP_MOD[@]}"}"; do CONFIG_MOD+=("rules/$f"); done
for f in "${CMP_DEL[@]+"${CMP_DEL[@]}"}"; do CONFIG_DEL+=("rules/$f"); done
CONFIG_UNCHANGED=$((CONFIG_UNCHANGED + CMP_UNCHANGED))

# Agents
compare_flat "$CLAUDE_DIR/agents" "$CONFIG_REPO/agents" "md"
for f in "${CMP_NEW[@]+"${CMP_NEW[@]}"}"; do CONFIG_NEW+=("agents/$f"); done
for f in "${CMP_MOD[@]+"${CMP_MOD[@]}"}"; do CONFIG_MOD+=("agents/$f"); done
for f in "${CMP_DEL[@]+"${CMP_DEL[@]}"}"; do CONFIG_DEL+=("agents/$f"); done
CONFIG_UNCHANGED=$((CONFIG_UNCHANGED + CMP_UNCHANGED))

# Skills (prefix with skills/)
compare_trees "$CLAUDE_DIR/skills" "$CONFIG_REPO/skills"
for f in "${CMP_NEW[@]+"${CMP_NEW[@]}"}"; do CONFIG_NEW+=("skills/$f"); done
for f in "${CMP_MOD[@]+"${CMP_MOD[@]}"}"; do CONFIG_MOD+=("skills/$f"); done
for f in "${CMP_DEL[@]+"${CMP_DEL[@]}"}"; do CONFIG_DEL+=("skills/$f"); done
CONFIG_UNCHANGED=$((CONFIG_UNCHANGED + CMP_UNCHANGED))

# Commands
compare_flat "$CLAUDE_DIR/commands" "$CONFIG_REPO/commands" "md"
for f in "${CMP_NEW[@]+"${CMP_NEW[@]}"}"; do CONFIG_NEW+=("commands/$f"); done
for f in "${CMP_MOD[@]+"${CMP_MOD[@]}"}"; do CONFIG_MOD+=("commands/$f"); done
for f in "${CMP_DEL[@]+"${CMP_DEL[@]}"}"; do CONFIG_DEL+=("commands/$f"); done
CONFIG_UNCHANGED=$((CONFIG_UNCHANGED + CMP_UNCHANGED))

# Scripts
compare_flat "$CLAUDE_DIR/scripts" "$CONFIG_REPO/scripts" "sh"
for f in "${CMP_NEW[@]+"${CMP_NEW[@]}"}"; do CONFIG_NEW+=("scripts/$f"); done
for f in "${CMP_MOD[@]+"${CMP_MOD[@]}"}"; do CONFIG_MOD+=("scripts/$f"); done
for f in "${CMP_DEL[@]+"${CMP_DEL[@]}"}"; do CONFIG_DEL+=("scripts/$f"); done
CONFIG_UNCHANGED=$((CONFIG_UNCHANGED + CMP_UNCHANGED))

CONFIG_DRIFT=$(( ${#CONFIG_NEW[@]} + ${#CONFIG_MOD[@]} + ${#CONFIG_DEL[@]} ))

# ================================================================
# CJCLAUDIN_HOME DRIFT
# ================================================================

HOME_NEW=()
HOME_MOD=()
HOME_DEL=()
HOME_UNCHANGED=0

# Rules -> payload/rules (prefix with payload/rules/)
compare_trees "$CLAUDE_DIR/rules" "$HOME_REPO/payload/rules"
for f in "${CMP_NEW[@]+"${CMP_NEW[@]}"}"; do HOME_NEW+=("payload/rules/$f"); done
for f in "${CMP_MOD[@]+"${CMP_MOD[@]}"}"; do HOME_MOD+=("payload/rules/$f"); done
for f in "${CMP_DEL[@]+"${CMP_DEL[@]}"}"; do HOME_DEL+=("payload/rules/$f"); done
HOME_UNCHANGED=$((HOME_UNCHANGED + CMP_UNCHANGED))

# Agents -> payload/agents
compare_flat "$CLAUDE_DIR/agents" "$HOME_REPO/payload/agents" "md"
for f in "${CMP_NEW[@]+"${CMP_NEW[@]}"}"; do HOME_NEW+=("payload/agents/$f"); done
for f in "${CMP_MOD[@]+"${CMP_MOD[@]}"}"; do HOME_MOD+=("payload/agents/$f"); done
for f in "${CMP_DEL[@]+"${CMP_DEL[@]}"}"; do HOME_DEL+=("payload/agents/$f"); done
HOME_UNCHANGED=$((HOME_UNCHANGED + CMP_UNCHANGED))

# Skills -> payload/skills (prefix with payload/skills/)
compare_trees "$CLAUDE_DIR/skills" "$HOME_REPO/payload/skills"
for f in "${CMP_NEW[@]+"${CMP_NEW[@]}"}"; do HOME_NEW+=("payload/skills/$f"); done
for f in "${CMP_MOD[@]+"${CMP_MOD[@]}"}"; do HOME_MOD+=("payload/skills/$f"); done
for f in "${CMP_DEL[@]+"${CMP_DEL[@]}"}"; do HOME_DEL+=("payload/skills/$f"); done
HOME_UNCHANGED=$((HOME_UNCHANGED + CMP_UNCHANGED))

# Commands -> payload/commands
compare_flat "$CLAUDE_DIR/commands" "$HOME_REPO/payload/commands" "md"
for f in "${CMP_NEW[@]+"${CMP_NEW[@]}"}"; do HOME_NEW+=("payload/commands/$f"); done
for f in "${CMP_MOD[@]+"${CMP_MOD[@]}"}"; do HOME_MOD+=("payload/commands/$f"); done
for f in "${CMP_DEL[@]+"${CMP_DEL[@]}"}"; do HOME_DEL+=("payload/commands/$f"); done
HOME_UNCHANGED=$((HOME_UNCHANGED + CMP_UNCHANGED))

# Scripts -> payload/scripts
compare_flat "$CLAUDE_DIR/scripts" "$HOME_REPO/payload/scripts" "sh"
for f in "${CMP_NEW[@]+"${CMP_NEW[@]}"}"; do HOME_NEW+=("payload/scripts/$f"); done
for f in "${CMP_MOD[@]+"${CMP_MOD[@]}"}"; do HOME_MOD+=("payload/scripts/$f"); done
for f in "${CMP_DEL[@]+"${CMP_DEL[@]}"}"; do HOME_DEL+=("payload/scripts/$f"); done
HOME_UNCHANGED=$((HOME_UNCHANGED + CMP_UNCHANGED))

# Homunculus instincts -> payload/homunculus/instincts
compare_trees "$CLAUDE_DIR/homunculus/instincts" "$HOME_REPO/payload/homunculus/instincts"
for f in "${CMP_NEW[@]+"${CMP_NEW[@]}"}"; do HOME_NEW+=("payload/homunculus/instincts/$f"); done
for f in "${CMP_MOD[@]+"${CMP_MOD[@]}"}"; do HOME_MOD+=("payload/homunculus/instincts/$f"); done
for f in "${CMP_DEL[@]+"${CMP_DEL[@]}"}"; do HOME_DEL+=("payload/homunculus/instincts/$f"); done
HOME_UNCHANGED=$((HOME_UNCHANGED + CMP_UNCHANGED))

# Windows hooks -> hooks/windows
compare_flat "$PROJECT_DIR/.claude/hooks" "$HOME_REPO/hooks/windows" "ps1"
for f in "${CMP_NEW[@]+"${CMP_NEW[@]}"}"; do HOME_NEW+=("hooks/windows/$f"); done
for f in "${CMP_MOD[@]+"${CMP_MOD[@]}"}"; do HOME_MOD+=("hooks/windows/$f"); done
for f in "${CMP_DEL[@]+"${CMP_DEL[@]}"}"; do HOME_DEL+=("hooks/windows/$f"); done
HOME_UNCHANGED=$((HOME_UNCHANGED + CMP_UNCHANGED))

HOME_DRIFT=$(( ${#HOME_NEW[@]} + ${#HOME_MOD[@]} + ${#HOME_DEL[@]} ))

# ================================================================
# JSON OUTPUT
# ================================================================

TOTAL_DRIFT=$((CONFIG_DRIFT + HOME_DRIFT))
if [[ $TOTAL_DRIFT -eq 0 ]]; then
    SUMMARY_MSG="All files in sync"
else
    SUMMARY_MSG="$TOTAL_DRIFT files out of sync"
fi

printf '{\n'

# config_repo section
printf '  "config_repo":{\n'
printf '    "path":"%s",\n' "$(json_escape "$CONFIG_REPO")"
printf '    %s,\n' "$(get_repo_status "$CONFIG_REPO")"
printf '    "new":%s,\n' "$(json_array CONFIG_NEW)"
printf '    "modified":%s,\n' "$(json_array CONFIG_MOD)"
printf '    "deleted":%s,\n' "$(json_array CONFIG_DEL)"
printf '    "unchanged_count":%d,\n' "$CONFIG_UNCHANGED"
printf '    "drift_count":%d\n' "$CONFIG_DRIFT"
printf '  },\n'

# home_repo section
printf '  "home_repo":{\n'
printf '    "path":"%s",\n' "$(json_escape "$HOME_REPO")"
printf '    %s,\n' "$(get_repo_status "$HOME_REPO")"
printf '    "new":%s,\n' "$(json_array HOME_NEW)"
printf '    "modified":%s,\n' "$(json_array HOME_MOD)"
printf '    "deleted":%s,\n' "$(json_array HOME_DEL)"
printf '    "unchanged_count":%d,\n' "$HOME_UNCHANGED"
printf '    "drift_count":%d\n' "$HOME_DRIFT"
printf '  },\n'

# summary
printf '  "summary":{\n'
printf '    "config_drift":%d,\n' "$CONFIG_DRIFT"
printf '    "home_drift":%d,\n' "$HOME_DRIFT"
printf '    "total_drift":%d,\n' "$TOTAL_DRIFT"
printf '    "message":"%s"\n' "$(json_escape "$SUMMARY_MSG")"
printf '  }\n'

printf '}\n'

exit 0
