---
platform: portable
description: "Bidirectional config sync across repos"
---

# /sync - Bidirectional Config Sync

Compares your live `~/.claude/` configuration against three repos and syncs drift in either direction:
- **CJClaudin_Mac** (private, `main`): macOS config with install.sh
- **CJClaude_1** (private, `main`): Primary config documentation repo
- **claude-code-config** (public, `master`): Reference config (union of both platforms)

## Step 1: Run Bidirectional Inventory

!`bash ~/.claude/scripts/sync-survey.sh`

## Step 2: Present Drift Summary

Parse the survey JSON and show the user a concise drift summary:

```
Live vs CJClaudin_Mac:      N new in live, M new in mac, D diverged
Live vs CJClaude_1:         N new in live, M new in cj1, D diverged
Live vs claude-code-config: N new in live, M new in config, D diverged
```

If all are clean, say so and stop.

## Step 3: Ask User

Use AskUserQuestion for each:

1. **Sync direction:**
   - Bidirectional (recommended): push new items from live, pull new items from repos
   - Push only: live -> repos
   - Pull only: repos -> live

2. **Target repos:**
   - All three (recommended)
   - CJClaudin_Mac only
   - CJClaude_1 only
   - claude-code-config only

3. **Action after sync:**
   - Commit and push (recommended)
   - Review diff first
   - Just copy files, no git

## Step 4: Orchestrate

Spawn a Task agent:
- **subagent_type:** general-purpose
- **name:** sync-orchestrator

Pass to the agent:
1. The survey JSON output
2. The user's direction, target, and action choices
3. Instruction: "Follow the instructions in ~/.claude/agents/sync-orchestrator.md"

## Step 5: Display Results

The agent returns JSON with classified files, actions taken, and git status.

1. Show summary: files synced, security blocks, platform skips
2. If any files were flagged for capability review, show details and ask if the user wants to accept them
3. If any files were blocked by security scan, list them with the reason
4. If the user chose "Review diff first", show the diff and ask whether to proceed with commit/push
5. Report final commit SHAs and push status per repo

## Step 6: Update claude-code-config Documentation

If claude-code-config was a sync target and files were added or changed, spawn a doc-updater agent:
- **subagent_type:** general-purpose
- **model:** haiku
- **name:** config-doc-updater

Pass to the agent:
1. The list of new, changed, and removed files in claude-code-config
2. Instruction: "Read README.md and COMPLETE-GUIDE.md in ~/GitProjects/claude-code-config/. Update both to reflect the synced changes: add new agents/hooks/scripts/skills to the relevant tables, update counts, remove entries for deleted items. Keep edits minimal and match existing style. Never use em dashes. Commit and push to master with message: docs: update README and COMPLETE-GUIDE for synced changes"

After the agent returns, report which sections were updated.
