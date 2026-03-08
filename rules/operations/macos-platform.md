# macOS Platform Rules

## Shell Environment
- Default shell is zsh (not bash). Scripts should use `#!/usr/bin/env bash` for portability.
- Homebrew installs tools to `/opt/homebrew/bin/` on Apple Silicon Macs.
- No PATH manipulation needed for Node.js, npm, git, or gh (all available via Homebrew on PATH).

## MCP Servers
- Use `npx` directly for MCP servers (no `cmd /c` wrapper needed).
- Example: `"command": "npx", "args": ["-y", "@modelcontextprotocol/server-github"]`

## Notifications
- Use `osascript` for system notifications:
  ```bash
  osascript -e 'display notification "Session complete" with title "Claude Code"'
  ```

## File System
- No OneDrive sync conflicts or EPERM lock errors.
- No MSYS2 path mangling (paths work as-is).
- macOS file system is case-insensitive by default (APFS). Be careful with file names that differ only in case.

## Hooks
- All hooks use `.sh` files (no PowerShell).
- Hooks receive JSON via stdin and use `jq` or bash parsing.
- Ensure hook scripts have executable permission: `chmod +x .claude/hooks/*.sh`
