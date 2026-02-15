---
description: "End-of-session wrap-up: update docs, clean up, commit and push all repos"
---

# /wrap-up - End of Session Wrap-Up

You are an end-of-session wrap-up agent. Document the session, clean up artifacts, and push changes to GitHub.

## Repository Locations

| Repo | Local Path | Remote | Branch |
|------|-----------|--------|--------|
| CJClaude_1 | `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\CJClaude_1` | `chris2ao/CJClaude_1` (public) | main |
| cryptoflexllc | `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\cryptoflexllc` | `chris2ao/cryptoflexllc` (public) | main |
| cryptoflex-ops | `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\cryptoflex-ops` | `chris2ao/cryptoflex-ops` (private) | main |
| claude-code-config | `D:\Users\chris_dnlqpqd\.claude` | `chris2ao/claude-code-config` (private) | master |

## Phase 1: Survey

Run `git pull`, `git status`, and `git diff --stat` on ALL four repos **in parallel** (4 Bash calls in one message). Report which repos have changes before proceeding.

If a pull fails due to conflicts, STOP and alert the user.

## Phase 2: Document

### 2a. Review session context
Analyze the conversation history. Identify: tasks completed, lessons learned, failures, config changes.

### 2b. Update CJClaude_1 CHANGELOG.md
Read only the **first 30 lines** (for format reference). Add a new dated entry at the TOP:

```markdown
## YYYY-MM-DD - [Brief title]

### What changed
- **Action verb** description with technical details

### What was learned
- Key takeaways, gotchas, debugging insights

---
```

Action verbs: **Fixed**, **Added**, **Removed**, **Configured**, **Extracted**, **Refactored**, **Updated**. Document failures, not just successes.

### 2c. Update CJClaude_1 README.md (significant work only)
Read only the **last 50 lines** to find the latest Phase number. Add a new Phase entry only for significant work (new features, architectural changes). Skip for config tweaks, minor fixes, or documentation-only sessions.

### 2d. Update MEMORY.md (if applicable)
Update if new skills, architecture changes, repos, or blog posts were added. Keep under 200 lines.

**Both** MEMORY.md files may need updates:
- Current project: auto-loaded MEMORY.md (whichever project this session is in)
- CJClaude_1: `D:\Users\chris_dnlqpqd\.claude\projects\d--Users-chris-dnlqpqd-OneDrive-AI-Projects-Claude-CJClaude-1\memory\MEMORY.md`

## Phase 3: Clean

### 3a. Run cleanup script
```bash
bash ~/.claude/scripts/cleanup-session.sh
```
This deletes transcript `.jsonl` files and stale todo `.json` files automatically.

### 3b. Settings bloat check (conditional)
Read `settings.local.json` in the current project. **Only clean up if >30 permission entries.** When cleaning:
- Keep: wildcard permissions (`Bash(git:*)`), WebFetch domains, MCP tools, hooks
- Remove: one-off specific commands, entries covered by existing wildcards, session-specific paths

If 30 or fewer entries, skip this step.

## Phase 4: Commit & Push

### 4a. Skill extraction (opt-in)
Ask the user: "Any patterns from this session worth extracting as a learned skill?" If yes, create skill files at `~/.claude/skills/learned/[name].md`. If no, skip.

### 4b. Commit all repos with changes
For each repo with changes, stage relevant files and commit. Use conventional commit format (`docs:`, `feat:`, `fix:`, `chore:`) with Hulk Hogan persona in the body. Always include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`.

```bash
git commit -m "$(cat <<'EOF'
type: Brief description

[Hulk Hogan persona body with technical details]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

### 4c. Push (with confirmation)
Show which repos have commits ready (repo name + one-line commit summary). **Wait for user confirmation**, then push all:
```bash
export PATH="$PATH:/c/Program Files/GitHub CLI" && git push
```

## Phase 5: Report

Present a summary table:

| Repo | Action | Commit | Status |
|------|--------|--------|--------|
| CJClaude_1 | Updated CHANGELOG | abc1234 | Pushed |
| ... | ... | ... | ... |

## Important Notes

- **Never commit secrets.** STOP and alert if tokens, keys, or passwords are found in staged files.
- **Never force push.**
- **PowerShell from Git Bash:** Write temp `.ps1` files for commands with `$` variables.
- **Preserve history.** Never delete changelog entries or README phases. Append only.
