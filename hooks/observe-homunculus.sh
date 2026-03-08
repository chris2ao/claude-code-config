#!/bin/bash
# observe-homunculus.sh — Runs on PostToolUse hook (async)
# Captures tool usage observations for the Homunculus v2 continuous learning system.
# Writes JSONL to ~/.claude/homunculus/observations.jsonl for later analysis
# by the skill-extractor agent or /learn command.
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

# Extract tool_name
tool_name=$(echo "$input" | grep -o '"tool_name":"[^"]*"' | head -n1 | cut -d'"' -f4)

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

# Extract session_id
session_id=$(echo "$input" | grep -o '"session_id":"[^"]*"' | head -n1 | cut -d'"' -f4)

# Extract tool_input (simplified - just capture the raw JSON fragment)
tool_input=$(echo "$input" | grep -o '"tool_input":\{[^}]*\}' | sed 's/"tool_input"://')

# Extract tool_output (simplified - just capture the raw JSON fragment)
tool_output=$(echo "$input" | grep -o '"tool_output":\{[^}]*\}' | sed 's/"tool_output"://')

# Truncate input if too long
if [ ${#tool_input} -gt $max_input_chars ]; then
    tool_input="${tool_input:0:$max_input_chars}...[truncated]"
fi

# Truncate output if too long
if [ ${#tool_output} -gt $max_output_chars ]; then
    tool_output="${tool_output:0:$max_output_chars}...[truncated]"
fi

# Get timestamp
timestamp=$(date -u '+%Y-%m-%dT%H:%M:%S.000Z')

# Build observation JSON (simplified)
# Note: This is a basic implementation. Production version would need proper JSON escaping.
json_line="{\"timestamp\":\"$timestamp\",\"session_id\":\"$session_id\",\"tool\":\"$tool_name\",\"input\":$tool_input,\"output\":$tool_output}"

# Append to observations file
echo "$json_line" >> "$observations_file"

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
