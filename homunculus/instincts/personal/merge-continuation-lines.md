---
id: merge-continuation-lines
trigger: "when parsing unstructured logs with continuation lines"
confidence: 0.4
domain: "logging"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Merge Non-Timestamped Log Continuation Lines

## Action
Merge non-timestamped lines into the preceding timestamped entry using a separator (e.g., ` | `). Do not create separate entries for continuation lines.

## Pattern
1. Match lines with leading timestamp pattern (e.g., `YYYY-MM-DD HH:MM:SS`)
2. Lines without a timestamp belong to the preceding timestamped entry
3. Append with separator: `parentLine + ' | ' + continuationLine`
4. Only create new log entries for lines with their own timestamps

## Evidence
- 2026-03-05: Gateway logs had continuation lines like "If the gateway is supervised..." without timestamps. Parser orphaned them as separate entries with current time. Merging fixed duplicate counts.
