---
platform: portable
description: "End-of-session wrap-up: update docs, persist to memory systems, commit and push all repos"
---

# /wrap-up - Session Wrap-Up

Automates end-of-session documentation updates, memory persistence, and git operations across all project repositories.

## Pre-Survey

!`bash ~/.claude/scripts/wrap-up-survey.sh`

## User Questions

Ask the user (use AskUserQuestion):
1. **Session summary:** In 2-3 sentences, what did you accomplish this session?
2. **Major changes:** Were there any architectural changes, new learnings, or pattern shifts worth documenting?

## Orchestration

After getting user answers, spawn a Task agent:
- **subagent_type:** general-purpose
- **model:** sonnet
- **name:** wrap-up-orchestrator

Pass to the agent:
1. The survey JSON output from above
2. The user's answers
3. Instruction: "You are a wrap-up orchestrator agent. Follow the instructions in ~/.claude/agents/wrap-up-orchestrator.md"

## After Agent Returns

The agent returns JSON with `memory_delta`, `changelog_entry`, `commits`, `component_changes`, and `summary`.

### Step 1: Apply MEMORY.md delta
Apply `memory_delta` by editing the project's MEMORY.md file.

### Step 2: Store session to vector memory
Call `mcp__vector-memory__memory_store` with:
- **content:** Combine the user's session summary answer with the `changelog_entry` from the agent. Format:
  ```
  Session: [date]
  Summary: [user's session summary answer]
  Changes: [changelog_entry "What changed" bullets]
  Learnings: [changelog_entry "What was learned" bullets]
  ```
- **metadata:**
  - tags: `wrap-up,session-summary,[primary project name],[date YYYY-MM-DD]`
  - type: `session-summary`

If the MCP call fails, log a warning and continue. Do not block wrap-up.

### Step 3: Targeted Knowledge Graph update
If `component_changes` array is non-empty:

1. For each component in the array, call `mcp__memory__search_nodes` with the component name to check if an entity already exists.
2. **Batch new entities:** Collect all components that DON'T exist in KG. Call `mcp__memory__create_entities` once with all new entities:
   - `name`: The component name (e.g., "bridge-launcher.sh")
   - `entityType`: The type from survey (Agent, Skill, Hook, Command, Script)
   - `observations`: Read the file briefly and generate 2-3 observations (file path, purpose, creation date)
3. **Batch observation updates:** For components that DO exist, call `mcp__memory__add_observations` once with updated observations noting what changed.
4. **Add obvious relations:** If a new agent is used by a skill, or a new script supports an agent, call `mcp__memory__create_relations`.

If the MCP call fails, log a warning and continue. Do not block wrap-up.

### Step 4: Touch marker file
Run: `touch ~/.claude/.last-wrap-up-timestamp`

This sets the reference point for the next wrap-up's component change detection.

### Step 4b: Evolution nudge

Check for new instincts since the last evolution run:

```bash
EVOLVE_MARKER="$HOME/.claude/homunculus/.last-evolve-timestamp"
if [ -f "$EVOLVE_MARKER" ]; then
    NEW_INSTINCTS=$(find "$HOME/.claude/homunculus/instincts/personal" -name "*.md" -newer "$EVOLVE_MARKER" 2>/dev/null | wc -l | tr -d ' ')
else
    NEW_INSTINCTS=$(ls "$HOME/.claude/homunculus/instincts/personal"/*.md 2>/dev/null | wc -l | tr -d ' ')
fi
echo "$NEW_INSTINCTS"
```

If the count is greater than 0, include this line in the Step 5 summary:

> **Evolution ready:** N new instinct(s) since last evolution. Run `/evolve` to generate skill/agent/command candidates.

### Step 4c: Dashboard Export

After all commits are pushed, run `/dashboard-export --no-push` to update the SNES environment dashboard data files in the cryptoflexllc repo. The cryptoflexllc commit from Step 4 will push the data along with any other changes.

If the cryptoflexllc repo was not modified in this session, run `/dashboard-export` (with push) to trigger a standalone Vercel rebuild with fresh data.

### Step 5: Display summary
Display to the user:
- Commits made (repo names, pushed status)
- If any commits failed, alert the user
- Memory status: MEMORY.md delta applied, vector memory stored (yes/no), KG entities updated (count)
- Dashboard: data exported (yes/no)
- Config drift: if `config_drift.detected` is true, suggest running `/claude-config-sync`
