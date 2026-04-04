---
platform: portable
description: "Two-tier memory architecture and vector memory configuration for Claude sessions"
---

# /memory-architecture - Claude Memory System Design

Activate when setting up persistent memory for Claude sessions, configuring the vector memory MCP server, or when a debugging session is going in circles and context is needed across session boundaries.

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

## Source Instincts

- `two-tier-memory`: "when setting up persistent memory for Claude sessions"
- `vector-memory-config`: "when configuring vector memory systems"
- `session-restart-pattern`: "when debugging session stalls with no progress after multiple hypotheses"
