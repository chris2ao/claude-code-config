---
id: async-first-cache-wrappers
trigger: "when designing cache wrappers that may handle both sync and async functions"
confidence: 0.4
domain: "architecture"
source: "session-archive-ingestion"
created: "2026-03-07"
---

# Make Cache Wrappers Async-First

## Action
When building a generic cache/memoization wrapper that accepts a compute function, always make it async-first. Use `await` on the compute function result so it works transparently with both synchronous return values and Promises.

## Pattern
1. Define the cache wrapper as `async function getCached(key, computeFn, ttl)`
2. Inside, `await computeFn()` so sync values get wrapped in Promise.resolve() automatically
3. Store the resolved value, not the Promise
4. Callers always `await getCached(...)` regardless of whether their compute function is sync or async

## Evidence
- 2026-02-27: MCP project-tools server needed to cache both sync operations (repo_status via execFileSync) and async operations (blog_posts via fs.readFile). Making getCached async-first with `await computeFn()` handled both cases without the caller needing to know.
