# HEREDOC Commit Messages Can Pollute Auto-Approved Permissions

**Extracted:** 2026-02-09
**Context:** Using `git commit -m "$(cat <<'EOF' ... EOF)"` with Claude Code's auto-approve system

## Problem
When using HEREDOC syntax for multi-line git commit messages, Claude Code's auto-approve mechanism captures the entire Bash command string — including the HEREDOC body — as a permission entry in `.claude/settings.local.json`. If the commit body contains parentheses, backslashes, or text resembling tool patterns, it creates garbage permission entries.

Example of what gets captured:
```json
"Bash(Up Global State\" - so this kind of accumulation never happens again,\nbrother! Also cleaned up 7 one-off permission entries in\nsettings.local.json and replaced them with a single Bash\\(export PATH:*\\)\nwildcard...)"
```

This pollutes the permissions array with nonsensical entries that persist across sessions.

## Solution
After any HEREDOC commit, check `settings.local.json` for new garbage entries:

1. Read `.claude/settings.local.json` after committing
2. Look for permission entries that contain commit message text
3. Remove any entries that aren't intentional wildcard patterns
4. The `/wrap-up` command's Step 7 handles this automatically

## Prevention
- The auto-approve system parses the full Bash command text, not just the binary name
- HEREDOC bodies with `(`, `)`, `\(`, `\)` are especially prone to being misinterpreted
- Consider using shorter commit messages for auto-approved sessions, or clean up after

## When to Use
- After using `git commit -m "$(cat <<'EOF' ... EOF)"` with auto-approve enabled
- When `settings.local.json` has unexpectedly large or nonsensical permission entries
- During end-of-session cleanup (Step 7 of /wrap-up)
