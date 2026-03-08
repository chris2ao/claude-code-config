---
id: python-mcp-memory
trigger: "when installing mcp-memory-service"
confidence: 0.4
domain: "environment"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# mcp-memory-service Requires Python 3.10+

## Action
Verify Python 3.10+ is installed before installing mcp-memory-service. macOS default Python is 3.9.6 which is too old. Install via Homebrew if needed.

## Pattern
1. Check: `python3 --version`
2. If < 3.10: `brew install python@3.12`
3. Verify: `python3.12 --version`
4. Use explicit python3.12 path in MCP server config if system python is still old

## Evidence
- 2026-03-05: mcp-memory-service uses Python 3.10+ syntax features. Failed on macOS default 3.9.6.
