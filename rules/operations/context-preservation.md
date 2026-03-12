---
platform: portable
---

# Context Preservation

## After Compaction

When context has been compacted (you notice missing details about the current task):

1. Check for a session scratchpad: read the most recent file in `~/.claude/session-state/` that matches the current project name
2. Query vector memory with keywords related to the current task
3. Present the recovered context to the user and confirm before acting on it: "I recovered the following context from your session scratchpad. Does this look right before I continue?" Then list the key items: current task, status, and next steps.
4. Only proceed with the recovered next steps after user confirmation

## When Nudged by Hook

When you see a "SESSION CONTEXT" reminder, write or update `~/.claude/session-state/{project-name}-{timestamp}.md` with:

- Project name and working directory
- Current task description and progress
- Key decisions made so far
- Files being actively worked on
- Next steps remaining
- Any important context that would be lost in compaction

NEVER include secret values (API keys, tokens, passwords, credentials). Reference env var names only, never values.

Keep the scratchpad concise (under 80 lines). It is ephemeral working state.

## Durable Context

For information that should persist beyond this session (completed tasks, bug fixes, architectural decisions), store to vector memory instead. The scratchpad is for in-flight work only.
