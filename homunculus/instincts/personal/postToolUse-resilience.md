---
id: postToolUse-resilience
trigger: "when designing session-end memory capture that must survive Ctrl+C"
confidence: 0.4
domain: "claude-code"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Use PostToolUse for Resilient Memory Capture

## Action
Use PostToolUse hooks for incremental memory saves, not Stop or SessionEnd hooks. PostToolUse fires after every tool completes, so context is saved continuously even if session terminates ungracefully.

## Pattern
1. PostToolUse hook tracks edits to source files
2. After threshold (e.g., 5 edits), nudge to save context
3. On memory_store call, reset counter
4. Stop/SessionEnd hooks are supplementary, not primary

## Evidence
- 2026-03-05: Stop/SessionEnd hooks don't fire on hard terminal kills (Ctrl+C). PostToolUse-based memory nudge ensures context is saved incrementally.
