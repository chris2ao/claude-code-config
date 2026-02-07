# MCP Server Config: Claude Code vs Claude Desktop

**Extracted:** 2026-02-07
**Context:** Configuring MCP servers for Claude Code (CLI)

## Problem
MCP servers configured in `~/.claude/mcp-servers.json` don't appear in Claude Code. Running `/mcp` shows "No MCP servers configured" despite the file being correctly formatted. No error or warning is given.

## Solution
`~/.claude/mcp-servers.json` is the config file for **Claude Desktop** (the GUI app). **Claude Code** (the CLI) stores MCP servers in a completely different file:

- **User-level:** `~/.claude.json` under `"mcpServers"` key
- **Project-level:** `~/.claude.json` under `"projects"."<absolute-path>"."mcpServers"`

Use the CLI to add servers correctly:
```bash
# User-level (applies to all projects)
claude mcp add <name> --scope user -- npx -y @package/server

# For servers needing env vars (e.g., GitHub token)
claude mcp add-json github --scope user '{"command":"npx","args":["-y","@modelcontextprotocol/server-github"],"env":{"GITHUB_PERSONAL_ACCESS_TOKEN":"ghp_..."}}'

# Verify
claude mcp list
```

## Additional Notes
- On Windows, use **forward slashes** in JSON path arguments (e.g., `D:/Users/...` not `D:\Users\...`)
- The `-e` flag on `claude mcp add` can be finicky with token values; prefer `add-json` for servers with env vars
- Servers load on session start — restart Claude Code after adding

## When to Use
- Setting up MCP servers for Claude Code for the first time
- MCP servers not appearing despite config file existing
- Migrating from Claude Desktop to Claude Code
- Debugging "No MCP servers configured" message
