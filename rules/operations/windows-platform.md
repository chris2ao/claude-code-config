# Windows Platform Rules

## PowerShell from Git Bash
- Write temp .ps1 files for complex PowerShell; Git Bash strips `$` from inline commands
- Use `[Console]::In.ReadToEnd()` for stdin (not `$input`) when invoked via hooks
- Invoke scripts via `-Command ". 'script.ps1'"` not `-File`

## Path Handling
- Git Bash rewrites Windows paths (MSYS2 mangling). Use `npx` or invoke via PowerShell
- Always `export PATH` for GitHub CLI: `export PATH="$PATH:/c/Program Files/GitHub CLI"`
- Always `export PATH` for Node.js: `export PATH="/c/Program Files/nodejs:$PATH"`
- MCP servers MUST use `"command": "cmd", "args": ["/c", "npx", ...]` — bare `npx` fails

## OneDrive
- `.next` cache gets EPERM lock errors. Fix: `rm -rf .next` before rebuilding
- Large directories (node_modules) should be in .gitignore AND OneDrive selective sync exclusion
