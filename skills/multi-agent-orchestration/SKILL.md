---
platform: portable
description: "Patterns for structuring multi-agent teams with phase gating, sandbox constraints, and infrastructure choice"
---

# /multi-agent-orchestration - Multi-Agent Team Patterns

Activate when planning a large build (6+ files, 3+ features), designing a multi-agent team structure, or deciding between local and cloud agent infrastructure. These patterns address the failure modes that emerge when agents run in parallel without structure.

## Steps

### 1. Phase Gating for Large Projects

For projects with 6+ files and 3+ distinct features, decompose across specialized agents and gate each phase:

```
Phase 1: Plan    -> captain/architect agent designs approach
Phase 2: Build   -> parallel specialist agents (frontend, backend, shared)
Phase 3: Review  -> QA checkpoint: all blockers resolved before advancing
Phase 4: Polish  -> integration agent validates combined result
```

Phase gating catches critical issues before they cascade. Catch architectural mismatches at Phase 3, not during polish.

Typical agent team composition:
- Captain/Orchestrator (Opus): designs, sequences, synthesizes
- Domain specialists (Sonnet): frontend, backend, database, security
- Reviewer (inherit): validates combined output

### 2. Independent Stream Decomposition

Before launching parallel agents, map dependencies:

1. Identify independent streams (frontend UI, backend API, shared components)
2. Identify stream dependencies (components depend on UI primitives)
3. Launch independent streams as parallel agents in one message
4. Dependent streams wait for prerequisite output before starting
5. Final review agent receives combined output

### 3. Child Agent File Write Constraints

Child agents (spawned via the Task tool) have restricted write access to paths outside the project working directory, including `~/.claude/`. For any file that needs to land in a restricted path:

1. Ask the child agent to "return the file content as structured output" rather than write it
2. Child agent returns: `{ filename, content, metadata }`
3. Parent session receives output and uses the Write tool

This pattern is required for instinct files, config files, and any path under `~/`.

### 4. Channels Over Dispatch for MCP-Heavy Setups

For always-on machines with full MCP infrastructure (vector memory, Obsidian, GitHub, etc.), use Channels (local async) or Remote Control, not Dispatch:

| Mode | MCP access | Use when |
|------|-----------|----------|
| Channels | Full (subprocess of main CC) | Always-on machine, need memory/Obsidian |
| Remote Control | Full (local interactive) | Interactive session from remote device |
| Dispatch | None (isolated VM) | Fire-and-forget, no local tool needs |

### 5. Structural Test Gaps in Dispatch Waves

When dispatch waves include smoke checklists, ensure they exercise the full user-facing surface, not just low-level tests:

**Common omission:** waves include `pytest` and `vitest` but skip `npm run build` / `tsc`. TypeScript type errors, missing component exports, and broken import paths only surface at build time. Including unit tests without a build step is a structural gap that allows soak-blocker bugs to survive wave review.

**Minimum smoke checklist per wave:**
1. `npm run build` (or `tsc --noEmit`) -- catches type errors and missing exports
2. Unit tests (`pytest`, `vitest`, etc.) -- catches logic errors
3. Integration smoke (`curl` to key endpoints) -- catches runtime wiring errors

Silently-failing bugs caught in Phase 2 sleepy-forging-gosling that build coverage would have caught earlier: `ChWriteFailed` not exported, double-hashed payload, silent ClickHouse auth failure returning 200 with empty result, unreachable fallback branch.

### 6. Fail-Loudly Assertions in Observability and Reconciliation Scripts

Reconciliation scripts, parity gates, and observability checks that run in scheduled/cron environments must use `os.environ["KEY"]` (raises `KeyError` on missing) rather than `os.environ.get("KEY", default)`. The silent-default pattern masks misconfigured cron environments: the script runs, emits no findings, and the operator has no idea whether the environment was healthy or simply unconfigured.

**Pattern:**
```python
# Good: fails loudly on misconfiguration
ch_host = os.environ["CLICKHOUSE_HOST"]
ch_user = os.environ["CLICKHOUSE_USER_CLAUDE"]

# Bad: silent auth failure masks misconfig
ch_host = os.environ.get("CLICKHOUSE_HOST", "localhost")
ch_user = os.environ.get("CLICKHOUSE_USER_CLAUDE", "")
```

Apply this to all scripts that gate a soak period, emit drift findings, or serve as health signals. If the environment is wrong, a loud crash + non-zero exit is far more useful than a successful-looking run with no data.

## Source Instincts

- `parallel-scaffolding`: "when scaffolding large monolithic projects (50+ files)"
- `multi-agent-phase-gating`: "when starting a large project with 6 or more files"
- `task-agent-sandbox-writes`: "when spawning Task agents that need to create files in restricted directories"
- `channels-over-dispatch`: "when choosing between Channels, Dispatch, and Remote Control"
