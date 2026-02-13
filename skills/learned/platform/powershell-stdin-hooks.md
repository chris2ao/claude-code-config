# PowerShell Stdin in Claude Code Hooks (Windows)

**Extracted:** 2026-02-07
**Context:** Writing Claude Code hooks in PowerShell on Windows

## Problem
When Claude Code invokes a hook script via `powershell -File script.ps1`, the script receives nothing on stdin. The `$input` automatic variable is empty, so hooks that need to read the JSON event data (session_id, tool_name, etc.) silently fail with no error.

## Solution
Two changes are needed:

1. **Read stdin with `[Console]::In.ReadToEnd()`** instead of `$input`
2. **Invoke via dot-sourcing** instead of `-File`:
   ```
   powershell -Command ". 'C:/path/to/script.ps1'"
   ```
   NOT:
   ```
   powershell -File "C:/path/to/script.ps1"
   ```

The `-File` flag changes how PowerShell handles stdin piping. Dot-sourcing with `-Command` preserves the stdin stream.

## Example
```powershell
# In your hook script (e.g., log-activity.ps1):
$rawInput = [Console]::In.ReadToEnd()
$data = $rawInput | ConvertFrom-Json

# In settings.local.json hook config:
{
  "hooks": {
    "PostToolUse": [{
      "command": "powershell -Command \". 'D:/path/to/.claude/hooks/log-activity.ps1'\"",
      "async": true
    }]
  }
}
```

## When to Use
- Writing any Claude Code hook script in PowerShell on Windows
- Debugging hooks that seem to fire but produce no output
- When `$input` returns empty in a PowerShell hook script
