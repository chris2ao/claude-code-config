---
id: openclaw-memorysearch
trigger: "when configuring memory search in OpenClaw"
confidence: 0.4
domain: "openclaw"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# memorySearch Goes Under agents.defaults

## Action
Place memorySearch configuration under `agents.defaults` in openclaw.json, not as a top-level key. Top-level placement is silently ignored.

## Pattern
1. Correct: `{ "agents": { "defaults": { "memorySearch": { ... } } } }`
2. Wrong: `{ "memorySearch": { ... } }` (top-level, silently ignored)
3. Also wrong: `{ "agents": { "memorySearch": { ... } } }` (wrong nesting level)

## Evidence
- 2026-03-06: memorySearch config was top-level and agents had no memory search capability. Moving to agents.defaults fixed it.
