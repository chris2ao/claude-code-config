---
id: permission-path-consistency
trigger: "when defining permission strings in Claude Code settings.local.json"
confidence: 0.5
domain: "claude-code"
source: "session-archive-ingestion"
created: "2026-03-14"
---

# Use Consistent Path Forms in Permission Entries

## Action
When adding Bash or script paths to `allowedTools` or hook definitions in `settings.local.json`, use a single consistent path form throughout. Claude Code uses string-exact matching for permissions, so `~/.claude/scripts/foo.sh`, `$HOME/.claude/scripts/foo.sh`, and `/Users/chris2ao/.claude/scripts/foo.sh` are three different permission entries.

## Pattern
1. Pick one form for the project (tilde `~`, `$HOME`, or absolute)
2. Use that form in ALL permission entries, hook command paths, and allowedTools
3. When adding new entries, check existing ones for the established convention
4. On Windows, paths use forward slashes in Git Bash but backslashes in PowerShell; match the execution context

## Evidence
- 2026-02-15: Permission mismatches caused by mixed path forms in settings. Scripts were allowed under one path form but invoked under another, triggering unnecessary permission prompts.
