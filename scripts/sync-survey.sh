#!/bin/bash
# platform: macos
# sync-survey.sh - Bidirectional config inventory across 4 locations
# Outputs JSON manifest comparing live ~/.claude/, CJClaudin_Mac, CJClaude_1, claude-code-config
# Includes content hashes, file sizes, mtimes, and frontmatter platform fields

set -uo pipefail

# Source environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/env.sh" ]]; then
    source "$SCRIPT_DIR/env.sh"
fi

# Paths
LIVE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
MAC_REPO="${PROJECTS_DIR:-$HOME/GitProjects}/CJClaudin_Mac"
CJ1_REPO="${PROJECTS_DIR:-$HOME/GitProjects}/CJClaude_1"
CONFIG_REPO="${PROJECTS_DIR:-$HOME/GitProjects}/claude-code-config"

# Syncable directories (relative to each root)
SYNC_DIRS="agents commands rules scripts skills"

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | tr -d '\n'
}

# get_platform_field FILE
# Extracts platform: value from YAML frontmatter or shell comment
get_platform_field() {
    local file="$1"
    local ext="${file##*.}"

    if [[ "$ext" == "sh" || "$ext" == "ps1" || "$ext" == "py" ]]; then
        # Shell/Python: look for "# platform: <value>" in first 5 lines
        head -n5 "$file" 2>/dev/null | grep -m1 '^# platform:' | sed 's/^# platform:[[:space:]]*//' | tr -d '\n'
    elif [[ "$ext" == "md" ]]; then
        # Markdown: check for YAML frontmatter
        if head -n1 "$file" 2>/dev/null | grep -q '^---$'; then
            # Extract platform field from frontmatter
            sed -n '2,/^---$/p' "$file" 2>/dev/null | grep -m1 '^platform:' | sed 's/^platform:[[:space:]]*//' | tr -d '\n'
        fi
    fi
}

# scan_dir ROOT_DIR
# Outputs JSON array of file entries for syncable files under ROOT_DIR
scan_dir() {
    local root="$1"
    local first=true

    printf '['

    if [[ ! -d "$root" ]]; then
        printf ']'
        return
    fi

    for dir in $SYNC_DIRS; do
        local full_dir="$root/$dir"
        [[ ! -d "$full_dir" ]] && continue

        while IFS= read -r file; do
            [[ -z "$file" ]] && continue

            local rel="${file#$root/}"
            local hash
            hash=$(md5 -q "$file" 2>/dev/null || md5sum "$file" 2>/dev/null | cut -d' ' -f1)
            local size
            size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
            local mtime
            mtime=$(stat -f%m "$file" 2>/dev/null || stat -c%Y "$file" 2>/dev/null)
            local platform
            platform=$(get_platform_field "$file")

            if [[ "$first" == true ]]; then
                first=false
            else
                printf ','
            fi

            printf '{"path":"%s","hash":"%s","size":%s,"mtime":%s,"platform":"%s"}' \
                "$(json_escape "$rel")" \
                "$hash" \
                "${size:-0}" \
                "${mtime:-0}" \
                "$(json_escape "${platform:-}")"
        done < <(find "$full_dir" \( -name "*.md" -o -name "*.sh" -o -name "*.py" -o -name "*.ps1" \) \
            -type f ! -name "*.backup" ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null | sort)
    done

    printf ']'
}

# get_repo_status DIR
get_repo_status() {
    local dir="$1"

    if [[ ! -d "$dir/.git" ]]; then
        printf '"git":false'
        return
    fi

    local branch
    branch=$(cd "$dir" && git branch --show-current 2>/dev/null || echo "unknown")
    local changes
    changes=$(cd "$dir" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    local ahead=0
    if cd "$dir" && git rev-parse @{u} >/dev/null 2>&1; then
        ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null | tr -d ' ')
    fi

    printf '"git":true,"branch":"%s","uncommitted":%d,"ahead":%d' \
        "$branch" "$changes" "$ahead"
}

