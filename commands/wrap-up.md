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

First, run `git pull` on ALL four repos in parallel to ensure local copies are in sync with GitHub. Then run `git status` and `git diff --stat` on all four repos. Identify which repos have changes (staged, unstaged, or untracked files). Report findings to the user before proceeding.

If a pull fails due to conflicts, STOP and alert the user. Do not attempt to auto-resolve merge conflicts.

**Important:** Use `export PATH="$PATH:/c/Program Files/GitHub CLI"` before any `gh` or `git push` commands.

### Step 2: Review Session Context

Analyze the conversation history to identify:
- What tasks were completed
- What was learned (new patterns, gotchas, fixes)
- What failed and why
- Any new learned skills extracted
- Any config changes made
- Any security-relevant actions taken

Compile a concise summary of the session.

### Step 3: Update CJClaude_1 CHANGELOG.md

Add a new dated entry at the TOP of the changelog (below the header). Follow the existing format exactly:

```markdown
## YYYY-MM-DD - [Brief descriptive title]

### What changed
- **Action verb** description of what was done
- (list all significant changes)

### What was learned
1. Numbered list of key takeaways
2. Include gotchas, workarounds, and debugging insights

---
```

Rules:
- Use bold action verbs: **Fixed**, **Added**, **Removed**, **Configured**, **Extracted**, **Validated**, **Cleaned up**
- Include technical details (file paths, error messages, token types, commands)
- Document failures and dead ends, not just successes
- If security actions were taken, add a `### Security note` subsection

### Step 4: Update CJClaude_1 README.md

If the session involved significant new work (not just minor fixes), add a new Phase entry to the narrative in README.md. Follow the existing narrative style:
- Brief paragraph describing what happened and why
- Mention key technical details
- Note any architectural decisions or direction changes

If the session was minor (config tweaks, small fixes), skip this step and note that no README update was needed.

### Step 5: Update MEMORY.md

Update `D:\Users\chris_dnlqpqd\.claude\projects\D--Users-chris-dnlqpqd-OneDrive-AI-Projects-Claude-CJClaude-1\memory\MEMORY.md` if:
- New learned skills were extracted (update the skills count and list)
- New key learnings were discovered (add to Key Learnings section)
- Project architecture changed
- New repos were created
- Blog posts were added

Keep MEMORY.md under 200 lines. Be concise.

### Step 6: Clean Up Global State

Clean accumulated Claude Code data that causes bloat and can trigger interactive mode freezes:

1. **`~/.claude/projects/` transcripts:** For each project directory under `~/.claude/projects/`, delete all `.jsonl` transcript files and session subdirectories (UUIDs), keeping ONLY the `memory/` directory and its contents.

2. **`~/.claude/todos/` stale files:** Delete all `*.json` files in `~/.claude/todos/`.

Report what was cleaned (file counts and space freed).

### Step 7: Clean Up settings.local.json

Read `.claude/settings.local.json` in CJClaude_1 and remove accumulated one-off permission entries. Keep:
- General wildcard permissions (`Bash(git:*)`, `Bash(npm:*)`, etc.)
- WebSearch and WebFetch domain permissions
- MCP tool permissions
- Hook configurations (never modify hooks)

Remove:
- Very specific one-off Bash commands (e.g., `Bash("C:\\Program Files\\..." specific-command)`)
- Redundant entries already covered by wildcards (e.g., `Bash(git add:*)` is covered by `Bash(git:*)`)
- Session-specific file paths in permission entries

### Step 8: Update Other Repos (if applicable)

For each repo with changes:
- **cryptoflexllc**: If site changes were made, ensure build passes before committing
- **cryptoflex-ops**: If deployment or operational changes were documented
- **claude-code-config**: If new skills were extracted or rules were modified, stage and commit them

### Step 9: Commit All Changes

For each repo with changes, create commits following conventional commit format:
- `docs:` for changelog, readme, documentation updates
- `fix:` for bug fixes
- `feat:` for new features
- `chore:` for cleanup and maintenance

**CRITICAL: Commit message body must be written in the persona of Hulk Hogan.** The subject line stays professional (conventional commit format), but the body should be a detailed explanation of the changes and why they were made, written as if Hulk Hogan himself is explaining what went down. Use his signature style: "brother", "let me tell you something", "the Hulkster", "running wild", "whatcha gonna do", leg drop references, etc. Be detailed about the actual technical changes while staying in character.

Always include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>` in commit messages.

Use HEREDOC format for multi-line commit messages:
```bash
git commit -m "$(cat <<'EOF'
type: Brief description

Let me tell you something, brother! The Hulkster just ran wild on
this codebase and here's what went down...

[Detailed technical changes written in Hulk Hogan's voice]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

### Step 10: Push to GitHub

**Ask the user for confirmation before pushing.** Show them:
- Which repos have commits ready to push
- A one-line summary of each commit

Then push all repos. Use:
```bash
export PATH="$PATH:/c/Program Files/GitHub CLI" && git push
```

### Step 11: Final Report

Present a summary table:

```
| Repo | Action | Commit | Status |
|------|--------|--------|--------|
| CJClaude_1 | Updated CHANGELOG, README | abc1234 | Pushed |
| claude-code-config | Added skill #8 | def5678 | Pushed |
| cryptoflexllc | No changes | - | Clean |
| cryptoflex-ops | No changes | - | Clean |
```

## Important Notes

- **Never commit secrets.** If you find tokens, keys, or passwords in staged files, STOP and alert the user.
- **Never force push.** Always use regular `git push`.
- **PowerShell from Git Bash:** If you need to run PowerShell with `$` variables, write a temp `.ps1` file and execute with `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "path.ps1"`. Delete the temp file after. Git Bash strips `$` from inline PowerShell commands.
- **Git push PATH:** Always `export PATH="$PATH:/c/Program Files/GitHub CLI"` before push commands.
- **Read before editing.** Always read files before modifying them.
- **Preserve history.** Never delete changelog entries or README phases. Append only.
