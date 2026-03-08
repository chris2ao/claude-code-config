---
id: verify-data-contracts
trigger: "when consuming structured data from external systems"
confidence: 0.4
domain: "api"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Verify Actual Field Names Against API Contract

## Action
Before wiring up data consumers, inspect the actual data shape returned by the source. Don't assume field names from documentation alone. Log a sample response and match fields.

## Pattern
1. Make a test request and log the raw response
2. Compare actual field names to what the consumer expects
3. Watch for common mismatches: `message` vs `title`/`detail`, flat array vs envelope object
4. Add TypeScript types that match the actual response

## Evidence
- 2026-03-07: Alert API used `message` field but data had `title` and `detail`. Logs API returned `{ entries: [...] }` but component expected flat array.
