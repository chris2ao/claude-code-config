---
platform: portable
description: "Reconcile the knowledge graph (MCP memory server) against actual files on disk"
---

# /Knowledge-Graph-Sync

Reconcile the knowledge graph (MCP `memory` server) against the actual Claude config files on disk. Find missing entities, stale entities, and orphaned relations. Update the graph to match reality.

## Phase 1: Inventory on Disk

Collect all component files from the following locations. For each file, record the name, type, and absolute path.

Run these Bash commands to gather the file lists:

```bash
# Agents
ls ~/.claude/agents/*.md 2>/dev/null

# Skills (SKILL.md files one level deep)
find ~/.claude/skills -maxdepth 2 -name 'SKILL.md' 2>/dev/null

# Hooks (.sh only, exclude any .ps1 duplicates)
ls ~/.claude/hooks/*.sh 2>/dev/null

# Commands
ls ~/.claude/commands/*.md 2>/dev/null

# Scripts
ls ~/.claude/scripts/* 2>/dev/null

# MCP Servers (parse from ~/.claude.json)
cat ~/.claude.json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); [print(k) for k in d.get('mcpServers',{}).keys()]"
```

For each result, assign a type:
- `~/.claude/agents/*.md` → type: `Agent`
- `~/.claude/skills/*/SKILL.md` → type: `Skill` (name = parent directory name, e.g. `gws` from `skills/gws/SKILL.md`)
- `~/.claude/hooks/*.sh` → type: `Hook`
- `~/.claude/commands/*.md` → type: `Command`
- `~/.claude/scripts/*` → type: `Script`
- `mcpServers` keys → type: `MCP Server`

For agents and commands, derive the name from the filename without the `.md` extension. For scripts, use the full filename.

Read the first 5 lines of each agent and skill file to extract a brief description (first non-empty, non-frontmatter line after any `---` block, or the first `#` heading).

Build a disk inventory table: `{ name, type, path, description }`.

## Phase 2: Inventory in Knowledge Graph

Call `mcp__memory__read_graph` to retrieve all current entities and relations.

From the response, extract:
- All entities: `{ name, entityType, observations }`
- All relations: `{ from, to, relationType }`

Build a KG inventory keyed by entity name.

## Phase 3: Reconcile Entities

Compare the disk inventory against the KG entities.

### Missing from KG (on disk but no matching KG entity)

For each disk component with no matching KG entity (match by name, case-insensitive):

Call `mcp__memory__create_entities` to add the entity. Use this shape for each:

```
name: {component name}
entityType: {type from disk inventory}
observations:
  - "file: {absolute path}"
  - "description: {extracted description or 'No description found'}"
  - "added_by_kg_sync: {today's date}"
```

Batch all new entities into a single `create_entities` call.

### In KG but deleted from disk (stale entities)

For each KG entity whose `entityType` is one of `Agent`, `Skill`, `Hook`, `Command`, `Script`, or `MCP Server` and that has NO matching file in the disk inventory:

Collect these into a stale list. Do NOT delete them automatically. Report them to the user (see Phase 5) and ask whether to delete.

If the user confirms deletion, call `mcp__memory__delete_entities` with the confirmed entity names.

### In KG and on disk (potentially outdated)

For each entity present in both KG and disk, check whether the `file:` observation in the KG matches the current path. If it differs, call `mcp__memory__add_observations` to append a correction:

```
"file_updated: {new path} (was {old path}) — updated by kg_sync on {date}"
```

Count how many entities had no changes (accurate), and how many had a path correction.

## Phase 4: Validate Relations

For each relation in the KG, check that both the `from` entity and the `to` entity still exist in the KG (after any additions or deletions from Phase 3).

Collect any relation where either endpoint no longer exists as an entity. These are orphaned relations.

Report the orphaned relations (see Phase 5). Do NOT delete them automatically unless the user explicitly asks.

If the user asks to clean them up, call `mcp__memory__delete_relations` with the orphaned relation objects.

## Phase 5: Report

Output a summary in this format:

```
Knowledge Graph Sync Complete
------------------------------
Components on disk:   N
Components in KG:     N

  Added (new):        N entities
  Stale (no file):    N entities  [list names]
  Path corrected:     N entities
  Already accurate:   N entities

  Orphaned relations: N           [list from->to]
------------------------------
```

For stale entities and orphaned relations, list each one by name so the user can evaluate them. Then ask:

"Would you like me to delete the N stale entities? (yes/no)"

Wait for user confirmation before deleting anything.

## Important Notes

- Only reconcile entities whose `entityType` is `Agent`, `Skill`, `Hook`, `Command`, `Script`, or `MCP Server`. Do not touch other entity types (people, projects, services, etc.).
- Never delete entities or relations without explicit user confirmation.
- If `mcp__memory__read_graph` fails or returns an empty graph, report the error and stop. Do not proceed with writes against a potentially unavailable server.
- If the MCP memory server is unavailable, display: "Knowledge graph is unreachable. Cannot sync. Check that the memory MCP server is running."
- Use today's date in `YYYY-MM-DD` format for all observation timestamps.

