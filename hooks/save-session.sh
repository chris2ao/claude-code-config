#!/bin/bash
# save-session.sh — Runs on SessionEnd hook
# Copies the conversation transcript into .claude/session_archive/
# and appends an entry to the session index file.
#
# Hook input (JSON on stdin) includes:
#   session_id      — unique session identifier
#   transcript_path — path to the JSONL transcript file

# Read JSON from stdin
input=$(cat)

# Extract transcript_path
transcript_path=$(echo "$input" | grep -o '"transcript_path":"[^"]*"' | head -n1 | cut -d'"' -f4)

# Extract session_id
session_id=$(echo "$input" | grep -o '"session_id":"[^"]*"' | head -n1 | cut -d'"' -f4)

# Exit if no transcript path or file doesn't exist
if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
    exit 0
fi

# Resolve project root (script is in .claude/hooks, go up 2 levels)
script_dir=$(cd "$(dirname "$0")" && pwd)
project_root=$(cd "$script_dir/../.." && pwd)
archive_dir="$project_root/.claude/session_archive"

# Create archive directory if it doesn't exist
mkdir -p "$archive_dir"

# Create timestamped filename
timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
archive_name="${timestamp}_${session_id}"

# Copy raw transcript
dest_path="$archive_dir/${archive_name}.jsonl"
cp "$transcript_path" "$dest_path"

# Create a lightweight summary by extracting assistant/user message roles
summary_path="$archive_dir/${archive_name}_summary.txt"
{
    echo "Session: $session_id"
    echo "Date: $timestamp"
    echo "Transcript: $transcript_path"
    echo "---"

    # Extract message types from JSONL (simplified parsing)
    while IFS= read -r line; do
        message_type=$(echo "$line" | grep -o '"type":"[^"]*"' | head -n1 | cut -d'"' -f4)
        if [ -n "$message_type" ]; then
            # Extract first bit of content (simplified)
            content=$(echo "$line" | grep -o '"text":"[^"]*"' | head -n1 | cut -d'"' -f4 | cut -c1-100)
            echo "[$message_type] $content"
        fi
    done < "$transcript_path"
} > "$summary_path"

# Append to session index
index_path="$archive_dir/index.txt"
echo "$timestamp | $session_id | $dest_path" >> "$index_path"

# Clean up session scratchpad on clean exit
rm -f "$HOME/.claude/session-state/${session_id}.md" 2>/dev/null

exit 0
