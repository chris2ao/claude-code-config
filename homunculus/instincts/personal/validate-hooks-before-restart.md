---
id: validate-hooks-before-restart
trigger: "when creating or modifying Claude Code hook scripts (.ps1 or .sh files)"
confidence: 0.6
domain: "claude-code"
source: "session-observation"
created: "2026-02-16"
---

# Validate Hook Syntax Before Session End

## Action
After creating or modifying a Claude Code hook script, run syntax validation before exiting the session. For PowerShell hooks, use `powershell -NoProfile -Command "try { Get-Content 'path/to/hook.ps1' | Out-Null; Write-Host 'Valid' } catch { Write-Host 'ERROR: $_' }"`. For JSON config files that reference hooks, use `node -e "JSON.parse(require('fs').readFileSync('path/to/settings.json','utf8')); console.log('Valid JSON')"`.

## Pattern
1. Create or modify hook script (e.g., `.claude/hooks/new-hook.ps1`)
2. Validate PowerShell syntax: `powershell -NoProfile -Command "try { Get-Content '.claude/hooks/new-hook.ps1' | Out-Null; Write-Host 'PowerShell can read the script' } catch { Write-Host 'ERROR: $_' }"`
3. If the hook is registered in `.claude/settings.local.json`, validate JSON syntax: `node -e "JSON.parse(require('fs').readFileSync('.claude/settings.local.json','utf8')); console.log('Valid JSON')"`
4. Only exit the session after all validations pass

## Evidence
- 2026-02-15: After creating `observe-homunculus.ps1` hook, ran both PowerShell syntax check and JSON validation before committing. This prevents the "invalid settings files" crash loop that occurs when Claude Code tries to load a hook with syntax errors at startup.
