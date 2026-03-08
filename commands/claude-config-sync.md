---
description: "Sync live ~/.claude/ config to the claude-code-config repo with parallel agents"
---

# /claude-config-sync - Config Repo Sync

You sync the live `~/.claude/` configuration to `C:/ClaudeProjects/claude-code-config` (branch: `master`). No questions asked. Detect drift, copy files, update docs, commit, push.

## Phase 0: Drift Detection

Run the survey script with Windows path override:

```bash
PROJECTS_DIR=/c/ClaudeProjects bash ~/.claude/scripts/sync-survey.sh
```

Parse the JSON output. Extract only the `config_repo` section.

If `drift_count` is 0, say "Config repo is in sync. Nothing to do." and stop.

Otherwise, display:

```
Config Repo: N new, M modified, D deleted (U unchanged)
```

List the file names grouped by status (new, modified, deleted).

## Phase 1: Parallel Sync

Launch up to 3 parallel Task agents (model: haiku, subagent_type: general-purpose). Skip any agent whose work list is empty.

### Agent 1: File Copier

Pass the `new` and `modified` arrays from the survey.

Instructions for this agent:

> You copy files from the live `~/.claude/` config to `C:/ClaudeProjects/claude-code-config/`.
>
> For each file path in the provided arrays (e.g., `rules/core/memory-management.md`):
> 1. Source: `$HOME/.claude/{path}`
> 2. Destination: `/c/ClaudeProjects/claude-code-config/{path}`
> 3. Security check: run `grep -l 'sk-ant-\|gho_\|ghp_\|AKIA\|Bearer [A-Za-z0-9]' SOURCE`. Skip if matched.
> 4. Skip if filename matches: `*.backup`, `settings.json`, `settings.local.json`, `history.jsonl`, `observations.jsonl`
> 5. Create parent directory: `mkdir -p $(dirname DEST)`
> 6. Copy: `cp SOURCE DEST`
>
> Batch files into a single Bash call per category to minimize tool calls. Use a loop:
> ```bash
> for f in file1 file2 file3; do
>   mkdir -p "$(dirname "/c/ClaudeProjects/claude-code-config/$f")"
>   cp "$HOME/.claude/$f" "/c/ClaudeProjects/claude-code-config/$f"
> done
> ```
>
> Return a summary: files copied count, files skipped count, any errors.

### Agent 2: Deletion Handler

Only launch if the `deleted` array is non-empty.

Pass the `deleted` array.

Instructions for this agent:

> You remove files from `C:/ClaudeProjects/claude-code-config/` that no longer exist in the live config.
>
> 1. `cd /c/ClaudeProjects/claude-code-config`
> 2. For each path in the deleted array, run: `git rm {path}`
> 3. Use a single `git rm` call with all paths if possible:
>    ```bash
>    cd /c/ClaudeProjects/claude-code-config && git rm path1 path2 path3
>    ```
>
> Return a summary: files deleted count, any errors.

### Agent 3: Doc Updater

Pass the full `config_repo` section of the survey JSON plus the drift being applied.

Instructions for this agent:

> You update README.md in `C:/ClaudeProjects/claude-code-config/` to reflect accurate file counts after the sync.
>
> 1. Count files in each category from the live config:
>    - Rules: `find $HOME/.claude/rules -name '*.md' | wc -l`
>    - Agents: `ls $HOME/.claude/agents/*.md 2>/dev/null | grep -v backup | wc -l`
>    - Invocable skills: `find $HOME/.claude/skills -maxdepth 2 -name 'SKILL.md' | wc -l`
>    - Learned skills: `find $HOME/.claude/skills/learned -name '*.md' ! -name 'INDEX.md' 2>/dev/null | wc -l`
>    - Commands: `ls $HOME/.claude/commands/*.md 2>/dev/null | wc -l`
>    - Hooks (in repo): `ls /c/ClaudeProjects/claude-code-config/hooks/*.sh 2>/dev/null | wc -l`
>    - Instincts: `find $HOME/.claude/homunculus/instincts -name '*.md' ! -name '.gitkeep' 2>/dev/null | wc -l`
> 2. Read `/c/ClaudeProjects/claude-code-config/README.md`
> 3. Update any lines that reference file counts (e.g., "12 rules" becomes the new count)
> 4. Write the updated README.md
>
> Return the old and new counts for each category.

## Phase 2: Commit and Push

After all agents return successfully:

1. Check each agent's result for errors. If any agent reported errors, display them.
2. Stage and review:

```bash
cd /c/ClaudeProjects/claude-code-config && git add -A && git status --porcelain
```

3. Build the commit message from the drift data. Use HEREDOC format:

```bash
cd /c/ClaudeProjects/claude-code-config && git commit -m "$(cat <<'EOF'
chore: sync config from live ~/.claude/

N new, M modified, D deleted files

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

4. Push:

```bash
cd /c/ClaudeProjects/claude-code-config && git push origin master
```

## Phase 3: Report

Display a final summary:

```
Config Sync Complete
  Copied:  N files
  Deleted: D files
  Skipped: S files
  Commit:  {sha}
  Pushed:  origin/master
  Docs:    README.md updated
```

If any files were skipped due to security checks, list them with the reason.

## Important Notes

- The config repo uses branch `master`, NOT `main`
- Always use HEREDOC for commit messages
- Never copy files containing real secrets (API keys, tokens)
- Never copy `.backup` files or machine-specific settings
- The survey script needs `PROJECTS_DIR=/c/ClaudeProjects` on Windows
- If git push fails (e.g., network), report the error. The local commit is preserved.
