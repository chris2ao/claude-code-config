#!/bin/bash
# platform: macos

# validate-mdx.sh - Validate a single MDX blog post file
# Usage: bash validate-mdx.sh <path-to-file.mdx>

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "{\"error\":\"Usage: validate-mdx.sh <path-to-file.mdx>\",\"timestamp\":\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}" >&2
    exit 1
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
    echo "{\"error\":\"File not found\",\"path\":\"$FILE\",\"timestamp\":\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}" >&2
    exit 1
fi

# JSON escape helper
json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Initialize variables
FILENAME=$(basename "$FILE")
FILEPATH=$(realpath "$FILE" 2>/dev/null || echo "$FILE")
VALID=true
WARNINGS=()
ERRORS=()

# Check 1: Frontmatter present
frontmatter_present=false
frontmatter_complete=false
missing_fields=()
required_fields=("title" "date" "description" "tags")

line_num=0
in_frontmatter=false
frontmatter_count=0
found_fields=()

while IFS= read -r line; do
    line="${line%$'\r'}"
    line_num=$((line_num + 1))

    if [[ $line_num -eq 1 && "$line" == "---" ]]; then
        in_frontmatter=true
        frontmatter_count=$((frontmatter_count + 1))
        continue
    fi

    if $in_frontmatter; then
        if [[ "$line" == "---" ]]; then
            frontmatter_count=$((frontmatter_count + 1))
            frontmatter_present=true
            break
        fi

        for field in "${required_fields[@]}"; do
            if [[ "$line" =~ ^${field}: ]]; then
                found_fields+=("$field")
            fi
        done
    fi
done < "$FILE"

for field in "${required_fields[@]}"; do
    if [[ ! " ${found_fields[*]:-} " =~ " ${field} " ]]; then
        missing_fields+=("$field")
    fi
done

