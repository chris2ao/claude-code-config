---
platform: portable
---

# KB Article Authoring

Write a Knowledge Base article to `~/.openclaw/Knowledge_Base/`.

## Required Structure

1. YAML frontmatter:
   - `title`
   - `created` (YYYY-MM-DD)
   - `updated` (YYYY-MM-DD)
   - `author`: Claude Code
   - `tags`: use canonical taxonomy below

2. Heading sections (include all that apply):
   - **Context / Why**: what problem this solves, why the reader should care
   - **What changed**: what was implemented, configured, or decided
   - **Architecture / Process**: how the system works, data flow, component interaction
   - **Dependencies**: required software, services, configuration
   - **Commands / Queries**: absolute command examples for operational tasks
   - **Risks / Limitations**: known failure modes, edge cases, caveats
   - **Validation**: at least one concrete validation artifact (command output, pass/fail summary, or run ID)
   - **Sources**: links to repos, docs, or related KB articles

## Canonical Tags

Select only relevant tags from this taxonomy:

### topic
- `topic/automation`
- `topic/knowledge-management`
- `topic/software-engineering`
- `topic/decision-making`

### concept
- `concept/workflow`
- `concept/reliability`
- `concept/observability`
- `concept/constraints`

### domain
- `domain/operations`
- `domain/software-engineering`
- `domain/knowledge-management`

### entity
- `entity/openclaw`
- `entity/codex`
- `entity/claude`
- `entity/chris-johnson`

## File Naming

Use: `YYYY-MM-DD-<topic>.md`

## Living Documents

Some KB articles are living documents with a defined entry format. When asked to add an entry to one of these, read the existing article first and follow its established format exactly.

| Keyword | Article | Action |
|---------|---------|--------|
| "scheduled task" | `~/.openclaw/Knowledge_Base/2026-03-25-scheduled-tasks.md` | Read the article, copy the entry template in the HTML comment, fill in values for the new task, append below existing entries |

When the user says "create new KB for scheduled task" or "add a scheduled task to KB", do NOT create a new article. Instead, read the existing scheduled tasks article and append a new entry using the template format defined in that file.

## Quality Bar

- Concise, decision-useful writing
- Record exact paths and command snippets
- Avoid placeholders when concrete values are known
- Include at least one validation artifact with real output

## Input

$ARGUMENTS
