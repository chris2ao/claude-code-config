#!/bin/bash
# session-scratchpad.sh — PostToolUse hook
# Counts significant tool calls per session. After every 15 calls, outputs a
# reminder for Claude to update a session scratchpad file. This preserves
# context across compaction events.
#
# Tracked tools: Read, Grep, Glob, Edit, Write, Bash
# State: /tmp/claude-scratchpad-nudge/{session_id}.state
# Opt-out: set CLAUDE_SCRATCHPAD_NUDGE=false in your environment

# Env var opt-out
if [ "${CLAUDE_SCRATCHPAD_NUDGE}" = "false" ]; then
    exit 0
fi

input=$(cat)

tool_name=$(echo "$input" | grep -o '"tool_name":"[^"]*"' | head -n1 | cut -d'"' -f4)
session_id=$(echo "$input" | grep -o '"session_id":"[^"]*"' | head -n1 | cut -d'"' -f4)

if [ -z "$tool_name" ] || [ -z "$session_id" ]; then
    exit 0
fi

state_dir="/tmp/claude-scratchpad-nudge"
mkdir -p "$state_dir"
state_file="$state_dir/${session_id}.state"

# Initialize state file if missing
if [ ! -f "$state_file" ]; then
    echo "calls=0" > "$state_file"
    echo "reminded=0" >> "$state_file"
fi

# If Claude just wrote a scratchpad file, reset counter
if [ "$tool_name" = "Write" ] || [ "$tool_name" = "Edit" ]; then
    file_path=$(echo "$input" | sed 's/\\"/"/g' | grep -o '"file_path":"[^"]*"' | head -n1 | cut -d'"' -f4)
    case "$file_path" in
        */.claude/session-state/*)
            echo "calls=0" > "$state_file"
            echo "reminded=0" >> "$state_file"
            exit 0
            ;;
    esac
fi

# Only count significant tool calls
case "$tool_name" in
    Read|Grep|Glob|Edit|Write|Bash) ;;
    *) exit 0 ;;
esac

# Read current state
calls=$(grep '^calls=' "$state_file" | cut -d= -f2)
reminded=$(grep '^reminded=' "$state_file" | cut -d= -f2)
calls=$((calls + 1))

# Update call count
sed -i '' "s/^calls=.*/calls=$calls/" "$state_file" 2>/dev/null || {
    echo "calls=$calls" > "$state_file"
    echo "reminded=$reminded" >> "$state_file"
}

# Nudge every 15 tool calls
threshold=$(( (reminded + 1) * 15 ))

if [ "$calls" -ge "$threshold" ]; then
    reminded=$((reminded + 1))
    sed -i '' "s/^reminded=.*/reminded=$reminded/" "$state_file" 2>/dev/null
    echo "SESSION CONTEXT: Update your session scratchpad at ~/.claude/session-state/${session_id}.md with current task state, key decisions, files being worked on, and next steps. This preserves context across compaction."
fi

exit 0
