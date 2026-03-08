---
id: openclaw-agents-nesting
trigger: "when parsing openclaw status --json output"
confidence: 0.4
domain: "openclaw"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# OpenClaw Status JSON Agent Nesting

## Action
Access agents at `agents.agents.agents` array, not `agents.agents`. The status output wraps agents in a nested structure: `{ agents: { agents: [...] } }`.

## Pattern
1. Run `openclaw status --json`
2. Parse result
3. Access agent list at: `result.agents.agents` (array)
4. Do NOT assume flat `result.agents` is the array

## Evidence
- 2026-03-07: API route failed because it accessed agents at wrong nesting level. Had to unwrap the nested structure.
