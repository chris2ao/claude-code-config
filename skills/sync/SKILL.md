---
description: "Sync Claude Code config to claude-code-config and CJClaudin_home repos"
---

# /sync - Config Sync

Compares your live `~/.claude/` configuration against two target repos and syncs any drift:
- **claude-code-config** (public, `master`): Reference config for other Claude Code users
- **CJClaudin_home** (private, `main`): Portable config package with install.sh

## Pre-Survey

!`bash ~/.claude/scripts/sync-survey.sh`

## Present Drift Summary

Show the user a concise drift summary from the survey JSON:

```
Config Repo:  N new, M modified, D deleted (or "clean")
Home Repo:    N new, M modified, D deleted (or "clean")
```

If both are clean, say so and stop. No need to proceed further.

## User Questions

Ask the user (use AskUserQuestion):

1. **Sync target:** Which repo(s) should we sync?
   - Both (Recommended)
   - claude-code-config only
   - CJClaudin_home only

2. **Action:** What should we do after copying files?
   - Commit and push (Recommended)
   - Review diff first
   - Just copy files, no git operations

## Orchestration

After getting user answers, spawn a Task agent:
- **subagent_type:** general-purpose
- **model:** haiku
- **name:** sync-orchestrator

Pass to the agent:
1. The survey JSON output from above
2. The user's target choice and action choice
3. Instruction: "You are a sync orchestrator agent. Follow the instructions in ~/.claude/agents/sync-orchestrator.md"

## After Agent Returns

The agent returns JSON with `config_result`, `home_result`, and `summary`.

1. Display the summary to the user (files copied, commits created, push status)
2. If any errors occurred, alert the user with details
3. If the user chose "Review diff first", show the diff output and ask whether to proceed with commit/push
