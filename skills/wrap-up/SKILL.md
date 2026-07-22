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
3. The primary project: name and absolute path of the project this session is running in (your current working directory)
4. Excluded paths: any files the user has said not to commit this session (state "none" if there are none)
5. Instruction: "You are a wrap-up orchestrator agent. Follow the instructions in ~/.claude/agents/wrap-up-orchestrator.md"

If the user excluded files this session, list them EXPLICITLY in item 4. The agent definition enforces exclusions, but they must be named in the input.

## After Agent Returns

The agent returns JSON with `memory_delta`, `changelog_entry`, `commits`, `component_changes`, and `summary`.

### Step 1: Apply MEMORY.md delta
Apply `memory_delta` by editing the project's MEMORY.md file. The delta is structured: add each entry in `memory_delta.index_lines` to the right section of MEMORY.md (one line each), and write each item in `memory_delta.topic_files` as a separate file in the same memory directory. Do not paste paragraphs into MEMORY.md.

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

### Step 3: (retired)
The knowledge graph layer was retired 2026-07-20 (P1 simplification). Component changes are covered by MEMORY.md topic files and vector memory; no KG update is performed.

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

### Step 4c: Session archive export

Gmail metrics publish automatically after every agent run (`launch_agent.sh` runs `gmail-metrics-export.sh` at 08:08/20:08), so wrap-up does not need to export them for freshness.

After the orchestrator returns, run `/gmail-metrics-export` in its default push mode. It regenerates `src/data/gmail-metrics.json` and `src/data/session-archive.json` in cryptoflexllc and commits and pushes them itself; the main value at wrap-up time is refreshing `session-archive.json`, which agent runs do not touch. If the export or its push fails, log a warning and continue. Do not block wrap-up.

### Step 5: Display summary
Display to the user:
- Commits made (repo names, pushed status)
- If any commits failed, alert the user
- Memory status: MEMORY.md delta applied, vector memory stored (yes/no)
- Gmail metrics: exported (yes/no)
- Config drift: if `config_drift.detected` is true, suggest running `/claude-config-sync`
