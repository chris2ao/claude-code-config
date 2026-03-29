#!/bin/bash
# memory-nudge.sh — PostToolUse hook
# Tracks significant work per session. After 5+ units of work without a
# vector-memory store call, outputs a reminder that gets injected
# into Claude's context as user feedback.
#
# How it works:
#   - Counts Edit/Write tool calls on source files (+1 each)
#   - Counts Agent completions as significant work (+3 each, since agents
#     typically write multiple files that don't trigger parent hooks)
#   - Skips pure config, docs, and dotfiles for Edit/Write
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

# Determine how much work this tool call represents
work_units=0

# Agent completions count as significant work (agents write files
# that don't trigger parent session PostToolUse hooks)
if [ "$tool_name" = "Agent" ]; then
    work_units=3
fi

# MCP tool calls that modify state count as significant work
case "$tool_name" in
    mcp__memory__create_entities|mcp__memory__create_relations|mcp__memory__delete_entities|mcp__memory__add_observations)
        work_units=2
        ;;
    mcp__obsidian__create_vault_file|mcp__obsidian__patch_vault_file|mcp__obsidian__update_active_file)
        work_units=1
        ;;
    mcp__github__create_pull_request|mcp__github__create_issue|mcp__github__push_files|mcp__github__create_or_update_file)
        work_units=2
        ;;
esac

# Edit and Write count if they target source-like files
if [ "$tool_name" = "Edit" ] || [ "$tool_name" = "Write" ]; then
    # Extract file_path from tool_input JSON
    file_path=$(echo "$input" | sed 's/\\"/"/g' | grep -o '"file_path":"[^"]*"' | head -n1 | cut -d'"' -f4)

    if [ -n "$file_path" ]; then
        basename=$(basename "$file_path")
        ext="${basename##*.}"

        # Skip pure data files (but NOT markdown, which includes agents/skills/commands)
        case "$ext" in
            txt|csv|log)
                exit 0
                ;;
        esac

        # Skip dotfiles
        case "$basename" in
            .*)  exit 0 ;;
        esac

        # Count code files anywhere (not just hardcoded source paths)
        case "$ext" in
            py|js|ts|tsx|jsx|rs|go|java|rb|sh|css|scss|html|vue|svelte|sql|c|cpp|h|md|mdx)
                work_units=1
                ;;
            json|yaml|yml|toml|ini|cfg)
                # Config files count at half weight (2 config edits = 1 unit)
                # Use a separate counter to track halves
                config_file="$state_dir/${session_id}.config_half"
                if [ -f "$config_file" ]; then
                    rm "$config_file"
                    work_units=1
                else
                    touch "$config_file"
                    exit 0
                fi
                ;;
            *)
                # Unknown extensions in source-like paths still count
                case "$file_path" in
                    */src/*|*/lib/*|*/app/*|*/components/*|*/hooks/*|*/pages/*|*/server/*|*/api/*|*/services/*|*/utils/*|*/helpers/*|*/models/*|*/controllers/*|*/routes/*|*/middleware/*|*/tools/*|*/auth/*|*/prompts/*)
                        work_units=1
                        ;;
                esac
                ;;
        esac
    fi
fi

# Bash commands that create/modify files also count
if [ "$tool_name" = "Bash" ]; then
    # Check if the command looks like it creates/installs things
    tool_input=$(echo "$input" | sed 's/\\"/"/g' | grep -o '"command":"[^"]*"' | head -n1 | cut -d'"' -f4)
    case "$tool_input" in
        *pip\ install*|*npm\ install*|*brew\ install*|*mkdir*|*mv\ *)
            work_units=1
            ;;
    esac
fi

# Nothing significant happened
if [ "$work_units" -eq 0 ]; then
    exit 0
fi

# Read current state
edits=$(grep '^edits=' "$state_file" | cut -d= -f2)
reminded=$(grep '^reminded=' "$state_file" | cut -d= -f2)
edits=$((edits + work_units))

# Update edit count
sed -i '' "s/^edits=.*/edits=$edits/" "$state_file" 2>/dev/null || {
    echo "edits=$edits" > "$state_file"
    echo "reminded=$reminded" >> "$state_file"
}

# Nudge at 3 work units, then every 8 after that
threshold=3
if [ "$reminded" -gt 0 ]; then
    threshold=$(( 3 + reminded * 8 ))
fi

if [ "$edits" -ge "$threshold" ]; then
    reminded=$((reminded + 1))
    sed -i '' "s/^reminded=.*/reminded=$reminded/" "$state_file" 2>/dev/null
    echo "MEMORY SAVE REQUIRED: You have $edits units of work without a vector memory save. Review what you have accomplished and store each significant item NOW using mcp__vector-memory__memory_store. Save criteria: (1) tasks completed, (2) decisions made, (3) bugs found or fixed, (4) gotchas or workarounds discovered, (5) errors and their solutions. Include project name as a tag. Do this before continuing with other work."
fi

exit 0
