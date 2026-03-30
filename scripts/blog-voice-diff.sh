#!/usr/bin/env bash
# platform: macos

# blog-voice-diff.sh - Extract measurable voice metrics from an MDX blog post
# Usage: bash blog-voice-diff.sh <path-to-file.mdx>
# Output: JSON with voice metrics for comparison against baseline ranges

set -uo pipefail

if [[ $# -ne 1 ]]; then
    echo '{"error":"Usage: blog-voice-diff.sh <path-to-file.mdx>"}' >&2
    exit 1
fi

FILE="$1"

if [[ ! -f "$FILE" ]]; then
    echo "{\"error\":\"File not found\",\"path\":\"$FILE\"}" >&2
    exit 1
fi

json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

# Strip frontmatter to get content only
content=$(awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2{print}' "$FILE")

# Strip code blocks for prose analysis
prose=$(echo "$content" | awk '
    /^```/{in_code=!in_code; next}
    !in_code{print}
')

# --- Paragraph metrics ---
# A paragraph is one or more consecutive non-empty lines
para_count=0
para_total_words=0
current_para_words=0
in_paragraph=false

while IFS= read -r line; do
    # Skip lines that are purely MDX components or headings
    trimmed=$(echo "$line" | sed 's/^[[:space:]]*//')
    if [[ -z "$trimmed" ]]; then
        if $in_paragraph && [[ $current_para_words -gt 0 ]]; then
            para_count=$((para_count + 1))
            para_total_words=$((para_total_words + current_para_words))
            current_para_words=0
            in_paragraph=false
        fi
    else
        in_paragraph=true
        wc=$(echo "$trimmed" | wc -w | tr -d ' ')
        current_para_words=$((current_para_words + wc))
    fi
done <<< "$prose"

# Capture last paragraph
if $in_paragraph && [[ $current_para_words -gt 0 ]]; then
    para_count=$((para_count + 1))
    para_total_words=$((para_total_words + current_para_words))
fi

if [[ $para_count -gt 0 ]]; then
    avg_para_length=$((para_total_words / para_count))
else
    avg_para_length=0
fi

# --- Sentence metrics ---
# Count sentences by period, exclamation, question mark at end of words
sentence_count=$(echo "$prose" | grep -oE '[.!?][[:space:]]|[.!?]$' | wc -l | tr -d ' ')
if [[ $sentence_count -eq 0 ]]; then sentence_count=1; fi

total_prose_words=$(echo "$prose" | wc -w | tr -d ' ')
avg_sentence_length=$((total_prose_words / sentence_count))

# --- Contraction frequency (per 1000 words) ---
contraction_count=$(echo "$prose" | grep -oiE "\b(I'm|I've|I'll|I'd|we're|we've|we'll|we'd|you're|you've|you'll|you'd|they're|they've|they'll|they'd|he's|she's|it's|that's|there's|here's|what's|who's|how's|isn't|aren't|wasn't|weren't|don't|doesn't|didn't|won't|wouldn't|shouldn't|couldn't|can't|haven't|hasn't|hadn't)\b" | wc -l | tr -d ' ')
if [[ $total_prose_words -gt 0 ]]; then
    contraction_per_1000=$(( (contraction_count * 1000) / total_prose_words ))
else
    contraction_per_1000=0
fi

# --- First-person pronoun density (per 1000 words) ---
fp_count=$(echo "$prose" | grep -oiE "\b(I|I'm|I've|I'll|I'd|my|me|mine|myself|we|we're|we've|we'll|we'd|our|ours|us|ourselves)\b" | wc -l | tr -d ' ')
if [[ $total_prose_words -gt 0 ]]; then
    fp_per_1000=$(( (fp_count * 1000) / total_prose_words ))
else
    fp_per_1000=0
fi

# --- Question density (per 1000 words) ---
question_count=$(echo "$prose" | grep -oE '\?' | wc -l | tr -d ' ')
if [[ $total_prose_words -gt 0 ]]; then
    question_per_1000=$(( (question_count * 1000) / total_prose_words ))
else
    question_per_1000=0
fi

# --- Em dash count (in prose, outside code blocks) ---
em_dash_count=$(echo "$prose" | grep -o '—' | wc -l | tr -d ' ')

# --- Opening paragraph analysis ---
# First non-empty paragraph after frontmatter
opening_para=""
found_opening=false
while IFS= read -r line; do
    trimmed=$(echo "$line" | sed 's/^[[:space:]]*//')
    # Skip headings, empty lines, import statements, MDX components
    if [[ -z "$trimmed" ]] || [[ "$trimmed" =~ ^# ]] || [[ "$trimmed" =~ ^import ]] || [[ "$trimmed" =~ ^\< ]]; then
        if $found_opening; then break; fi
        continue
    fi
    found_opening=true
    opening_para="$opening_para $trimmed"
done <<< "$content"

opening_word_count=$(echo "$opening_para" | wc -w | tr -d ' ')

# Check for numbers/metrics in opening paragraph
has_metric=false
if echo "$opening_para" | grep -qE '[0-9]+(%| percent| hours| days| commits| files| lines| minutes| seconds| emails| posts|x |X )'; then
    has_metric=true
fi

# --- GIF analysis ---
gif_lines=()
gif_count=0
line_num=0
while IFS= read -r line; do
    line_num=$((line_num + 1))
    if echo "$line" | grep -qiE 'giphy\.com|\.gif'; then
        gif_lines+=("$line_num")
        gif_count=$((gif_count + 1))
    fi
done < "$FILE"

gif_lines_json="["
first=true
for ln in "${gif_lines[@]:-}"; do
    if [[ -z "$ln" ]]; then continue; fi
    if ! $first; then gif_lines_json+=","; fi
    gif_lines_json+="$ln"
    first=false
done
gif_lines_json+="]"

# --- Callout analysis ---
total_callouts=0
callout_tip=$(grep -c "<Tip" "$FILE" 2>/dev/null || true); callout_tip=${callout_tip:-0}
callout_info=$(grep -c "<Info" "$FILE" 2>/dev/null || true); callout_info=${callout_info:-0}
callout_warning=$(grep -c "<Warning" "$FILE" 2>/dev/null || true); callout_warning=${callout_warning:-0}
callout_stop=$(grep -c "<Stop" "$FILE" 2>/dev/null || true); callout_stop=${callout_stop:-0}
callout_security=$(grep -c "<Security" "$FILE" 2>/dev/null || true); callout_security=${callout_security:-0}
total_callouts=$((callout_tip + callout_info + callout_warning + callout_stop + callout_security))

# --- Heading depth distribution ---
h2_count=$(grep -cE '^## ' "$FILE" 2>/dev/null || true)
h3_count=$(grep -cE '^### ' "$FILE" 2>/dev/null || true)
h4_count=$(grep -cE '^#### ' "$FILE" 2>/dev/null || true)
# Ensure counts are numeric (grep -c outputs 0 but returns exit 1 on no match)
h2_count=${h2_count:-0}; h3_count=${h3_count:-0}; h4_count=${h4_count:-0}

# --- Total content word count ---
total_words=$(echo "$content" | wc -w | tr -d ' ')

# --- Output JSON ---
cat <<EOF
{
  "file": "$(json_escape "$(basename "$FILE")")",
  "total_words": $total_words,
  "paragraphs": {
    "count": $para_count,
    "avg_length_words": $avg_para_length
  },
  "sentences": {
    "count": $sentence_count,
    "avg_length_words": $avg_sentence_length
  },
  "contractions": {
    "count": $contraction_count,
    "per_1000_words": $contraction_per_1000
  },
  "first_person_pronouns": {
    "count": $fp_count,
    "per_1000_words": $fp_per_1000
  },
  "questions": {
    "count": $question_count,
    "per_1000_words": $question_per_1000
  },
  "em_dashes": $em_dash_count,
  "opening_paragraph": {
    "word_count": $opening_word_count,
    "has_metric": $has_metric
  },
  "gifs": {
    "count": $gif_count,
    "line_positions": $gif_lines_json
  },
  "callouts": {
    "total": $total_callouts,
    "tip": $callout_tip,
    "info": $callout_info,
    "warning": $callout_warning,
    "stop": $callout_stop,
    "security": $callout_security
  },
  "headings": {
    "h2": $h2_count,
    "h3": $h3_count,
    "h4": $h4_count
  }
}
EOF
