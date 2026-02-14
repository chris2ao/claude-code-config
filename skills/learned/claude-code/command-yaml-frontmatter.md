# Claude Code Command Registration Requires YAML Frontmatter

**Extracted:** 2026-02-07
**Context:** Creating custom slash commands or debugging plugin commands in Claude Code

## Problem
Markdown files in a plugin's `commands/` directory (or custom command directories) are silently ignored by Claude Code if they lack YAML frontmatter. The command doesn't appear in autocomplete, and no error or warning is shown. This makes debugging very difficult — the file exists, has valid content, but Claude Code acts as if it doesn't exist.

## Solution
Every `.md` command file must start with YAML frontmatter containing at least a `description` field:

```markdown
---
description: Brief description of what this command does
---

# Command Title

Your command content here...
```

Only the `description` field is required. Other fields like `agent:` or `subtask:` (used by OpenCode) are ignored by Claude Code and can be omitted.

## Diagnosis Steps
1. Check if the command file has `---` on lines 1 and 3 (or wherever the frontmatter block ends)
2. Check that `description:` is present inside the frontmatter block
3. Verify the file is in the correct `commands/` directory
4. Plugin commands live in `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/commands/`

## When to Use
- Custom slash commands not appearing in Claude Code autocomplete
- Plugin commands partially missing (some work, some don't)
- Writing new custom commands for a plugin or project
- Debugging why a `.md` command file is being ignored
