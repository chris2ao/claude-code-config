---
platform: portable
description: "Pre-compact context preservation"
---

# /smart-compact

Preserve session context before running /compact.

## Security: Secret Scrubbing

CRITICAL: NEVER include secret values in vector memory or the scratchpad. This means:
- No API keys, tokens, passwords, or credentials (reference env var NAMES only, never values)
- No connection strings containing embedded passwords
- No private keys, certificates, or auth headers
- If error context involves a credential, describe the error pattern without the credential value

## Steps

1. **Ensure session-state directory exists**: Run `mkdir -p ~/.claude/session-state && chmod 700 ~/.claude/session-state` via Bash to ensure the directory exists with restricted permissions.

2. **Store to vector memory**: Save a comprehensive summary of the current session to vector memory using `mcp__vector-memory__memory_store`. Include:
   - What task(s) you are working on
   - Key decisions made
   - Current progress and what remains
   - Important file paths and patterns
   - Tags: `session-context`, project name, relevant technology keywords

   If vector memory is unavailable (MCP server down, timeout, or error), warn the user explicitly: "Vector memory save failed. Only the scratchpad will be written. Durable context will not be preserved." Do not silently skip.

3. **Write scratchpad**: Write a detailed scratchpad to `~/.claude/session-state/{project-name}-{timestamp}.md` containing:
   - Project name and working directory
   - Task description and current status
   - Files being actively modified
   - Key context that would be lost in compaction
   - Exact next steps to resume
   - `vector_memory_saved: true/false` as a header field

   Use the project/repo directory name and a timestamp (YYYY-MM-DDTHHMM) for the filename. This prevents collisions when running multiple sessions across different projects.

4. **Confirm to user**: Tell the user: "Context preserved to vector memory and scratchpad. Run /compact now."

You cannot trigger /compact directly (it is a built-in CLI command). This skill acts as a pre-compact step that ensures nothing is lost.
