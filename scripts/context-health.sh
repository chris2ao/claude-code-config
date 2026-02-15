#!/bin/bash

# context-health.sh - Quick context window health check
# Counts transcripts, sizes, estimates tokens

set -euo pipefail

get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Initialize counters
transcript_count=0
total_size_bytes=0
total_lines=0
todo_count=0
activity_log_lines=0

# Claude projects directory
CLAUDE_PROJECTS="$HOME/.claude/projects"
CLAUDE_TODOS="$HOME/.claude/todos"

# Count transcripts
if [[ -d "$CLAUDE_PROJECTS" ]]; then
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            transcript_count=$((transcript_count + 1))

            # Get file size
            if [[ "$(uname -s)" == "Linux" ]] || [[ "$(uname -s)" =~ MSYS|MINGW|CYGWIN ]]; then
                size=$(stat -c %s "$file" 2>/dev/null || echo 0)
            else
                size=$(stat -f %z "$file" 2>/dev/null || echo 0)
            fi
            total_size_bytes=$((total_size_bytes + size))

            # Count lines
            lines=$(wc -l < "$file" 2>/dev/null || echo 0)
            total_lines=$((total_lines + lines))
        fi
    done < <(find "$CLAUDE_PROJECTS" -name "*.jsonl" -type f 2>/dev/null)
fi

# Count todos
if [[ -d "$CLAUDE_TODOS" ]]; then
    todo_count=$(find "$CLAUDE_TODOS" -name "*.json" -type f 2>/dev/null | wc -l)
fi

# Count activity log lines in current project
activity_log_files=(
    "activity_log.txt"
    "activity_log_*.txt"
)

for pattern in "${activity_log_files[@]}"; do
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            lines=$(wc -l < "$file" 2>/dev/null || echo 0)
            activity_log_lines=$((activity_log_lines + lines))
        fi
    done < <(find . -maxdepth 1 -name "$pattern" -type f 2>/dev/null)
done

# Calculate MB
total_size_mb=$(awk "BEGIN {printf \"%.1f\", $total_size_bytes / 1048576}")

# Estimate tokens (15 tokens per line average)
estimated_tokens=$((total_lines * 15))

# Output JSON
cat <<EOF
{
  "timestamp": "$(get_timestamp)",
  "transcripts": {
    "count": $transcript_count,
    "total_size_bytes": $total_size_bytes,
    "total_size_mb": $total_size_mb,
    "total_lines": $total_lines,
    "estimated_tokens": $estimated_tokens
  },
  "todos": {
    "count": $todo_count
  },
  "activity_log": {
    "lines": $activity_log_lines
  }
}
EOF

exit 0
