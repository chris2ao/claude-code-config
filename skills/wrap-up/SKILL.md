---
description: "End-of-session wrap-up: update docs, clean up, commit and push all repos"
---

# /wrap-up - End of Session Documentation & Cleanup

You are an end-of-session wrap-up agent. Your job is to document everything that was done in this session, clean up accumulated artifacts, and push all changes to GitHub.

## Repository Locations

| Repo | Local Path | Remote | Purpose |
|------|-----------|--------|---------|
| CJClaude_1 | `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\CJClaude_1` | `chris2ao/CJClaude_1` (public) | Learning journal, changelog, session history |
| cryptoflexllc | `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\cryptoflexllc` | `chris2ao/cryptoflexllc` (public) | CryptoFlex LLC website |
| cryptoflex-ops | `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\cryptoflex-ops` | `chris2ao/cryptoflex-ops` (private) | Deployment and operational docs |
| claude-code-config | `D:\Users\chris_dnlqpqd\.claude` | `chris2ao/claude-code-config` (private) | Claude Code rules, skills, config |

## Execution Steps

Run these in order. Do NOT skip steps. Ask the user before pushing.

### Step 1: Pull Latest and Survey All Repos

Run `git pull` on ALL four repos in parallel. Then run `git status` and `git diff --stat` on all four repos. Report findings before proceeding.

If a pull fails due to conflicts, STOP and alert the user.

**Important:** Use `export PATH="$PATH:/c/Program Files/GitHub CLI"` before any `gh` or `git push` commands.

### Step 2: Review Session Context

Analyze the conversation history to identify:
- What tasks were completed
- What was learned (new patterns, gotchas, fixes)
- What failed and why
- Any new learned skills extracted
- Any config changes made

### Step 3: Update CJClaude_1 CHANGELOG.md

Add a new dated entry at the TOP of the changelog. Use bold action verbs: **Fixed**, **Added**, **Removed**, **Configured**, **Extracted**. Include technical details and document failures.

### Step 4: Update CJClaude_1 README.md

If significant new work, add a new Phase entry to the narrative. Skip for minor fixes.

### Step 5: Update MEMORY.md

Update if new skills, learnings, architecture changes, repos, or blog posts were added. Keep under 200 lines.

### Step 6: Extract Learned Skills

Look for non-obvious error resolutions, debugging techniques, workarounds, and integration patterns. Create skill files at `~/.claude/skills/learned/[pattern-name].md`. Ask user to confirm before saving.

### Step 7: Clean Up Global State

1. Delete `.jsonl` transcript files from `~/.claude/projects/` (keep `memory/` dirs)
2. Delete `*.json` from `~/.claude/todos/`

### Step 8: Clean Up settings.local.json

Remove accumulated one-off permission entries. Keep wildcards, WebFetch domains, MCP tools, and hooks.

### Step 9: Update Other Repos (if applicable)

Commit changes in cryptoflexllc, cryptoflex-ops, claude-code-config as needed.

### Step 10: Commit All Changes

Use conventional commit format with Hulk Hogan persona in the body. Always include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`.

### Step 11: Push to GitHub

Ask user for confirmation first. Show which repos have commits ready.

### Step 12: Final Report

Present a summary table of all repos, actions, commits, and status.

## Important Notes

- **Never commit secrets.** STOP and alert if found.
- **Never force push.**
- **PowerShell from Git Bash:** Write temp .ps1 files for `$` variables.
- **Git push PATH:** Always `export PATH="$PATH:/c/Program Files/GitHub CLI"` first.
- **Preserve history.** Never delete changelog entries or README phases.
