#!/bin/bash
# log-activity.sh — Runs on PostToolUse hook (async)
# Logs every file edit, bash command, and write operation to activity_log.txt
# so you have a running record of everything Claude Code does in this project.
#
# Hook input (JSON on stdin) includes:
#   tool_name  — name of the tool that was used (Bash, Edit, Write, etc.)
#   tool_input — the input/arguments passed to the tool
#   session_id — current session identifier

# Read JSON from stdin
input=$(cat)

# Extract tool_name
tool_name=$(echo "$input" | grep -o '"tool_name":"[^"]*"' | head -n1 | cut -d'"' -f4)

# Exit if no tool name
if [ -z "$tool_name" ]; then
    exit 0
fi

# Extract session_id
session_id=$(echo "$input" | grep -o '"session_id":"[^"]*"' | head -n1 | cut -d'"' -f4)

# Resolve project root (script is in .claude/hooks, go up 2 levels)
script_dir=$(cd "$(dirname "$0")" && pwd)
project_root=$(cd "$script_dir/../.." && pwd)
log_path="$project_root/activity_log.txt"

# Get timestamp
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Build detail based on tool type
detail=""
case "$tool_name" in
    Edit)
        file=$(echo "$input" | grep -o '"file_path":"[^"]*"' | head -n1 | cut -d'"' -f4)
        detail="Edited: $file"
        ;;
    Write)
        file=$(echo "$input" | grep -o '"file_path":"[^"]*"' | head -n1 | cut -d'"' -f4)
        detail="Wrote: $file"
        ;;
    Bash)
        cmd=$(echo "$input" | grep -o '"command":"[^"]*"' | head -n1 | cut -d'"' -f4)
        # Truncate long commands
        if [ ${#cmd} -gt 200 ]; then
            cmd="${cmd:0:200}..."
        fi
        detail="Ran: $cmd"
        ;;
    NotebookEdit)
        nb=$(echo "$input" | grep -o '"notebook_path":"[^"]*"' | head -n1 | cut -d'"' -f4)
        detail="Edited notebook: $nb"
        ;;
    *)
        detail="Used tool: $tool_name"
        ;;
esac

# Append log line
log_line="[$timestamp] ($session_id) $tool_name | $detail"
echo "$log_line" >> "$log_path"

# Log rotation: archive when file exceeds 1000 lines
max_lines=1000
if [ -f "$log_path" ]; then
    line_count=$(wc -l < "$log_path")
    if [ "$line_count" -ge "$max_lines" ]; then
        # Extract first and last timestamps
        first_line=$(head -n1 "$log_path")
        last_line=$(tail -n1 "$log_path")

        # Parse dates from "[YYYY-MM-DD HH:mm:ss]" format
        start_date=$(echo "$first_line" | grep -o '\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]' | tr -d '[' | head -n1)
        end_date=$(echo "$last_line" | grep -o '\[20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]' | tr -d '[' | head -n1)

        # Fallback if parsing fails
        if [ -z "$start_date" ]; then
            start_date="unknown"
        fi
        if [ -z "$end_date" ]; then
            end_date=$(date '+%Y-%m-%d')
        fi

        archive_name="activity_log_${start_date}_to_${end_date}.txt"
        archive_path="$project_root/$archive_name"

        # Avoid overwriting: append a counter if archive already exists
        counter=1
        while [ -f "$archive_path" ]; do
            archive_name="activity_log_${start_date}_to_${end_date}_${counter}.txt"
            archive_path="$project_root/$archive_name"
            ((counter++))
        done

        # Move current log to archive
        mv "$log_path" "$archive_path"
    fi
fi

exit 0
