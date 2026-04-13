---
platform: portable
description: "Debugging patterns for Next.js MDX content and Vercel deployment failures"
---

# /vercel-nextjs-debugging - Vercel and Next.js MDX Debugging

Activate when a Next.js site deployed on Vercel fails to compile, crashes at runtime, shows truncated error messages, or deploys stale code despite new commits being pushed.

## Steps

### 1. Get the Full Error First

Vercel dashboard UI has character limits for error display. Never debug from a truncated error message. Get the full output via one of these methods, in priority order:

1. Use the `get_deployment_build_logs` MCP tool for complete output
2. Run `vercel logs <deployment-url>` via CLI
3. Reproduce the error locally with the same Next.js config

Local reproduction is the most reliable for MDX and build errors because the full stack trace is visible without truncation.

### 2. MDX Content: Forbidden Syntax

MDX files compiled via `next-mdx-remote` have two common authoring errors that do not fail at build time but crash at runtime:

**HTML Comments (invalid in MDX)**
- MDX compiles to JSX; `<!--` is treated as an invalid character sequence
- Find: `<!-- any text -->` Replace with: `{/* any text */}`
- MDX linters may not catch this until server-side runtime

**Import Statements (invalid in next-mdx-remote)**
- `next-mdx-remote` compiles MDX on the server at runtime with no module resolution context
- `import` statements cause runtime crashes with "Unexpected token" or `___m` variable errors
- Fix: remove all `import` statements from MDX content
- Register components via the `components` prop on `<MDXRemote>` in page.tsx instead
- Must register in BOTH `blog/[slug]/page.tsx` AND `backlog/[slug]/page.tsx` (separate MDX component registries)

### 3. Stale Deploy: Code Not Updating

When a Vercel deploy shows old code despite new commits being pushed:
- The build cache is the likely culprit (Vercel aggressively caches build artifacts)
- Fix: uncheck "Build Cache" in project Settings > General, or trigger a clean deploy from the dashboard
- Re-enable the cache after the clean deploy succeeds

## Source Instincts

- `mdx-jsx-comments`: "when MDX fails to compile with syntax errors near comment-like patterns"
- `mdx-no-imports`: "when MDX file fails with 'Unexpected token' or '___m' errors at runtime"
- `vercel-error-truncation`: "when Vercel error message looks incomplete or cuts off mid-sentence"
- `vercel-build-cache-stale`: "when a Vercel deployment does not reflect recently pushed commits"
