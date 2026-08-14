---
platform: portable
---

# Memory Management

## Four Memory Systems, One Rule

Claude Code has multiple memory systems. Each serves a different purpose. Do not duplicate information across them.

(The knowledge graph MCP layer was retired 2026-07-20 in the P1 simplification: two silent data-loss incidents and no multi-hop query workload. Entity-style facts now live in auto-memory topic files, e.g. project-inventory.md. Rationale: docs/research/memory-system-evaluation-2026-07-20.md in CJClaudin_Mac.)

### System Boundaries

**Auto memory** (`MEMORY.md` files, built-in):
- Scope: per-project, loaded automatically (first 200 lines)
- Use for: stable facts that apply every session in this project, including component inventory and relationships that used to go to the knowledge graph
- Examples: build commands, deploy scripts, file structure conventions, tool preferences, project inventory
- Keep it short and factual. If it changes often, it does not belong here.

**Vector memory** (MCP `vector-memory`):
- Scope: global, queried on demand via `memory_store` and `memory_search`
- Use for: detailed context that is relevant when a topic comes up
- Examples: bug resolutions (root cause, fix), architectural decisions (reasoning, tradeoffs), workarounds (what failed, what worked), error patterns (message, cause, solution)
- Always include project name as a tag for filtering.
- Keep each memory under 8000 characters: the Ollama embedding endpoint rejects longer inputs at store time.
- The server deduplicates semantically at storage time (harvest evolution, v10.31+), so near-duplicate saves are handled automatically.

**Homunculus** (`observations.jsonl` + instincts):
- Scope: global, captured automatically by hooks
- Use for: behavioral pattern extraction (handled by observer agent, not by you)
- Do not write to this system directly. Hooks capture it.
- Observations older than 90 days are periodically archived to compressed files alongside the live jsonl.

**Session archive** (`~/.claude/session_archive/`):
- Scope: global (all projects), saved on clean session end
- Use for: full transcript backup for later analysis or re-derivation
- Do not write to this system directly. The SessionEnd hook handles it.

## When to Save to Vector Memory (Triggers)

Save to vector-memory after ANY of these events:

1. Completing a significant task (feature, bug fix, refactor, config change)
2. Making an architectural decision (choosing a library, pattern, or approach)
3. Discovering a gotcha or workaround (something that took effort to figure out)
4. Resolving a bug (root cause, fix, and how it was found)
5. Encountering an error and fixing it (error message, cause, solution)

Do NOT save to vector memory:
- Project conventions that belong in auto memory (MEMORY.md)
- Simple facts like file paths or build commands (auto memory)
- Raw tool usage observations (hooks handle this)

## When to Save to Auto Memory (MEMORY.md)

Update MEMORY.md only for stable, project-specific facts:
- Build and deploy commands
- Key file paths and project structure
- Naming conventions and patterns unique to this project
- Tool and framework versions
- Preferences confirmed across multiple sessions
- Project and component inventory (formerly knowledge-graph territory)

## Fact Versioning Protocol

Before storing a new memory that updates or replaces an existing fact:

1. **Search first**: Run `memory_search` with keywords from the new memory
2. **Check for overlap**: If a result covers the same topic/entity with different information:
   - Update the old memory via `memory_update`: prepend "[SUPERSEDED YYYY-MM-DD]" to its content and add "superseded" to its tags
   - Store the new memory with tag "supersedes:<old-hash>" (hash from search result)
3. **If no overlap**: Store normally

This prevents fact accumulation where outdated information competes with current facts during retrieval.

### When to Version
- Configuration values that changed (port numbers, versions, paths)
- Decisions that were reversed or updated
- Bug fixes that change the understanding of a prior bug report
- Architecture changes that invalidate prior descriptions

### When NOT to Version
- Genuinely distinct memories about the same broad topic
- Memories from different projects that happen to share keywords
- Historical records that are still accurate (they just describe the past)

## Session Start

At the beginning of each session, if the user describes a task related to previous work:
- Query vector-memory with relevant keywords to retrieve prior context
- Use retrieved memories to avoid re-learning or re-investigating
- Check MEMORY.md for project conventions (loaded automatically)

The `session-recall` SessionStart hook emits this as a directive on startup/clear/compact, so it should not depend on remembering.

## Search Parameters (Quality Boost)

Pass `quality_boost: 0.25` on every `memory_search` used for recall (looking up prior context, checking for an existing fact before storing, post-compaction recovery). The server-side `MCP_QUALITY_BOOST_ENABLED` / `MCP_QUALITY_BOOST_WEIGHT` env vars only reach the SSE/web API; the stdio MCP tool hardcodes a `quality_boost` default of 0.0 (`server/handlers/memory.py:1005`), so it has to be passed per call or it does not happen.

Omit it (leave at 0.0, pure semantic) when:
- Doing a fact-versioning duplicate check, where you want the nearest text match regardless of score
- Searching for terse config values or command strings

Caveat: the DeBERTa scorer is prose-biased (confirmed 2026-07-21), so a high weight favors wordy session summaries over short high-value gotchas. 0.25 is deliberately modest; do not raise it above 0.3 without re-checking that gotcha-type memories still rank.

## Save During, Not After

Save memories continuously throughout the session as events occur. Do not wait until session end, as hard kills skip exit hooks and lose unsaved context.

## Session Ingestion Cadence

`/ingest-sessions` is on-demand only, not scheduled. Run it after long stretches of un-wrapped work or before a retrospective. Routine capture is covered by wrap-up saves plus the server's storage-time semantic dedup; historical runs found roughly 85 percent duplicates when run on a cadence.
