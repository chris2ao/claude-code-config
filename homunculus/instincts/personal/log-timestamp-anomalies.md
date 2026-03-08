---
id: log-timestamp-anomalies
trigger: "when polling logs from files and seeing timestamp anomalies"
confidence: 0.4
domain: "logging"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Fix Log Polling Timestamp Anomalies

## Action
Implement tail-based reading (track file offset), use deterministic hashing for IDs, and merge multi-line entries before generating identifiers.

## Pattern
1. Track last-read byte offset, only read new content each poll
2. Use sha256(source:timestamp:line-hash) for deterministic IDs
3. Merge continuation lines (no leading timestamp) into preceding entry
4. Never assign new Date().toISOString() to lines without their own timestamps

## Evidence
- 2026-03-05: Log parser read entire 9MB file every poll, assigned randomUUID() and current timestamps to 82K lines including continuation lines. Created massive duplicates.
