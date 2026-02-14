# Claude Code Startup Diagnostics via Debug Mode

**Extracted:** 2026-02-08
**Context:** Diagnosing "Found N invalid settings files" or other startup errors when `claude doctor` requires an interactive TTY

## Problem
Claude Code shows startup warnings like "Found 5 invalid settings files" but:
- `claude doctor` requires an interactive TTY (uses Ink for rendering) and crashes when piped or run from scripts
- The warning doesn't specify WHICH files are invalid or WHY
- The `/doctor` command in-session may not show details either (known issue: anthropics/claude-code#14798)

## Solution
Use debug mode with `--print` to capture full startup diagnostics to a file:

```bash
claude --debug --debug-file /tmp/claude-debug.log --print "say OK"
```

Then search the log for specific issues:

```bash
# Find YAML parse errors, missing files, validation failures
grep -i "WARN\|YAML\|invalid\|ENOENT\|parse.*error\|settings.*error" /tmp/claude-debug.log

# See which settings files are being watched
grep -i "setting" /tmp/claude-debug.log

# Check plugin loading issues
grep -i "plugin\|skill\|agent.*load" /tmp/claude-debug.log
```

## Common Causes of "Invalid Settings Files"
1. **YAML frontmatter in plugin SKILL.md files** with unquoted colons (`: `) in description values
2. **Missing `.claude/settings.json`** at project level (ENOENT error)
3. **Unrecognized fields** in settings.json added by third-party tools (SuperClaude, etc.)
4. **Orphaned settings files** in parent directories from different working directory contexts

## When to Use
- "Found N invalid settings files" warning at Claude Code startup
- `claude doctor` is unavailable or unhelpful
- Need to trace exactly which config files are loaded and in what order
- Diagnosing plugin, hook, or MCP server loading issues
