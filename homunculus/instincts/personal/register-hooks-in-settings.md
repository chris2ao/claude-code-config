---
id: register-hooks-in-settings
trigger: "when creating hook scripts for Claude Code"
confidence: 0.6
domain: "claude-code"
source: "session-archive-ingestion"
created: "2026-03-07"
---

# Always Register Hooks in settings.json

## Action
After creating or placing hook scripts in `~/.claude/hooks/`, always verify they are registered in `~/.claude/settings.json` (global) or `.claude/settings.local.json` (project-level) under the `hooks` key. Scripts without registration are inert and will never fire.

## Pattern
1. Create the hook script in the hooks directory
2. Open `settings.json` and verify a `hooks` entry exists for the correct event type
3. Event types: `PreToolUse`, `PostToolUse`, `Stop`, `SessionEnd`
4. Each hook entry needs: `type` (command), `command` (shell command to run), and optionally `matcher` (tool name filter)
5. Global hooks in `~/.claude/settings.json` apply to ALL projects, including future ones
6. Project hooks in `.claude/settings.local.json` apply only to that project

## Evidence
- 2026-03-07: Five hook scripts existed in `~/.claude/hooks/` (file-guard, log-activity, observe-homunculus, prompt-notify, save-session) but none were firing because `settings.json` had no `hooks` key. Adding the registration entries made all five scripts active.
