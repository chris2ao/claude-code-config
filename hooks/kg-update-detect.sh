#!/usr/bin/env bash
# kg-update-detect.sh — PostToolUse hook
# Detects when Claude Code component files are created or modified and outputs
# a reminder to update the knowledge graph so it stays current.
#
# Tracked paths (any Edit or Write to files under these):
#   ~/.claude/agents/    — Agent definitions
#   ~/.claude/skills/    — Skill definitions
#   ~/.claude/hooks/     — Hook scripts
#   ~/.claude/commands/  — Slash commands
#   ~/.claude/scripts/   — Utility scripts
#   ~/.claude.json       — MCP server config
#
# How it works:
#   - Reads JSON from stdin (tool_name, tool_input.file_path, session_id)
#   - Only fires on Edit or Write tool calls
#   - Resolves the file_path against known tracked paths
#   - If a match is found, emits a KG UPDATE reminder once per file per session
#   - A state file in /tmp/claude-kg-nudge/ prevents duplicate nudges for the
#     same file within the same session
#
# Opt-out: set CLAUDE_KG_NUDGE=false in your environment to disable

# Env var opt-out
if [ "${CLAUDE_KG_NUDGE}" = "false" ]; then
    exit 0
fi

input=$(cat)

tool_name=$(echo "$input" | grep -o '"tool_name":"[^"]*"' | head -n1 | cut -d'"' -f4)
session_id=$(echo "$input" | grep -o '"session_id":"[^"]*"' | head -n1 | cut -d'"' -f4)

if [ -z "$tool_name" ] || [ -z "$session_id" ]; then
    exit 0
fi

# Only care about Edit and Write tool calls
if [ "$tool_name" != "Edit" ] && [ "$tool_name" != "Write" ]; then
    exit 0
fi

# Extract file_path from tool_input JSON
file_path=$(echo "$input" | sed 's/\\"/"/g' | grep -o '"file_path":"[^"]*"' | head -n1 | cut -d'"' -f4)

if [ -z "$file_path" ]; then
    exit 0
fi

# Expand ~ to the actual home directory for reliable prefix matching
home_dir="$HOME"

# Determine if file_path falls under a tracked directory or is a tracked file
component_type=""

case "$file_path" in
    "${home_dir}/.claude/agents/"*)
        component_type="agent definition"
        ;;
    "${home_dir}/.claude/skills/"*)
        component_type="skill definition"
        ;;
    "${home_dir}/.claude/hooks/"*)
        component_type="hook script"
        ;;
    "${home_dir}/.claude/commands/"*)
        component_type="slash command"
        ;;
    "${home_dir}/.claude/scripts/"*)
        component_type="utility script"
        ;;
    "${home_dir}/.claude.json")
        component_type="MCP server config"
        ;;
    *)
        exit 0
        ;;
esac

# Dedup: nudge only once per file per session
state_dir="/tmp/claude-kg-nudge"
mkdir -p "$state_dir"

# Build a safe filename from session_id + file_path hash
# Use a simple collision-resistant key: session + url-encoded path
safe_key=$(printf '%s' "${session_id}::${file_path}" | shasum -a 256 | cut -c1-16)
nudge_file="${state_dir}/${safe_key}.nudged"

if [ -f "$nudge_file" ]; then
    exit 0
fi

# Mark as nudged for this session + file combination
touch "$nudge_file"

# Emit the reminder
echo "KG UPDATE: You modified ${component_type} at ${file_path}. Update the knowledge graph using mcp__memory__create_entities or mcp__memory__add_observations to keep it current. If you created a new component, also add relations using mcp__memory__create_relations."

exit 0
