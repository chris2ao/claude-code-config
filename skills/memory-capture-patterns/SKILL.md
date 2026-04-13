---
platform: portable
description: "Operational patterns for continuous vector memory capture using hooks and save cadence rules"
---

# /memory-capture-patterns - Memory Capture Enforcement

Activate when implementing memory persistence rules, designing hooks for context capture, or when a session is accumulating significant work without explicit vector memory saves.

## Steps

### 1. Save Cadence: Continuous, Not End-of-Session

Do not accumulate saves for session end. Hard kills skip exit hooks, losing all unsaved context. Monolithic end-of-session saves are also harder to search and more error-prone.

Save to vector memory every 20-30 units of significant work, where one unit is a feature completed, architectural decision made, gotcha discovered, bug resolved, or error fixed. This is not every file edit.

When the memory nudge fires, treat it as a mandatory checkpoint trigger, not an optional reminder.

Anti-pattern to avoid: accumulating 100+ work units and then trying to save everything at once. Results in oversized memory entries, risk of total context loss on unexpected termination, and memory fatigue where the backlog feels too large to tackle.

### 2. Enforce via PostToolUse Hooks (Not Stop/SessionEnd)

Use PostToolUse hooks for incremental memory saves. Stop and SessionEnd hooks do not fire on hard terminal kills (Ctrl+C or process kill). PostToolUse fires after every tool completes, so context is saved incrementally even if the session terminates ungracefully.

Stop and SessionEnd hooks are supplementary checkpoints, not the primary save mechanism.

### 3. Memory Nudge Hook Implementation

Implement a PostToolUse hook that tracks edit count and injects a nudge at thresholds:

1. Hook fires on Edit/Write to `src/` files only (skip config/docs to reduce noise)
2. Increment a counter stored in a temp file (e.g., `/tmp/.claude-edit-count`)
3. At threshold (default: 5 edits), inject a reminder to save context to vector memory
4. Use escalating message urgency at higher thresholds (15, 25, 35)
5. On `memory_store` tool call, reset counter to 0

This enforces memory persistence without requiring manual discipline.

## Source Instincts

- `memory-save-cadence`: "when work accumulates past 50 units without explicit vector memory save"
- `memory-nudge-hook`: "when implementing context persistence rules"
- `postToolUse-resilience`: "when designing session-end memory capture that must survive Ctrl+C"