if [[ ${#missing_fields[@]} -eq 0 ]]; then
    frontmatter_complete=true
fi

# Check 2: Em dashes (outside code blocks)
em_dash_count=0
em_dash_lines=()
in_code_block=false

line_num=0
while IFS= read -r line; do
    line_num=$((line_num + 1))

    # Toggle code block state
    if [[ "$line" =~ ^\`\`\` ]]; then
        if $in_code_block; then
            in_code_block=false
        else
            in_code_block=true
        fi
        continue
    fi

    # Skip if in code block
    if $in_code_block; then
        continue
    fi

    # Check for em dash (U+2014: —)
    if [[ "$line" =~ — ]]; then
        em_dash_count=$((em_dash_count + 1))
        em_dash_lines+=($line_num)
    fi
done < "$FILE"

# Check 3: Code blocks with language tags
code_block_count=0
missing_language=()

line_num=0
while IFS= read -r line; do
    line_num=$((line_num + 1))

    if [[ "$line" =~ ^\`\`\`([a-zA-Z0-9_+-]*) ]]; then
        code_block_count=$((code_block_count + 1))
        lang="${BASH_REMATCH[1]}"
        if [[ -z "$lang" ]]; then
            missing_language+=($line_num)
        fi
    fi
done < "$FILE"

# Check 4: Duplicate GIF detection
duplicate_gifs=()
all_gif_urls=""
line_num=0
while IFS= read -r line; do
    line_num=$((line_num + 1))
    # Extract giphy URLs
    while [[ "$line" =~ (https://media\.giphy\.com/media/[^/]+/giphy\.gif) ]]; do
        url="${BASH_REMATCH[1]}"
        if echo "$all_gif_urls" | grep -qF "$url"; then
            duplicate_gifs+=("$line_num:$url")
        else
            all_gif_urls="${all_gif_urls}${url}"$'\n'
        fi
        line="${line#*"$url"}"
    done
done < "$FILE"

# Check 5: Callout count threshold
callout_count=0
for ctype in Tip Info Warning Stop Security; do
    count=$(grep -c "<${ctype}" "$FILE" 2>/dev/null || true)
    count=${count:-0}
    callout_count=$((callout_count + count))
done

# Check 6: Heading hierarchy (no skipped levels)
heading_hierarchy_errors=()
prev_level=0
line_num=0
while IFS= read -r line; do
    line_num=$((line_num + 1))
    if [[ "$line" =~ ^(#{2,6})[[:space:]] ]]; then
        hashes="${BASH_REMATCH[1]}"
        level=${#hashes}
        if [[ $prev_level -gt 0 && $level -gt $((prev_level + 1)) ]]; then
            heading_hierarchy_errors+=("$line_num:H${prev_level}->H${level}")
        fi
        prev_level=$level
    fi
done < "$FILE"

# Check 7: Private repo link detection
private_repo_links=()
line_num=0
while IFS= read -r line; do
    line_num=$((line_num + 1))
    # Match github.com/chris2ao/ links that are NOT the two public repos
    if echo "$line" | grep -qE 'github\.com/chris2ao/' ; then
        if ! echo "$line" | grep -qE 'github\.com/chris2ao/(cryptoflexllc|claude-code-config)(\s|/|"|'"'"'|\)|$)'; then
            private_repo_links+=($line_num)
        fi
    fi
done < "$FILE"

# Check 8: Callout component closure
unclosed_callouts=()
for ctype in Tip Info Warning Stop Security; do
    open_count=$(grep -c "<${ctype}" "$FILE" 2>/dev/null || true); open_count=${open_count:-0}
    close_count=$(grep -c "</${ctype}>" "$FILE" 2>/dev/null || true); close_count=${close_count:-0}
    if [[ $open_count -ne $close_count ]]; then
        unclosed_callouts+=("${ctype}:open=${open_count},close=${close_count}")
    fi
done

# Check 9: Alt text for images
missing_alt=()

line_num=0
while IFS= read -r line; do
    line_num=$((line_num + 1))

    # Find markdown images: ![alt](url)
    while [[ "$line" =~ !\[([^\]]*)\]\([^\)]+\) ]]; do
        alt="${BASH_REMATCH[1]}"
        if [[ -z "$alt" ]]; then
            missing_alt+=($line_num)
        fi
        # Remove matched part to continue searching
        line="${line#*\]\(}"
    done
done < "$FILE"

# Metadata calculations
total_lines=$(wc -l < "$FILE" 2>/dev/null || echo 0)
total_words=$(wc -w < "$FILE" 2>/dev/null || echo 0)
word_count=$((total_words - 30))
if [[ $word_count -lt 0 ]]; then word_count=0; fi

reading_time=$(( (word_count + 199) / 200 ))

heading_count=$(grep -c '^#' "$FILE" 2>/dev/null || true); heading_count=${heading_count:-0}
image_count=$(grep -o '!\[' "$FILE" 2>/dev/null | wc -l | tr -d ' ' || true); image_count=${image_count:-0}
link_count=$(grep -o '](' "$FILE" 2>/dev/null | wc -l | tr -d ' ' || true); link_count=${link_count:-0}
link_count=$((link_count - image_count))

# Build check results
passed_checks=0
failed_checks=0

# frontmatter_present
if $frontmatter_present; then
    passed_checks=$((passed_checks + 1))
    fm_present_pass=true
    fm_present_msg="Frontmatter found"
else
    failed_checks=$((failed_checks + 1))
    fm_present_pass=false
    fm_present_msg="Frontmatter missing or malformed"
    ERRORS+=("Frontmatter not found")
    VALID=false
fi

# frontmatter_complete
if $frontmatter_complete; then
    passed_checks=$((passed_checks + 1))
    fm_complete_pass=true
    fm_complete_msg="All required fields present"
else
    failed_checks=$((failed_checks + 1))
    fm_complete_pass=false
    fm_complete_msg="Missing required fields"
    ERRORS+=("Missing fields: ${missing_fields[*]:-}")
    VALID=false
fi

# em_dashes
if [[ $em_dash_count -eq 0 ]]; then
    passed_checks=$((passed_checks + 1))
    em_dash_pass=true
    em_dash_msg="No em dashes found"
else
    failed_checks=$((failed_checks + 1))
    em_dash_pass=false
    em_dash_msg="Em dashes found on lines: ${em_dash_lines[*]:-}"
    ERRORS+=("Em dashes found on lines: ${em_dash_lines[*]:-}")
    VALID=false
fi

# code_blocks
if [[ ${#missing_language[@]} -eq 0 ]]; then
    passed_checks=$((passed_checks + 1))
    code_blocks_pass=true
    code_blocks_msg="All code blocks have language tags"
else
    passed_checks=$((passed_checks + 1))
    code_blocks_pass=true
    code_blocks_msg="Some code blocks missing language tags"
    WARNINGS+=("Code blocks missing language on lines: ${missing_language[*]:-}")
fi

# alt_text
if [[ ${#missing_alt[@]} -eq 0 ]]; then
    passed_checks=$((passed_checks + 1))
    alt_text_pass=true
    alt_text_msg="All images have alt text"
else
    passed_checks=$((passed_checks + 1))
    alt_text_pass=true
    alt_text_msg="Some images missing alt text"
    WARNINGS+=("Images missing alt text on lines: ${missing_alt[*]:-}")
fi

# duplicate_gifs
if [[ ${#duplicate_gifs[@]} -eq 0 ]]; then
    passed_checks=$((passed_checks + 1))
    dup_gif_pass=true
    dup_gif_msg="No duplicate GIFs"
else
    failed_checks=$((failed_checks + 1))
    dup_gif_pass=false
    dup_gif_msg="Duplicate GIFs found"
    ERRORS+=("Duplicate GIFs: ${duplicate_gifs[*]:-}")
    VALID=false
fi

# callout_count
if [[ $callout_count -ge 3 ]]; then
    passed_checks=$((passed_checks + 1))
    callout_threshold_pass=true
    callout_threshold_msg="$callout_count callouts (minimum 3)"
else
    passed_checks=$((passed_checks + 1))
    callout_threshold_pass=true
    callout_threshold_msg="Only $callout_count callouts (recommend 3+)"
    WARNINGS+=("Low callout count: $callout_count (recommend 3+)")
fi

# heading_hierarchy
if [[ ${#heading_hierarchy_errors[@]} -eq 0 ]]; then
    passed_checks=$((passed_checks + 1))
    heading_hier_pass=true
    heading_hier_msg="Heading hierarchy valid"
else
    failed_checks=$((failed_checks + 1))
    heading_hier_pass=false
    heading_hier_msg="Skipped heading levels: ${heading_hierarchy_errors[*]:-}"
    ERRORS+=("Heading hierarchy: ${heading_hierarchy_errors[*]:-}")
    VALID=false
fi

# private_repo_links
if [[ ${#private_repo_links[@]} -eq 0 ]]; then
    passed_checks=$((passed_checks + 1))
    private_links_pass=true
    private_links_msg="No private repo links"
else
    failed_checks=$((failed_checks + 1))
    private_links_pass=false
    private_links_msg="Private repo links on lines: ${private_repo_links[*]:-}"
    ERRORS+=("Private repo links on lines: ${private_repo_links[*]:-}")
    VALID=false
fi

# unclosed_callouts
if [[ ${#unclosed_callouts[@]} -eq 0 ]]; then
    passed_checks=$((passed_checks + 1))
    callout_closure_pass=true
    callout_closure_msg="All callouts properly closed"
else
    failed_checks=$((failed_checks + 1))
    callout_closure_pass=false
    callout_closure_msg="Unclosed callouts: ${unclosed_callouts[*]:-}"
    ERRORS+=("Unclosed callouts: ${unclosed_callouts[*]:-}")
    VALID=false
fi

# Overall status
if ! $VALID; then
    overall="FAIL"
elif [[ ${#WARNINGS[@]} -gt 0 ]]; then
    overall="PASS_WITH_WARNINGS"
else
    overall="PASS"
fi

# Build missing_fields JSON array
missing_fields_json="["
first=true
for field in "${missing_fields[@]:-}"; do
    [[ -z "$field" ]] && continue
    if ! $first; then missing_fields_json+=","; fi
    missing_fields_json+="\"$field\""
    first=false
done
missing_fields_json+="]"

# Build missing_language JSON array
missing_lang_json="["
first=true
for line in "${missing_language[@]:-}"; do
    [[ -z "$line" ]] && continue
    if ! $first; then missing_lang_json+=","; fi
    missing_lang_json+="$line"
    first=false
done
missing_lang_json+="]"

# Build missing_alt JSON array
missing_alt_json="["
first=true
for line in "${missing_alt[@]:-}"; do
    [[ -z "$line" ]] && continue
    if ! $first; then missing_alt_json+=","; fi
    missing_alt_json+="$line"
    first=false
done
missing_alt_json+="]"

# Build warnings JSON array
warnings_json="["
first=true
for warn in "${WARNINGS[@]:-}"; do
    [[ -z "$warn" ]] && continue
    if ! $first; then warnings_json+=","; fi
    warnings_json+="\"$(json_escape "$warn")\""
    first=false
done
warnings_json+="]"

# Build errors JSON array
errors_json="["
first=true
for err in "${ERRORS[@]:-}"; do
    [[ -z "$err" ]] && continue
    if ! $first; then errors_json+=","; fi
    errors_json+="\"$(json_escape "$err")\""
    first=false
done
errors_json+="]"

# Output JSON
cat <<EOF
{
  "file": "$(json_escape "$FILENAME")",
  "path": "$(json_escape "$FILEPATH")",
  "valid": $(if $VALID; then echo "true"; else echo "false"; fi),
  "timestamp": "$(get_timestamp)",
  "checks": {
    "frontmatter_present": {
      "pass": $(if $fm_present_pass; then echo "true"; else echo "false"; fi),
      "message": "$(json_escape "$fm_present_msg")"
    },
    "frontmatter_complete": {
      "pass": $(if $fm_complete_pass; then echo "true"; else echo "false"; fi),
      "missing_fields": $missing_fields_json,
      "message": "$(json_escape "$fm_complete_msg")"
    },
    "em_dashes": {
      "pass": $(if $em_dash_pass; then echo "true"; else echo "false"; fi),
      "count": $em_dash_count,
      "message": "$(json_escape "$em_dash_msg")"
    },
    "code_blocks": {
      "pass": $(if $code_blocks_pass; then echo "true"; else echo "false"; fi),
      "count": $code_block_count,
      "missing_language": $missing_lang_json,
      "message": "$(json_escape "$code_blocks_msg")"
    },
    "alt_text": {
      "pass": $(if $alt_text_pass; then echo "true"; else echo "false"; fi),
      "missing_alt": $missing_alt_json,
      "message": "$(json_escape "$alt_text_msg")"
    },
    "duplicate_gifs": {
      "pass": $(if $dup_gif_pass; then echo "true"; else echo "false"; fi),
      "message": "$(json_escape "$dup_gif_msg")"
    },
    "callout_count": {
      "pass": $(if $callout_threshold_pass; then echo "true"; else echo "false"; fi),
      "count": $callout_count,
      "message": "$(json_escape "$callout_threshold_msg")"
    },
    "heading_hierarchy": {
      "pass": $(if $heading_hier_pass; then echo "true"; else echo "false"; fi),
      "message": "$(json_escape "$heading_hier_msg")"
    },
    "private_repo_links": {
      "pass": $(if $private_links_pass; then echo "true"; else echo "false"; fi),
      "message": "$(json_escape "$private_links_msg")"
    },
    "callout_closure": {
      "pass": $(if $callout_closure_pass; then echo "true"; else echo "false"; fi),
      "message": "$(json_escape "$callout_closure_msg")"
    }
  },
  "metadata": {
    "word_count": $word_count,
    "reading_time_minutes": $reading_time,
    "line_count": $total_lines,
    "heading_count": $heading_count,
    "code_block_count": $code_block_count,
    "image_count": $image_count,
    "link_count": $link_count
  },
  "warnings": $warnings_json,
  "errors": $errors_json,
  "summary": {
    "passed_checks": $passed_checks,
    "failed_checks": $failed_checks,
    "warning_count": ${#WARNINGS[@]},
    "error_count": ${#ERRORS[@]},
    "overall": "$overall"
  }
}
EOF

exit 0
