---
description: "Sync live ~/.claude/ config to the claude-code-config repo with parallel agents"
---

# /claude-config-sync - Config Repo Sync

You sync the live `~/.claude/` configuration to `$HOME/GitProjects/claude-code-config` (branch: `master`). No questions asked. Detect drift, copy files, update docs, commit, push.

## Phase 0: Drift Detection

Run the survey script and read the `diff.vs_config` section (the survey compares live `~/.claude/` against three repos under `diff`: `vs_mac`, `vs_cj1`, `vs_config`; this command only acts on `vs_config`):

```bash
bash ~/.claude/scripts/sync-survey.sh > /tmp/config-sync-survey.json
/opt/homebrew/bin/python3.11 - <<'PY'
import json
d = json.load(open("/tmp/config-sync-survey.json"))
v = d["diff"]["vs_config"]
new     = v.get("new_in_live", [])    # in live, not in repo  -> copy (new)
modified= v.get("diverged", [])       # differ                -> copy (modified)
deleted = v.get("new_in_config", [])  # in repo, not in live  -> git rm (deleted)
print("NEW:",      *new,      sep="\n  ")
print("MODIFIED:", *modified, sep="\n  ")
print("DELETED:",  *deleted,  sep="\n  ")
print(f"\nCONFIG_REPO: {len(new)} new, {len(modified)} modified, {len(deleted)} deleted")
PY
```

Drift count = `len(new) + len(modified) + len(deleted)`.

If drift count is 0, say "Config repo is in sync. Nothing to do." and stop.

Otherwise, display:

```
Config Repo: N new, M modified, D deleted
```

List the file names grouped by status (new, modified, deleted). `new` and `modified` come from `new_in_live` and `diverged`; `deleted` comes from `new_in_config`.

## Phase 1: Parallel Sync

Launch up to 3 parallel Task agents (subagent_type: general-purpose). Skip any agent whose work list is empty.

- **Agent 1 (File Copier):** model: haiku
- **Agent 2 (Deletion Handler):** model: haiku
- **Agent 3 (Doc Updater):** model: sonnet

### Agent 1: File Copier

Pass the `new` (new_in_live) and `modified` (diverged) arrays from the survey.

Instructions for this agent:

> You copy files from the live `~/.claude/` config to `$HOME/GitProjects/claude-code-config/`.
>
> For each file path in the provided arrays (e.g., `rules/core/memory-management.md`):
> 1. Source: `$HOME/.claude/{path}`
> 2. Destination: `$HOME/GitProjects/claude-code-config/{path}`
> 3. Security check: run `grep -lE 'sk-ant-|gho_|ghp_|github_pat_|AKIA|Bearer [A-Za-z0-9]{12,}' SOURCE`. Skip if matched.
> 4. Skip if filename matches: `*.backup`, `settings.json`, `settings.local.json`, `history.jsonl`, `observations.jsonl`
> 5. Create parent directory: `mkdir -p $(dirname DEST)`
> 6. Copy: `cp SOURCE DEST`
>
> Batch files into a single Bash call. The default shell is zsh, which does NOT word-split
> unquoted variables, so write the loop with an explicit list (or run it via `/bin/bash -c`):
> ```bash
> for f in "rules/core/memory-management.md" "skills/sync/SKILL.md"; do
>   mkdir -p "$(dirname "$HOME/GitProjects/claude-code-config/$f")"
>   cp "$HOME/.claude/$f" "$HOME/GitProjects/claude-code-config/$f"
> done
> ```
>
> Return a summary: files copied count, files skipped count, any errors.

### Agent 2: Deletion Handler

Only launch if the `deleted` (new_in_config) array is non-empty.

Pass the `deleted` array.

Instructions for this agent:

> You remove files from `$HOME/GitProjects/claude-code-config/` that no longer exist in the live config.
>
> 1. `cd $HOME/GitProjects/claude-code-config`
> 2. For each path in the deleted array, run: `git rm {path}`
> 3. Use a single `git rm` call with all paths if possible:
>    ```bash
>    cd "$HOME/GitProjects/claude-code-config" && git rm path1 path2 path3
>    ```
>
> Return a summary: files deleted count, any errors.

### Agent 3: Doc Updater

Pass the `vs_config` drift (new/modified/deleted counts) being applied.

Instructions for this agent:

> You update README.md in `$HOME/GitProjects/claude-code-config/` to reflect accurate file counts after the sync. If the sync had 0 new and 0 deleted files (modifications only), the counts are unchanged and you may report "no count changes needed".
>
> 1. Count files in each category from the live config:
>    - Rules: `find $HOME/.claude/rules -name '*.md' | wc -l`
>    - Agents: `ls $HOME/.claude/agents/*.md 2>/dev/null | grep -v backup | wc -l`
>    - Invocable skills: `find $HOME/.claude/skills -maxdepth 2 -name 'SKILL.md' | wc -l`
>    - Learned skills: `find $HOME/.claude/skills/learned -name '*.md' ! -name 'INDEX.md' 2>/dev/null | wc -l`
>    - Commands: `ls $HOME/.claude/commands/*.md 2>/dev/null | wc -l`
>    - Hooks (in repo): `ls $HOME/GitProjects/claude-code-config/hooks/*.sh 2>/dev/null | wc -l`
>    - Instincts: `find $HOME/.claude/homunculus/instincts -name '*.md' ! -name '.gitkeep' 2>/dev/null | wc -l`
> 2. Read `$HOME/GitProjects/claude-code-config/README.md`
> 3. Update any lines that reference file counts (e.g., "12 rules" becomes the new count)
> 4. Write the updated README.md
>
> Return the old and new counts for each category.

## Phase 2: Commit and Push

After all agents return successfully:

1. Check each agent's result for errors. If any agent reported errors, display them.
2. Stage and review:

```bash
cd "$HOME/GitProjects/claude-code-config" && git add -A && git status --porcelain
```

3. Build the commit message from the drift data. Use HEREDOC format:

```bash
cd "$HOME/GitProjects/claude-code-config" && git commit -m "$(cat <<'EOF'
chore: sync config from live ~/.claude/

N new, M modified, D deleted files

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

The repo has a pre-commit secret scanner (`core.hooksPath .githooks` or a `.git/hooks/pre-commit`); if it blocks the commit, inspect the flagged file rather than bypassing.

4. Push:

```bash
cd "$HOME/GitProjects/claude-code-config" && git push origin master
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
  Docs:    README.md updated (or: no count changes needed)
```

If any files were skipped due to security checks, list them with the reason.

## Important Notes

- This command targets macOS. The repo lives at `$HOME/GitProjects/claude-code-config`.
- The config repo uses branch `master`, NOT `main`.
- `claude-code-config` is PUBLIC. Beyond the token scan, sanity-check the diff for private IPs and hostnames before pushing.
- The default interactive shell is zsh, which does not word-split unquoted variables; write loops with explicit file lists, bash arrays, or `/bin/bash -c`.
- Always use HEREDOC for commit messages.
- Never copy files containing real secrets (API keys, tokens).
- Never copy `.backup` files or machine-specific settings (settings.json, settings.local.json, history.jsonl, observations.jsonl).
- This command only reconciles `vs_config`. To also align CJClaudin_Mac and CJClaude_1, run `/sync`.
- If git push fails (e.g., network), report the error. The local commit is preserved.
```
