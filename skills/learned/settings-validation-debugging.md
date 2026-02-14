# Settings Validation Debugging

**Extracted:** 2026-02-13
**Context:** Feb 8, 2026 crash storm (26 sessions, 21 tiny restarts)

## Problem
Claude Code shows "Found N invalid settings files" at startup but doesn't specify which files are invalid or why. The startup warning is vague, and repeated restarts don't reveal the root cause. This can cause:
- Repeated crashes or freezes during initialization
- Silent failures where features don't load (plugins, MCP servers, hooks)
- User uncertainty about whether the system is working

## Root Cause
Claude Code validates ALL settings files at startup:
- `~/.claude.json` (global user settings)
- `~/.claude/settings.json` (global system settings)
- `<project>/.claude/settings.local.json` (project settings)
- Parent directory settings files (validated even if not used)
- Plugin YAML frontmatter in `SKILL.md` and command files

Common validation failures:
1. **YAML frontmatter** with unquoted colons in description fields (`: `)
2. **Missing expected files** (`.claude/settings.json` at project level)
3. **MCP server config** missing required `type: "stdio"` field
4. **Orphaned settings files** in parent directories from old working contexts
5. **Unrecognized fields** added by third-party tools (SuperClaude)

## Solution
**Step 1: Run debug mode diagnostics**
```bash
claude --debug --debug-file /tmp/claude-debug.log --print "test"
```

**Step 2: Search the debug log for validation errors**
```bash
grep -i "WARN\|YAML\|invalid\|ENOENT\|parse.*error\|settings.*error" /tmp/claude-debug.log
```

**Step 3: Fix each issue systematically**
- YAML errors: Quote description values containing colons
  ```yaml
  ---
  description: "Analyzes code: finds bugs and suggests fixes"
  ---
  ```
- Missing files: Create expected `.claude/settings.json` with `{}`
- MCP servers: Add `"type": "stdio"` to all stdio-based server configs
- Orphaned files: Remove or move settings files from parent directories

**Step 4: Verify fixes**
```bash
claude --print "say OK"
```
Should start without warnings.

## Anti-pattern
```bash
# DON'T: repeatedly restart hoping it fixes itself
claude  # Warning appears
# Exit, restart
claude  # Warning appears again
# Exit, restart... (infinite loop)

# DO: capture diagnostics immediately
claude --debug --debug-file debug.log --print "test"
grep -i error debug.log
```

## When to Use
- "Found N invalid settings files" warning at startup
- Claude Code crashes or freezes during initialization
- Features silently fail to load (plugins, MCP servers, hooks)
- After installing third-party plugins or tools
- After manual edits to `~/.claude.json` or `settings.local.json`
