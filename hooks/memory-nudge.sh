#!/bin/bash
# memory-nudge.sh — PostToolUse hook
# Tracks file modifications per session. After 5+ significant edits without a
# vector-memory store call, outputs a reminder that gets injected
# into Claude's context as user feedback.
#
# How it works:
#   - Counts Edit/Write tool calls in a session-specific temp file
#   - Only counts edits to source code (src/, lib/, app/, components/, hooks/, etc.)
#   - Skips config, docs, markdown, and dotfiles
#   - Resets when memory_store is detected
#   - Outputs reminder after threshold is reached (once per threshold)
#
# Opt-out: set CLAUDE_MEMORY_NUDGE=false in your environment to disable

# Env var opt-out
if [ "${CLAUDE_MEMORY_NUDGE}" = "false" ]; then
    exit 0
fi

input=$(cat)

tool_name=$(echo "$input" | grep -o '"tool_name":"[^"]*"' | head -n1 | cut -d'"' -f4)
session_id=$(echo "$input" | grep -o '"session_id":"[^"]*"' | head -n1 | cut -d'"' -f4)

if [ -z "$tool_name" ] || [ -z "$session_id" ]; then
    exit 0
fi

state_dir="/tmp/claude-memory-nudge"
mkdir -p "$state_dir"
state_file="$state_dir/${session_id}.state"

# Initialize state file if missing
if [ ! -f "$state_file" ]; then
    echo "edits=0" > "$state_file"
    echo "reminded=0" >> "$state_file"
fi

# If memory_store was just called, reset counters
if [ "$tool_name" = "mcp__vector-memory__memory_store" ]; then
    echo "edits=0" > "$state_file"
    echo "reminded=0" >> "$state_file"
    exit 0
fi

# Only count Edit and Write as significant changes
if [ "$tool_name" != "Edit" ] && [ "$tool_name" != "Write" ]; then
    exit 0
fi

# Extract file_path from tool_input JSON (unescape \" first since tool_input is a nested JSON string)
file_path=$(echo "$input" | sed 's/\\"/"/g' | grep -o '"file_path":"[^"]*"' | head -n1 | cut -d'"' -f4)

# Skip non-source files: config, docs, markdown, dotfiles, lock files
if [ -n "$file_path" ]; then
    basename=$(basename "$file_path")
    ext="${basename##*.}"

    # Skip by extension
    case "$ext" in
        md|mdx|txt|json|yaml|yml|toml|ini|cfg|lock|log|env|csv)
            exit 0
            ;;
    esac

    # Skip dotfiles and common config files
    case "$basename" in
        .*)               exit 0 ;;
        Makefile|Dockerfile|Procfile) exit 0 ;;
        *.config.*)       exit 0 ;;
        *.rc|*.rc.*)      exit 0 ;;
    esac

    # Skip paths outside source directories
    # Only count files under common source paths
    is_source=false
    case "$file_path" in
        */src/*|*/lib/*|*/app/*|*/components/*|*/hooks/*|*/pages/*|*/server/*|*/api/*|*/services/*|*/utils/*|*/helpers/*|*/models/*|*/controllers/*|*/routes/*|*/middleware/*)
            is_source=true
            ;;
    esac

    if [ "$is_source" = false ]; then
        exit 0
    fi
fi

# Read current state
edits=$(grep '^edits=' "$state_file" | cut -d= -f2)
reminded=$(grep '^reminded=' "$state_file" | cut -d= -f2)
edits=$((edits + 1))

# Update edit count
sed -i '' "s/^edits=.*/edits=$edits/" "$state_file" 2>/dev/null || {
    echo "edits=$edits" > "$state_file"
    echo "reminded=$reminded" >> "$state_file"
}

# Nudge at 5 edits, then every 10 after that
threshold=5
if [ "$reminded" -gt 0 ]; then
    threshold=$(( 5 + reminded * 10 ))
fi

if [ "$edits" -ge "$threshold" ]; then
    reminded=$((reminded + 1))
    sed -i '' "s/^reminded=.*/reminded=$reminded/" "$state_file" 2>/dev/null
    echo "MEMORY REMINDER: You have made $edits source file edits this session without storing a vector memory. If you have completed any significant tasks, bug fixes, or architectural decisions, store them now using mcp__vector-memory__memory_store before continuing."
fi

exit 0
