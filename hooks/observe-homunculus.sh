#!/bin/bash
# observe-homunculus.sh — Runs on PostToolUse hook (async)
# Captures tool usage observations for the Homunculus v2 continuous learning system.
# Writes JSONL to ~/.claude/homunculus/observations.jsonl for later analysis
# by the /evolve pipeline.
#
# Hook input (JSON on stdin) includes:
#   tool_name   — name of the tool (Bash, Edit, Write, Read, Grep, Glob, etc.)
#   tool_input  — the input/arguments passed to the tool
#   tool_output — the output/result from the tool (PostToolUse only)
#   session_id  — current session identifier

# Config
homunculus_dir="$HOME/.claude/homunculus"
observations_file="$homunculus_dir/observations.jsonl"
archive_dir="$homunculus_dir/observations.archive"
disabled_sentinel="$homunculus_dir/disabled"
max_input_chars=5000
max_output_chars=5000
max_file_size_mb=10
allowed_tools=("Edit" "Write" "Bash" "Read" "Grep" "Glob")

# Early exits

# Disabled sentinel check
if [ -f "$disabled_sentinel" ]; then
    exit 0
fi

# Ensure homunculus directory exists
if [ ! -d "$homunculus_dir" ]; then
    exit 0
fi

# Read stdin
input=$(cat)

# jq builds the observation so every line is valid JSON; skip quietly if jq is missing
command -v jq >/dev/null 2>&1 || exit 0

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)

# Exit if no tool name
if [ -z "$tool_name" ]; then
    exit 0
fi

# Filter: only capture allowed tools
allowed=0
for tool in "${allowed_tools[@]}"; do
    if [ "$tool_name" = "$tool" ]; then
        allowed=1
        break
    fi
done

if [ $allowed -eq 0 ]; then
    exit 0
fi

timestamp=$(date -u '+%Y-%m-%dT%H:%M:%S.000Z')

# Input stays an object when small; oversized input and all output are stored as truncated strings.
# PostToolUse sends the result as tool_response (tool_output is the older name).
json_line=$(printf '%s' "$input" | jq -c \
    --arg ts "$timestamp" \
    --argjson max_in "$max_input_chars" \
    --argjson max_out "$max_output_chars" '
    def clip($n): if length > $n then .[0:$n] + "...[truncated]" else . end;
    (.tool_input // null) as $in
    | ((.tool_response // .tool_output) // null) as $out
    | {
        timestamp: $ts,
        session_id: (.session_id // ""),
        tool: .tool_name,
        input: (if ($in | tojson | length) > $max_in then ($in | tojson | clip($max_in)) else $in end),
        output: (if $out == null then null elif ($out | type) == "string" then ($out | clip($max_out)) else ($out | tojson | clip($max_out)) end)
      }' 2>/dev/null)

[ -n "$json_line" ] || exit 0

# Append to observations file
printf '%s\n' "$json_line" >> "$observations_file"

# Archive if file exceeds size limit
if [ -f "$observations_file" ]; then
    file_size=$(stat -f%z "$observations_file" 2>/dev/null || stat -c%s "$observations_file" 2>/dev/null)
    max_size=$((max_file_size_mb * 1024 * 1024))

    if [ "$file_size" -gt "$max_size" ]; then
        # Ensure archive directory exists
        mkdir -p "$archive_dir"

        datestamp=$(date '+%Y-%m-%d_%H%M%S')
        archive_name="observations_${datestamp}.jsonl"
        archive_path="$archive_dir/$archive_name"

        # Move current file to archive
        mv "$observations_file" "$archive_path"
    fi
fi

exit 0
