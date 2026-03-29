#!/bin/bash
# memory-checkpoint.sh — Stop hook (fires when Claude's turn ends)
# Checks if significant work was done this session without vector memory saves.
# Outputs a structured checklist that the agent must evaluate before proceeding.
#
# This is the "Stop gate" in the dual-layer memory reliability system:
#   Layer 1 (mid-session): memory-nudge.sh nudges after N work units
#   Layer 2 (end-of-turn): this hook ensures nothing slips through
#
# The hook only fires once per session to avoid repeated prompts on every
# turn. After firing, it sets a "checkpoint_done" flag.
#
# Opt-out: set CLAUDE_MEMORY_CHECKPOINT=false in your environment

# Env var opt-out
if [ "${CLAUDE_MEMORY_CHECKPOINT}" = "false" ]; then
    exit 0
fi

input=$(cat)

session_id=$(echo "$input" | grep -o '"session_id":"[^"]*"' | head -n1 | cut -d'"' -f4)

if [ -z "$session_id" ]; then
    exit 0
fi

state_dir="/tmp/claude-memory-nudge"
mkdir -p "$state_dir"
nudge_state="$state_dir/${session_id}.state"
checkpoint_flag="$state_dir/${session_id}.checkpoint"

# Only fire once per session
if [ -f "$checkpoint_flag" ]; then
    exit 0
fi

# Check if any significant work happened (from memory-nudge state)
edits=0
if [ -f "$nudge_state" ]; then
    edits=$(grep '^edits=' "$nudge_state" | cut -d= -f2)
fi

# No work tracked, skip checkpoint
if [ "$edits" -lt 1 ]; then
    exit 0
fi

# Mark checkpoint as done for this session
touch "$checkpoint_flag"

# Output the structured memory checkpoint
cat <<'CHECKPOINT'
MEMORY CHECKPOINT: Before this session ends, review what you accomplished and save to vector memory. Evaluate each category:

1. TASKS COMPLETED: Did you finish any features, fixes, refactors, or config changes? Save what was done, why, and the approach taken.
2. DECISIONS MADE: Did you choose between approaches, pick a library, or make an architectural call? Save the decision and reasoning.
3. BUGS FOUND: Did you discover any bugs, broken behavior, or failing tests? Save the root cause and fix (or workaround).
4. GOTCHAS DISCOVERED: Did anything take longer than expected because of an undocumented quirk? Save it so future sessions avoid the same trap.
5. ERRORS RESOLVED: Did you encounter and fix errors? Save the error message, cause, and solution.

For each item, use mcp__vector-memory__memory_store with:
- Clear description of what happened and why
- Tags including the project name and relevant technologies
- Type: "note" for general items, "decision" for architectural choices

If you genuinely have nothing to save (pure Q&A session, no work done), state that explicitly rather than silently skipping.
CHECKPOINT

exit 0
