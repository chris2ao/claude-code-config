# Git Bash npm Path Mangling on Windows

**Extracted:** 2026-02-07
**Context:** Running `npm` commands in Git Bash (MSYS2) on Windows when Node.js is installed to `C:\Program Files\nodejs\`

## Problem

Running `npm run build` (or any `npm` script) from Git Bash fails with:

```
Error: Cannot find module 'C:\Program Files\Git\Users\chris_dnlqpqd\AppData\Roaming\npm\node_modules\npm\bin\npm-cli.js'
```

Git Bash (MSYS2) rewrites absolute Windows paths. It prepends `C:\Program Files\Git` to paths that start with `/Users/`, mangling the npm module resolution path. The actual file is at `C:\Users\...\npm-cli.js`, not `C:\Program Files\Git\Users\...\npm-cli.js`.

## Solution

**Option 1 (preferred):** Use `npx` with Node.js directly in PATH:

```bash
export PATH="/c/Program Files/nodejs:$PATH"
npx next build
```

**Option 2:** Invoke via PowerShell (if execution policy allows):

```bash
powershell -Command "npm run build"
```

**Option 3:** Use `node` directly to call npm:

```bash
node "C:\Program Files\nodejs\node_modules\npm\bin\npm-cli.js" run build
```

## When to Use

- `npm` commands fail in Git Bash with `MODULE_NOT_FOUND` errors
- The error path contains `C:\Program Files\Git\Users\` (Git Bash path prefix injected)
- Node.js works fine in PowerShell or cmd but breaks in Git Bash
- This does NOT affect `npx` when Node.js is properly in PATH
