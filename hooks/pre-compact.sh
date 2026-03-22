#!/bin/bash
# pre-compact.sh — PreCompact hook
# Automatically saves session context before compaction occurs.
# Reads the session transcript, extracts key context, and writes a
# scratchpad file that Claude can read after compaction to recover state.
#
# Input JSON fields used:
#   - session_id: unique session identifier
#   - transcript_path: path to the full session JSONL transcript
#   - trigger: "manual" or "auto"
#
# Output: scratchpad file at ~/.claude/session-state/{session_id}.md

input=$(cat)

session_id=$(echo "$input" | grep -o '"session_id":"[^"]*"' | head -n1 | cut -d'"' -f4)
transcript_path=$(echo "$input" | grep -o '"transcript_path":"[^"]*"' | head -n1 | cut -d'"' -f4)
trigger=$(echo "$input" | grep -o '"trigger":"[^"]*"' | head -n1 | cut -d'"' -f4)

if [ -z "$session_id" ]; then
    exit 0
fi

scratchpad_dir="$HOME/.claude/session-state"
mkdir -p "$scratchpad_dir"
scratchpad="$scratchpad_dir/${session_id}.md"

# Extract context from the transcript if available
recent_tools=""
recent_files=""
recent_errors=""
assistant_messages=""

if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    # Get the last 50 lines of the transcript for recent context
    tail_content=$(tail -100 "$transcript_path" 2>/dev/null)

    # Extract recently used file paths (from Edit, Write, Read tools)
    recent_files=$(echo "$tail_content" \
        | grep -o '"file_path":"[^"]*"' \
        | cut -d'"' -f4 \
        | sort -u \
        | tail -20)

    # Extract recent tool names to understand what was happening
    recent_tools=$(echo "$tail_content" \
        | grep -o '"tool_name":"[^"]*"' \
        | cut -d'"' -f4 \
        | tail -20)

    # Extract any error messages from tool results
    recent_errors=$(echo "$tail_content" \
        | grep -o '"error":"[^"]*"' \
        | cut -d'"' -f4 \
        | tail -5)

    # Extract recent assistant text content (task descriptions, decisions)
    # Look for assistant message text blocks in the last portion of transcript
    assistant_messages=$(echo "$tail_content" \
        | grep '"type":"text"' \
        | grep -o '"text":"[^"]*"' \
        | cut -d'"' -f4 \
        | tail -10)
fi

# Build the scratchpad
cat > "$scratchpad" << SCRATCHPAD_EOF
# Session Context (auto-saved before ${trigger} compaction)
# Session: ${session_id}
# Saved: $(date -u '+%Y-%m-%dT%H:%M:%SZ')

## Recent Files Being Worked On
$(if [ -n "$recent_files" ]; then
    echo "$recent_files" | while read -r f; do echo "- $f"; done
else
    echo "(no file paths captured)"
fi)

## Recent Tool Activity
$(if [ -n "$recent_tools" ]; then
    echo "$recent_tools" | sort | uniq -c | sort -rn | while read -r count tool; do
        echo "- ${tool}: ${count} calls"
    done
else
    echo "(no tool activity captured)"
fi)

## Recent Errors
$(if [ -n "$recent_errors" ]; then
    echo "$recent_errors" | while read -r e; do echo "- $e"; done
else
    echo "(none)"
fi)

## Recent Assistant Context
$(if [ -n "$assistant_messages" ]; then
    echo "$assistant_messages" | head -5 | while read -r m; do
        # Truncate long messages
        truncated=$(echo "$m" | cut -c1-200)
        echo "- $truncated"
    done
else
    echo "(no assistant messages captured)"
fi)

## Recovery Instructions
After compaction, read this file to recover context about what was being
worked on. Query vector memory with keywords from the file paths and tool
activity above to find related memories.
SCRATCHPAD_EOF

# Reset the scratchpad nudge counter since we just saved
nudge_state="/tmp/claude-scratchpad-nudge/${session_id}.state"
if [ -f "$nudge_state" ]; then
    echo "calls=0" > "$nudge_state"
    echo "reminded=0" >> "$nudge_state"
fi

exit 0
