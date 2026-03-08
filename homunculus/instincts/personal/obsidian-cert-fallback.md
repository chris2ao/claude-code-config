---
id: obsidian-cert-fallback
trigger: "when Obsidian MCP authentication fails with self-signed certificates"
confidence: 0.4
domain: "mcp"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Obsidian MCP Certificate Fallback

## Action
Test HTTP connection on port 27123 first. If successful, enable OBSIDIAN_USE_HTTP env var in MCP config. Self-signed HTTPS on 27124 is unreliable with mcp-tools binary.

## Pattern
1. Try: `curl http://localhost:27123` with API key header
2. If 200, configure MCP for HTTP
3. If fail, check Obsidian REST API plugin is enabled and HTTP server is toggled on
4. Update ~/.claude.json MCP config accordingly

## Evidence
- 2026-03-07: Multiple sessions hit HTTPS cert validation issues. HTTP always worked as fallback.
