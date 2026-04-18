#!/usr/bin/env bash
# homenetwork-nudge.sh — PostToolUse hook
# After a UniFi MCP tool call, remind Claude to update the HomeNetwork/ context
# in the CJClaudin_Mac project. Only nudges on tools likely to reveal new facts,
# and only if a HomeNetwork/ directory exists in the current workspace.

# Opt-out
if [ "${CLAUDE_HOMENETWORK_NUDGE}" = "false" ]; then
    exit 0
fi

input=$(cat)

tool_name=$(echo "$input" | grep -o '"tool_name":"[^"]*"' | head -n1 | cut -d'"' -f4)
cwd=$(echo "$input" | grep -o '"cwd":"[^"]*"' | head -n1 | cut -d'"' -f4)

if [ -z "$tool_name" ]; then
    exit 0
fi

# Only react to UniFi MCP tools
case "$tool_name" in
    mcp__unifi__*) ;;
    *) exit 0 ;;
esac

# Only react to tools that produce information worth persisting
# (skip noisy/internal tools like get_server_info, get_auth_report, load_*_tools)
case "$tool_name" in
    mcp__unifi__load_*_tools|mcp__unifi__get_server_info|mcp__unifi__get_auth_report)
        exit 0 ;;
esac

# Only nudge if a HomeNetwork directory exists in the workspace or cwd
workspace="${cwd:-$PWD}"
home_net=""
if [ -d "$workspace/HomeNetwork" ]; then
    home_net="$workspace/HomeNetwork"
elif [ -d "/Users/chris2ao/GitProjects/CJClaudin_Mac/HomeNetwork" ]; then
    home_net="/Users/chris2ao/GitProjects/CJClaudin_Mac/HomeNetwork"
else
    exit 0
fi

# Rate-limit: emit at most once per 5 minutes per session
session_id=$(echo "$input" | grep -o '"session_id":"[^"]*"' | head -n1 | cut -d'"' -f4)
state_dir="/tmp/claude-homenetwork-nudge"
mkdir -p "$state_dir"
stamp_file="$state_dir/${session_id:-default}.stamp"

now=$(date +%s)
if [ -f "$stamp_file" ]; then
    last=$(cat "$stamp_file" 2>/dev/null || echo 0)
    if [ $((now - last)) -lt 300 ]; then
        exit 0
    fi
fi
echo "$now" > "$stamp_file"

cat <<EOF
HOMENETWORK CONTEXT UPDATE: You just ran $tool_name against the home UniFi controller. Update the matching file(s) in $home_net with any new facts learned:
- New client or identification → inventory.md + devices/<category>.md
- New SSID / AP / VLAN / subnet → topology.md and the README "Current State" rollup
- Answered an open question → move the entry from Open to Resolved in investigations.md with today's date (2026-04-17) and the answer
- New unknown worth pursuing → add to investigations.md Open section with evidence gathered and next leads

Do not batch these to end-of-session. Update in this turn while the context is fresh.
EOF
exit 0
