---
platform: portable
---

# Context Preservation

## After Compaction

When context has been compacted (you notice missing details about the current task):

1. Query vector memory with keywords related to the current task
2. Check MEMORY.md and its topic files for project conventions (loaded automatically)
3. Present the recovered context to the user and confirm before acting on it: "I recovered the following context from memory. Does this look right before I continue?" Then list the key items: current task, status, and next steps.
4. Only proceed with the recovered next steps after user confirmation

(The session-state scratchpad machinery was removed 2026-07-20 in the P1 simplification: the directory sat empty for months while the rule text loaded into every session. Claude Code's own compaction handling plus vector memory cover recovery.)

## Durable Context

For information that should persist beyond this session (completed tasks, bug fixes, architectural decisions), store to vector memory as the work happens. Do not wait for session end; hard kills skip exit hooks. NEVER include secret values (API keys, tokens, passwords, credentials) in any stored context. Reference env var names only, never values.
