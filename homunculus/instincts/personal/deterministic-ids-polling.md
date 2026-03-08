---
id: deterministic-ids-polling
trigger: "when implementing dismissible alerts or log entries in polling dashboards"
confidence: 0.4
domain: "frontend"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Use Deterministic IDs for Polling Data

## Action
Use deterministic hashing (sha256 of content-based key) for IDs instead of randomUUID. This prevents React re-renders on every poll and enables stable ACK/dismiss state.

## Pattern
1. Identify the data fields that uniquely identify an entry (category, title, detail, timestamp)
2. Create ID = sha256(field1:field2:field3)
3. Use this ID for React keys, acknowledgement state, and deduplication

## Evidence
- 2026-03-05: Log parser used randomUUID(), causing React re-renders every poll. Fixed with sha256(source:timestamp:line-hash).
- 2026-03-07: Alert engine used randomUUID(), breaking ACK persistence. Fixed with sha256(category:title:detail).
