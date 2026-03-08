---
id: memory-nudge-hook
trigger: "when implementing context persistence rules"
confidence: 0.4
domain: "claude-code"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Memory Nudge Hook Pattern

## Action
Add a PostToolUse hook that tracks source file edit count and injects a nudge after a threshold (5 edits). Escalate at 15/25/35. Reset counter on memory_store call.

## Pattern
1. Hook fires on Edit/Write to src/ files only (skip config/docs)
2. Increment counter in temp file
3. At threshold, inject reminder to save context to vector memory
4. On memory_store tool call, reset counter to 0
5. Escalating messages at higher thresholds

## Evidence
- 2026-03-05: Automatic enforcement of memory persistence. Ensures context is saved continuously without manual discipline.
