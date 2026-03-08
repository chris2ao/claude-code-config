---
id: catch-on-new-sql-queries
trigger: "when adding new SQL queries to a Promise.all block"
confidence: 0.6
domain: "backend"
source: "session-observation"
created: "2026-02-15"
---

# Add .catch() to New SQL Queries in Promise.all

## Action
When adding a new SQL query to an existing `Promise.all()` block in the analytics dashboard (or any similar pattern), always append `.catch(() => [])` (or an appropriate fallback) so that a missing table or query error doesn't crash the entire page.

## Pattern
1. New query goes at the end of the `Promise.all` array
2. Add `.catch(() => [])` for list queries, `.catch(() => [{ ...defaults }])` for summary queries
3. Add the variable name to the destructured result array
4. Add a type cast (`as unknown as TypeName[]`) alongside the existing casts
5. Number the query comment to maintain the index reference

## Evidence
- 2026-02-15: Added `blog_comments` query as index 22 in the analytics page `Promise.all`. Used `.catch(() => [])` to gracefully handle cases where the table might not exist. Matches the pattern of all other optional queries (scroll_events, page_engagement, api_metrics, etc.) in the same block.
