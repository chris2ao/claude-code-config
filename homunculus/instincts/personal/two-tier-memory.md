---
id: two-tier-memory
trigger: "when setting up persistent memory for Claude sessions"
confidence: 0.4
domain: "claude-code"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Two-Tier Memory Architecture

## Action
Implement both Tier 1 (rules/instructions telling what to remember) and Tier 2 (vector database for storage). Single-layer memory fails because it depends on manual discipline. Hooks alone cannot survive hard kills.

## Pattern
1. Tier 1: Rules in CLAUDE.md / rules/ defining what to save and when
2. Tier 2: Vector database (mcp-memory-service with SQLite-vec) for actual storage
3. PostToolUse hooks for incremental capture
4. Both tiers operate independently so failure in one doesn't lose everything

## Evidence
- 2026-03-05: Single-layer auto-memory was unreliable. Adding vector-memory MCP as Tier 2 with rule-based triggers as Tier 1 solved both the "what to remember" and "where to store" problems.
