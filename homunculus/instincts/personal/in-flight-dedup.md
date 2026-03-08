---
id: in-flight-dedup
trigger: "when multiple components poll the same expensive CLI command"
confidence: 0.4
domain: "performance"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Promise-Based In-Flight Deduplication

## Action
Implement runCliJsonCached pattern: if a CLI call is already in-flight, return the existing promise instead of spawning a new process. Add TTL caching on top.

## Pattern
1. Create a Map<string, Promise> for in-flight requests
2. On new request, check if key exists in map
3. If yes, return existing promise
4. If no, spawn process, store promise in map, remove on completion
5. Layer TTL cache (30s) on top for repeated identical queries

## Evidence
- 2026-03-06: Multiple dashboard components independently polling `openclaw status --json` caused process explosion. In-flight dedup reduced spawns to 1 concurrent per command.
