#!/bin/bash

# blog-inventory.sh - Pre-compute blog post metadata from all MDX files
# Usage: bash blog-inventory.sh [--minimal]

set -euo pipefail

BLOG_ROOT="/c/ClaudeProjects/cryptoflexllc/src/content/blog"
MINIMAL=false

if [[ "${1:-}" == "--minimal" ]]; then
    MINIMAL=true
fi

# JSON escape helper
json_escape() {
    local str="$1"
    # Escape backslashes first, then quotes, then newlines/tabs
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

# Get ISO-8601 timestamp
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Parse frontmatter from MDX file
parse_frontmatter() {
    local file="$1"
    local field="$2"
    local in_frontmatter=false
    local frontmatter_lines=0
    local value=""

    while IFS= read -r line; do
        line="${line%$'\r'}"
        if [[ $frontmatter_lines -eq 0 && "$line" == "---" ]]; then
            in_frontmatter=true
            frontmatter_lines=$((frontmatter_lines + 1))
            continue
        fi

        if $in_frontmatter; then
            if [[ "$line" == "---" ]]; then
                break
            fi

            if [[ "$field" == "tags" && "$line" =~ ^tags:[[:space:]]*\[(.*)\] ]]; then
                value="${BASH_REMATCH[1]}"
                break
            elif [[ "$line" =~ ^${field}:[[:space:]]*(.*) ]]; then
                value="${BASH_REMATCH[1]}"
                # Strip surrounding quotes
                value="${value#\"}"
                value="${value%\"}"
                value="${value#\'}"
                value="${value%\'}"
                break
            fi
        fi
    done < "$file"

    echo "$value"
}

# Parse tags and return JSON array
parse_tags() {
    local tags_str="$1"
    local result="["
    local first=true

    # Split by comma
    IFS=',' read -ra tags <<< "$tags_str"
    for tag in "${tags[@]}"; do
        # Strip whitespace first, then quotes
        tag="$(echo "$tag" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        tag="${tag#\"}"
        tag="${tag%\"}"
        tag="${tag#\'}"
        tag="${tag%\'}"

        if [[ -n "$tag" ]]; then
            if ! $first; then
                result+=","
            fi
            result+="\"$(json_escape "$tag")\""
            first=false
        fi
    done

    result+="]"
    echo "$result"
}

# Check if directory exists
if [[ ! -d "$BLOG_ROOT" ]]; then
    echo "{\"error\":\"Blog directory not found\",\"path\":\"$BLOG_ROOT\",\"timestamp\":\"$(get_timestamp)\"}" >&2
    exit 0
fi

# Start JSON output
echo "{"
echo "  \"timestamp\": \"$(get_timestamp)\","
echo "  \"blog_root\": \"$BLOG_ROOT\","

# Count posts
post_count=$(find "$BLOG_ROOT" -maxdepth 1 -name "*.mdx" -type f 2>/dev/null | wc -l)
echo "  \"post_count\": $post_count,"
echo "  \"posts\": ["

# Process each MDX file
declare -A all_tags_map
total_word_count=0
latest_date=""
latest_post=""
first_post=true

# Create temporary file for sorting
tmpfile=$(mktemp)

while IFS= read -r file; do
    if [[ ! -f "$file" ]]; then
        continue
    fi

    filename=$(basename "$file")
    title=$(parse_frontmatter "$file" "title")
    date=$(parse_frontmatter "$file" "date")
    # Take only first 10 chars for date (YYYY-MM-DD)
    date="${date:0:10}"
    description=$(parse_frontmatter "$file" "description")
    tags_raw=$(parse_frontmatter "$file" "tags")

    # Get word and line counts
    word_count=$(wc -w < "$file" 2>/dev/null || echo 0)
    word_count=$((word_count - 30))  # Subtract frontmatter
    if [[ $word_count -lt 0 ]]; then word_count=0; fi

    line_count=$(wc -l < "$file" 2>/dev/null || echo 0)

    total_word_count=$((total_word_count + word_count))

    # Parse tags into array
    tags_json=$(parse_tags "$tags_raw")

    # Collect unique tags
    IFS=',' read -ra tag_arr <<< "$tags_raw"
    for tag in "${tag_arr[@]}"; do
        tag="$(echo "$tag" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        tag="${tag#\"}"
        tag="${tag%\"}"
        tag="${tag#\'}"
        tag="${tag%\'}"
        if [[ -n "$tag" ]]; then
            all_tags_map["$tag"]=1
        fi
    done

    # Track latest post
    if [[ -z "$latest_date" || "$date" > "$latest_date" ]]; then
        latest_date="$date"
        latest_post="$filename"
    fi

    # Write to temp file for sorting (date|filename|single-line-json)
    json_line="{\"filename\":\"$(json_escape "$filename")\",\"title\":\"$(json_escape "$title")\",\"date\":\"$date\",\"description\":\"$(json_escape "$description")\",\"tags\":$tags_json,\"word_count\":$word_count,\"line_count\":$line_count}"
    printf "%s|%s\n" "$date" "$json_line" >> "$tmpfile"

done < <(find "$BLOG_ROOT" -maxdepth 1 -name "*.mdx" -type f 2>/dev/null)

# Sort by date descending then output with proper comma separation
sorted=$(sort -t'|' -k1,1r "$tmpfile")
rm -f "$tmpfile"

first_entry=true
while IFS='|' read -r sort_date json_obj; do
    if ! $first_entry; then
        printf ",\n"
    fi
    printf "    %s" "$json_obj"
    first_entry=false
done <<< "$sorted"

echo ""
echo "  ]"

# Output metadata unless --minimal
if ! $MINIMAL; then
    echo "  ,"
    echo "  \"metadata\": {"
    echo "    \"latest_post\": \"$(json_escape "$latest_post")\","
    echo "    \"latest_date\": \"$latest_date\","

    # Output all tags sorted
    echo "    \"all_tags\": ["
    first_tag=true
    for tag in $(printf '%s\n' "${!all_tags_map[@]}" | sort); do
        if ! $first_tag; then
            echo ","
        fi
        echo -n "      \"$(json_escape "$tag")\""
        first_tag=false
    done
    echo ""
    echo "    ],"

    echo "    \"total_word_count\": $total_word_count"
    echo "  }"
fi

echo "}"

exit 0
