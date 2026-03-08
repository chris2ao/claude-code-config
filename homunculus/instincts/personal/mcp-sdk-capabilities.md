---
id: mcp-sdk-capabilities
trigger: "when setting up new MCP servers with SDK v1.x"
confidence: 0.4
domain: "mcp"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# MCP SDK Server Constructor Signature

## Action
Pass capabilities as the second argument to the Server constructor: `Server(serverInfo, { capabilities })`. Do not nest capabilities in the first argument object.

## Pattern
1. Correct: `new Server({ name, version }, { capabilities: { tools: {} } })`
2. Wrong: `new Server({ name, version, capabilities: { tools: {} } })`
3. If tools list returns empty despite definitions, check constructor signature first

## Evidence
- 2026-03-05: project-tools MCP server reported "does not support tools" because capabilities were merged into the first argument. Moving to second argument fixed it.
