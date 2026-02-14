# Git Bash Strips PowerShell Variables in Inline Commands

**Extracted:** 2026-02-08
**Context:** Running PowerShell commands with $variables from Git Bash on Windows

## Problem
When executing PowerShell one-liners from Git Bash using `powershell.exe -Command "..."`,
Bash interprets `$` characters first — stripping or expanding PowerShell variables like
`$env:USERPROFILE`, `$t`, `$_.Exception`, etc. before PowerShell sees them.

This causes cryptic parse errors like:
- `You must provide a value expression following the '+' operator`
- `Unexpected token '.login' in expression or statement`
- Variables silently become empty strings

Escaping (`\$`) sometimes works for simple cases but breaks down with nested expressions
like `$($obj.Property)` or `$($t.Substring(0,11))`.

## Solution
**Write a temp .ps1 file and execute it with `-File`:**

1. Write the PowerShell logic to a temp `.ps1` file (using the Write tool)
2. Execute: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "path/to/temp.ps1"`
3. Delete the temp file after

This completely avoids Bash's `$` interpretation since the script content
never passes through the Bash shell.

## Example
```bash
# BAD - Bash eats the $ variables
powershell.exe -Command "$j = Get-Content $env:USERPROFILE\.claude.json | ConvertFrom-Json; Write-Output $j.mcpServers"

# GOOD - Write to file first, then execute
# (write temp.ps1 with Write tool containing the PowerShell code)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "temp.ps1"
rm temp.ps1
```

## When to Use
- Any PowerShell command with `$` variables executed from Git Bash
- PowerShell commands fail with mysterious parse errors about missing values
- Variables appear empty when they shouldn't be
- Complex PowerShell logic (conditionals, try/catch, string interpolation)