# compare_file_lists
# Takes two JSON arrays (as temp files) and produces diff
# Uses associative arrays for O(n) comparison
compare_locations() {
    local live_files="$1"
    local target_files="$2"
    local target_name="$3"

    # Build associative arrays from file lists
    # Parse JSON arrays with grep/sed (no jq dependency)
    declare -A live_hashes target_hashes
    declare -a all_paths

    # Extract path:hash pairs from live
    while IFS='|' read -r path hash; do
        [[ -z "$path" ]] && continue
        live_hashes["$path"]="$hash"
        all_paths+=("$path")
    done < <(echo "$live_files" | grep -o '"path":"[^"]*","hash":"[^"]*"' | sed 's/"path":"//;s/","hash":"/|/;s/"$//')

    # Extract path:hash pairs from target
    while IFS='|' read -r path hash; do
        [[ -z "$path" ]] && continue
        target_hashes["$path"]="$hash"
        # Add to all_paths if not already present
        if [[ -z "${live_hashes[$path]+x}" ]]; then
            all_paths+=("$path")
        fi
    done < <(echo "$target_files" | grep -o '"path":"[^"]*","hash":"[^"]*"' | sed 's/"path":"//;s/","hash":"/|/;s/"$//')

    # Classify each path
    local new_in_live=() new_in_target=() diverged=() identical=()

    for path in "${all_paths[@]}"; do
        local in_live="${live_hashes[$path]+yes}"
        local in_target="${target_hashes[$path]+yes}"

        if [[ "$in_live" == "yes" && "$in_target" != "yes" ]]; then
            new_in_live+=("$path")
        elif [[ "$in_live" != "yes" && "$in_target" == "yes" ]]; then
            new_in_target+=("$path")
        elif [[ "${live_hashes[$path]}" != "${target_hashes[$path]}" ]]; then
            diverged+=("$path")
        else
            identical+=("$path")
        fi
    done

    # Output as JSON
    printf '"new_in_live":['
    local first=true
    for p in "${new_in_live[@]+"${new_in_live[@]}"}"; do
        [[ "$first" == true ]] && first=false || printf ','
        printf '"%s"' "$(json_escape "$p")"
    done
    printf '],"new_in_%s":[' "$target_name"
    first=true
    for p in "${new_in_target[@]+"${new_in_target[@]}"}"; do
        [[ "$first" == true ]] && first=false || printf ','
        printf '"%s"' "$(json_escape "$p")"
    done
    printf '],"diverged":['
    first=true
    for p in "${diverged[@]+"${diverged[@]}"}"; do
        [[ "$first" == true ]] && first=false || printf ','
        printf '"%s"' "$(json_escape "$p")"
    done
    printf '],"identical":['
    first=true
    for p in "${identical[@]+"${identical[@]}"}"; do
        [[ "$first" == true ]] && first=false || printf ','
        printf '"%s"' "$(json_escape "$p")"
    done
    printf ']'
}

# ================================================================
# MAIN
# ================================================================

# Scan all locations
live_scan=$(scan_dir "$LIVE_DIR")
mac_scan=$(scan_dir "$MAC_REPO")
cj1_scan=$(scan_dir "$CJ1_REPO")
config_scan=$(scan_dir "$CONFIG_REPO")

# Output JSON
printf '{\n'
printf '  "timestamp":"%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Repos section
printf '  "repos":{\n'

printf '    "live":{"path":"%s",%s,"files":%s},\n' \
    "$(json_escape "$LIVE_DIR")" \
    "$(printf '"git":false')" \
    "$live_scan"

printf '    "mac":{"path":"%s",%s,"files":%s},\n' \
    "$(json_escape "$MAC_REPO")" \
    "$(get_repo_status "$MAC_REPO")" \
    "$mac_scan"

printf '    "cj1":{"path":"%s",%s,"files":%s},\n' \
    "$(json_escape "$CJ1_REPO")" \
    "$(get_repo_status "$CJ1_REPO")" \
    "$cj1_scan"

printf '    "config":{"path":"%s",%s,"files":%s}\n' \
    "$(json_escape "$CONFIG_REPO")" \
    "$(get_repo_status "$CONFIG_REPO")" \
    "$config_scan"

printf '  },\n'

# Diff section: compare live against each repo
printf '  "diff":{\n'

printf '    "vs_mac":{%s},\n' "$(compare_locations "$live_scan" "$mac_scan" "mac")"
printf '    "vs_cj1":{%s},\n' "$(compare_locations "$live_scan" "$cj1_scan" "cj1")"
printf '    "vs_config":{%s}\n' "$(compare_locations "$live_scan" "$config_scan" "config")"

printf '  }\n'
printf '}\n'

exit 0
