---
id: obsidian-401-http
trigger: "when mcp-tools Obsidian binary returns 401 authentication failures"
confidence: 0.4
domain: "mcp"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Fix Obsidian MCP 401 with HTTP

## Action
Enable "Enable Non-Encrypted (HTTP) Server" in Obsidian Local REST API settings. Set OBSIDIAN_USE_HTTP=true env var in MCP config. Binary defaults to HTTPS (port 27124) with self-signed cert that fails validation. HTTP on port 27123 bypasses this.

## Pattern
1. Check Obsidian Local REST API plugin settings
2. Enable "Enable Non-Encrypted (HTTP) Server"
3. Add `OBSIDIAN_USE_HTTP=true` to MCP server env config
4. Verify connection on port 27123

## Evidence
- 2026-03-07: mcp-tools binary had certificate validation issues with self-signed Obsidian REST API. HTTP connection resolved 401 errors.
