---
platform: portable
---

# Memory Management

## Five Memory Systems, One Rule

Claude Code has multiple memory systems. Each serves a different purpose. Do not duplicate information across them.

### System Boundaries

**Auto memory** (`MEMORY.md` files, built-in):
- Scope: per-project, loaded automatically (first 200 lines)
- Use for: stable facts that apply every session in this project
- Examples: build commands, deploy scripts, file structure conventions, tool preferences
- Keep it short and factual. If it changes often, it does not belong here.

**Vector memory** (MCP `vector-memory`):
- Scope: global, queried on demand via `memory_store` and `memory_search`
- Use for: detailed context that is relevant when a topic comes up
- Examples: bug resolutions (root cause, fix), architectural decisions (reasoning, tradeoffs), workarounds (what failed, what worked), error patterns (message, cause, solution)
- Always include project name as a tag for filtering.

**Knowledge graph** (MCP `memory`):
- Scope: global, queried on demand via `create_entities`, `search_nodes`
- Use for: explicit relationships between named entities
- Examples: service dependencies, data flow between systems, team/role structures
- Only use when you need to model connections, not for general facts.

**Homunculus** (`observations.jsonl` + instincts):
- Scope: global, captured automatically by hooks
- Use for: behavioral pattern extraction (handled by observer agent, not by you)
- Do not write to this system directly. Hooks capture it.

**Session archive** (`.claude/session_archive/`):
- Scope: per-project, saved on clean exit
- Use for: full transcript backup for later analysis
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

## How to Save to Vector Memory

Include these fields in every memory:

- What: concise description of what happened
- Why: the reasoning or root cause
- Tags: relevant keywords (project name, technology, pattern type)

Use 3-5 tags per memory. Always include the project name as a tag.

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

## Save During, Not After

Save memories continuously throughout the session as events occur. Do not wait until session end, as hard kills skip exit hooks and lose unsaved context.

## Knowledge Graph Maintenance

When you create, modify, or delete any Claude Code component (agent, skill, hook, command, script, or MCP server config), update the knowledge graph:
- New component: create entity with type, file path, and description. Add relations to related entities.
- Modified component: add observations reflecting the change.
- Deleted component: delete the entity (which removes its relations).

Run /Knowledge-Graph-Sync periodically (during wrap-up or config-sync) to catch drift.
