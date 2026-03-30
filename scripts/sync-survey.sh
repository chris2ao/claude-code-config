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
# Uses temp files for bash 3 compatibility (no associative arrays)
compare_locations() {
    local live_files="$1"
    local target_files="$2"
    local target_name="$3"

    local tmp_live=$(mktemp)
    local tmp_target=$(mktemp)

    # Extract path|hash pairs from live
    echo "$live_files" | grep -o '"path":"[^"]*","hash":"[^"]*"' | sed 's/"path":"//;s/","hash":"/|/;s/"$//' | sort > "$tmp_live"

    # Extract path|hash pairs from target
    echo "$target_files" | grep -o '"path":"[^"]*","hash":"[^"]*"' | sed 's/"path":"//;s/","hash":"/|/;s/"$//' | sort > "$tmp_target"

    # Extract just paths for set operations
    local tmp_live_paths=$(mktemp)
    local tmp_target_paths=$(mktemp)
    cut -d'|' -f1 "$tmp_live" | sort > "$tmp_live_paths"
    cut -d'|' -f1 "$tmp_target" | sort > "$tmp_target_paths"

    # New in live (paths in live but not target)
    local tmp_new_live=$(mktemp)
    comm -23 "$tmp_live_paths" "$tmp_target_paths" > "$tmp_new_live"

    # New in target (paths in target but not live)
    local tmp_new_target=$(mktemp)
    comm -13 "$tmp_live_paths" "$tmp_target_paths" > "$tmp_new_target"

    # Common paths (in both)
    local tmp_common=$(mktemp)
    comm -12 "$tmp_live_paths" "$tmp_target_paths" > "$tmp_common"

    # For common paths, check if hashes diverge
    local tmp_diverged=$(mktemp)
    local tmp_identical=$(mktemp)
    while IFS= read -r path; do
        [[ -z "$path" ]] && continue
        local live_hash=$(grep "^${path}|" "$tmp_live" | head -1 | cut -d'|' -f2)
        local target_hash=$(grep "^${path}|" "$tmp_target" | head -1 | cut -d'|' -f2)
        if [[ "$live_hash" != "$target_hash" ]]; then
            echo "$path" >> "$tmp_diverged"
        else
            echo "$path" >> "$tmp_identical"
        fi
    done < "$tmp_common"

    # Output as JSON
    printf '"new_in_live":['
    local first=true
    while IFS= read -r p; do
        [[ -z "$p" ]] && continue
        [[ "$first" == true ]] && first=false || printf ','
        printf '"%s"' "$(json_escape "$p")"
    done < "$tmp_new_live"
    printf '],"new_in_%s":[' "$target_name"
    first=true
    while IFS= read -r p; do
        [[ -z "$p" ]] && continue
        [[ "$first" == true ]] && first=false || printf ','
        printf '"%s"' "$(json_escape "$p")"
    done < "$tmp_new_target"
    printf '],"diverged":['
    first=true
    if [[ -f "$tmp_diverged" ]]; then
        while IFS= read -r p; do
            [[ -z "$p" ]] && continue
            [[ "$first" == true ]] && first=false || printf ','
            printf '"%s"' "$(json_escape "$p")"
        done < "$tmp_diverged"
    fi
    printf '],"identical":['
    first=true
    if [[ -f "$tmp_identical" ]]; then
        while IFS= read -r p; do
            [[ -z "$p" ]] && continue
            [[ "$first" == true ]] && first=false || printf ','
            printf '"%s"' "$(json_escape "$p")"
        done < "$tmp_identical"
    fi
    printf ']'

    # Cleanup
    rm -f "$tmp_live" "$tmp_target" "$tmp_live_paths" "$tmp_target_paths" "$tmp_new_live" "$tmp_new_target" "$tmp_common" "$tmp_diverged" "$tmp_identical"
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
