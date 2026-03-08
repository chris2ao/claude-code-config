---
id: runaway-cpu-polling
trigger: "when dashboard shows runaway CPU usage and rapid process cycling"
confidence: 0.4
domain: "performance"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Fix Runaway CPU from Polling

## Action
Implement in-flight deduplication + TTL cache for expensive CLI calls. Increase polling intervals to 60-120s minimum. Never let requests stack faster than they complete.

## Pattern
1. Identify the expensive CLI call being polled (e.g., `openclaw status --json`)
2. Add a cached runner with promise-based in-flight dedup (if call is already running, return its promise)
3. Add TTL caching (30s minimum) so repeated calls return cached results
4. Increase polling interval from 10s to 60-120s

## Evidence
- 2026-03-06: Mission Control polling `openclaw status --json` every 10s spawned 140+ Node.js processes, hitting 580% CPU. Fixed with cached CLI runner + 30s TTL + in-flight dedup.
