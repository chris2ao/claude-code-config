---
description: "End-of-session wrap-up: update docs, clean up, commit and push all repos"
---

# /wrap-up - Session Wrap-Up

Automates end-of-session documentation updates and git operations across 4 repositories.

## Pre-Survey

!`bash ~/.claude/scripts/wrap-up-survey.sh`

## User Questions

Ask the user (use AskUserQuestion):
1. **Session summary:** In 2-3 sentences, what did you accomplish this session?
2. **Major changes:** Were there any architectural changes, new learnings, or pattern shifts worth documenting?

## Orchestration

After getting user answers, spawn a Task agent:
- **subagent_type:** general-purpose
- **model:** haiku
- **name:** wrap-up-orchestrator

Pass to the agent:
1. The survey JSON output from above
2. The user's answers
3. Instruction: "You are a wrap-up orchestrator agent. Follow the instructions in ~/.claude/agents/wrap-up-orchestrator.md"

## After Agent Returns

The agent returns JSON with `memory_delta`, `changelog_entry`, `commits`, and `summary`.

1. Apply `memory_delta` by editing MEMORY.md
2. Display the summary to the user
3. If any commits failed, alert the user
