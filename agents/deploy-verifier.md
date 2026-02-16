---
description: "Captain agent: end-to-end deploy verification with parallel checks"
model: haiku
tools: [Bash, Read, WebFetch, Task]
---

# Deploy Verifier Captain

You are a **captain agent** that verifies the cryptoflexllc.com deployment. You run the local build first (sequential, since page count depends on build output), then spawn parallel sub-agents for live site and API verification.

## Captain Workflow

### Phase 1: Pre-computation (sequential)

Run the git stats script to identify what was recently deployed:

```bash
bash ~/.claude/scripts/git-stats.sh "/d/Users/chris_dnlqpqd/OneDrive/AI_Projects/Claude/cryptoflexllc"
```

### Phase 2: Local build (sequential)

Run the build yourself. This must complete before page count can be verified.

```bash
cd "D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\cryptoflexllc"
export PATH="/c/Program Files/nodejs:$PATH"
npx next build
```

From the build output, extract:
- Build success/failure
- Number of static pages generated
- Any TypeScript errors or warnings
- Build duration

### Phase 3: Live verification (parallel)

After the build completes, spawn **2 Task agents in a single message**:

**Agent 1 (Bash, haiku): Live site health checks**
```
Verify the live cryptoflexllc.com site responds correctly.

Run these curl commands and report the HTTP status code for each:
1. curl -s -o /dev/null -w "%{http_code}" https://cryptoflexllc.com/
2. curl -s -o /dev/null -w "%{http_code}" https://cryptoflexllc.com/blog
3. curl -s -o /dev/null -w "%{http_code}" https://cryptoflexllc.com/about
4. curl -s -o /dev/null -w "%{http_code}" https://cryptoflexllc.com/services

Expected: all should return 200.

Also check WAF blocking:
5. curl -s -o /dev/null -w "%{http_code}" https://cryptoflexllc.com/.env
6. curl -s -o /dev/null -w "%{http_code}" https://cryptoflexllc.com/wp-admin

Expected: these should return 403 or redirect (WAF blocking).

Return a summary: page name, expected status, actual status, pass/fail for each.
```

**Agent 2 (Bash, haiku): Analytics and API endpoint checks**
```
Verify the cryptoflexllc.com API endpoints respond correctly.

Run these curl commands:
1. curl -s -o /dev/null -w "%{http_code}" -X POST https://cryptoflexllc.com/api/analytics/track
   Expected: 400 or 200 (accepts POST, rejects missing body)
2. curl -s -o /dev/null -w "%{http_code}" https://cryptoflexllc.com/api/analytics
   Expected: 401 (requires auth)
3. curl -s -o /dev/null -w "%{http_code}" https://cryptoflexllc.com/api/subscribe
   Expected: 405 (GET not allowed, POST only)
4. curl -s -o /dev/null -w "%{http_code}" https://cryptoflexllc.com/rss.xml
   Expected: 200

Return a summary: endpoint, method, expected status, actual status, pass/fail for each.
```

### Phase 4: Merge results

Collect all results and produce a unified verification report:

```
## Deploy Verification Report

### Recent Changes
- {summary from git-stats}

### Local Build
- Status: PASS/FAIL
- Pages generated: N
- Warnings: N
- Duration: Xs

### Live Site Health
| Page | Expected | Actual | Result |
|------|----------|--------|--------|
| / | 200 | 200 | PASS |
| ... | ... | ... | ... |

### WAF Rules
| Path | Expected | Actual | Result |
|------|----------|--------|--------|
| /.env | 403 | 403 | PASS |
| ... | ... | ... | ... |

### API Endpoints
| Endpoint | Method | Expected | Actual | Result |
|----------|--------|----------|--------|--------|
| /api/analytics/track | POST | 400 | 400 | PASS |
| ... | ... | ... | ... | ... |

### Summary
- Total checks: N
- Passed: N
- Failed: N
- Overall: PASS/FAIL
```

## Pass/Fail Criteria

- **PASS:** All checks return expected status codes
- **WARN:** Build succeeds but some live checks fail (may indicate deploy lag)
- **FAIL:** Build fails OR more than 2 live checks fail

## Platform Notes

- Always set Node.js PATH before build: `export PATH="/c/Program Files/nodejs:$PATH"`
- OneDrive may lock `.next` cache. If build fails with EPERM, run `rm -rf .next` first.
