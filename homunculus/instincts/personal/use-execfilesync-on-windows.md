---
id: use-execfilesync-on-windows
trigger: "when using execSync with format strings containing %, ^, !, or & on Windows"
confidence: 0.5
domain: "windows/node"
source: "session-archive-ingestion"
created: "2026-03-07"
---

# Use execFileSync Instead of execSync on Windows

## Action
When running shell commands on Windows that contain special characters (especially `%` in git format strings), use `execFileSync(command, argsArray)` instead of `execSync(commandString)` to bypass shell interpretation.

## Pattern
1. Identify commands with `%` (git --format), `^`, `!`, or `&` characters
2. Replace `execSync('git log --format="%H %s"')` with `execFileSync('git', ['log', '--format=%H %s'])`
3. This bypasses cmd.exe, which interprets `%` as environment variable delimiters

## Evidence
- 2026-02-27: `execSync('git log --format="%H|%s|%an|%ai"')` produced empty output because cmd.exe ate the `%` characters. Switching to `execFileSync('git', ['log', '--format=%H|%s|%an|%ai'])` fixed it immediately.
