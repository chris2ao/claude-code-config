---
platform: portable
description: "Vector memory architecture, capture cadence, hooks, and retention for Claude sessions"
---

# /memory-architecture - Claude Memory System Design

Activate when setting up persistent memory for Claude sessions, configuring the vector memory MCP server, designing hooks for context capture, when a session is accumulating significant work without explicit vector memory saves, or when a debugging session is going in circles and context is needed across session boundaries.

## Steps

### 1. Two-Tier Architecture

Single-layer memory fails because it relies on manual discipline and does not survive hard kills. Implement both tiers:

**Tier 1: Rules (what to remember)**
- Rules in `CLAUDE.md` and `rules/` directories define triggers ("after completing a significant task...")
- Rules tell Claude when and what to save
- These are instructions, not storage

**Tier 2: Vector Database (where to store)**
- `mcp-memory-service` with SQLite-vec for actual storage
- Queries are semantic, not keyword-exact
- `PostToolUse` hooks for incremental capture (survives Ctrl+C)

Neither tier alone is sufficient. Tier 1 without storage has nowhere to put context. Storage without rules relies on manual discipline.

### 2. Hybrid Search Configuration

For the vector memory MCP server, configure hybrid search weights:

```json
{
  "search": {
    "vectorWeight": 0.7,
    "textWeight": 0.3,
    "mmrLambda": 0.7,
    "temporalDecay": { "halfLifeDays": 30 }
  }
}
```

- `vectorWeight: 0.7`: semantic search dominates for conceptual matching
- `textWeight: 0.3`: keyword fallback catches exact terms semantic misses
- `mmrLambda: 0.7`: MMR diversity prevents near-duplicate results
- `halfLifeDays: 30`: recent memories score higher than old ones

### 3. Session Restart Pattern for Stalled Debugging

When a debugging session is going in circles (3+ failed hypotheses, no clear progress), stop and:

1. Write all findings, hypotheses tested, and current state to a debug doc on disk (`/tmp/debug-context.md` or `docs/debug/`)
2. Include: what you know for certain, what you have tried, what was ruled out, current best hypothesis
3. Start a fresh session that reads the debug doc
4. New session has clean context but full prior knowledge

This avoids accumulated wrong assumptions corrupting reasoning. The fresh session often finds the answer in minutes.

### 4. Save Cadence: Continuous, Not End-of-Session

Do not accumulate saves for session end. Hard kills skip exit hooks, losing all unsaved context. Monolithic end-of-session saves are also harder to search and more error-prone.

Save to vector memory every 20-30 units of significant work, where one unit is a feature completed, architectural decision made, gotcha discovered, bug resolved, or error fixed. This is not every file edit.

When the memory nudge fires, treat it as a mandatory checkpoint trigger, not an optional reminder.

Anti-pattern to avoid: accumulating 100+ work units and then trying to save everything at once. Results in oversized memory entries, risk of total context loss on unexpected termination, and memory fatigue where the backlog feels too large to tackle.

### 5. Enforce via PostToolUse Hooks (Not Stop/SessionEnd)

Use PostToolUse hooks for incremental memory saves. Stop and SessionEnd hooks do not fire on hard terminal kills (Ctrl+C or process kill). PostToolUse fires after every tool completes, so context is saved incrementally even if the session terminates ungracefully.

Stop and SessionEnd hooks are supplementary checkpoints, not the primary save mechanism.

### 6. Memory Nudge Hook Implementation

Implement a PostToolUse hook that tracks edit count and injects a nudge at thresholds:

1. Hook fires on Edit/Write to `src/` files only (skip config/docs to reduce noise)
2. Increment a counter stored in a temp file (e.g., `/tmp/.claude-edit-count`)
3. At threshold (default: 5 edits), inject a reminder to save context to vector memory
4. Use escalating message urgency at higher thresholds (15, 25, 35)
5. On `memory_store` tool call, reset counter to 0

This enforces memory persistence without requiring manual discipline.

### 7. Data Integrity for Mutating Scripts

Any script that rewrites or archives a memory/observation data file must:

1. **Back up before rewrite**: save a copy of the file before modifying it, so a bad rewrite can be rolled back
2. **Refuse on parse failure**: if the existing data fails to parse (corrupted JSON, truncated file, schema mismatch), stop and report the error rather than silently continuing with a best-effort rewrite

Two incidents made this mandatory: an observation-archival script silently lost roughly 47,000 raw records during a rewrite with no detection mechanism, and the (now-retired) knowledge-graph layer silently lost 80 of 84 entities down to 4, also undetected.

### 8. Retention: Old Memories Fall Off via a Monthly Sweep

The server's built-in forgetting stays off (`MCP_FORGETTING_ENABLED=false`): its quality scores are flat, so it would archive most of the DB. Decay is handled by `~/.claude/scripts/memory-stale-sweep.py` (launchd `com.chris2ao.memory-stale-sweep`, 1st of the month), which soft-deletes decommissioned-topic, superseded, and never-accessed memories after a verified backup, and writes a restore manifest to `~/.claude/logs/memory-sweep/`. To keep a memory permanently, tag it `important`, `reference`, or `keep`.

## Source Instincts

- `two-tier-memory`: "when setting up persistent memory for Claude sessions"
- `vector-memory-config`: "when configuring vector memory systems"
- `session-restart-pattern`: "when debugging session stalls with no progress after multiple hypotheses"
- `memory-save-cadence`: "when work accumulates past 50 units without explicit vector memory save"
- `memory-nudge-hook`: "when implementing context persistence rules"
- `postToolUse-resilience`: "when designing session-end memory capture that must survive Ctrl+C"
