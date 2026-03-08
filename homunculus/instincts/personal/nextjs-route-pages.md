---
id: nextjs-route-pages
trigger: "when linking to routes in Next.js app router"
confidence: 0.4
domain: "next.js"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Create Page Files for Next.js App Router Routes

## Action
For every sidebar or navigation link, ensure a corresponding `app/[route]/page.tsx` file exists. Missing page files result in 404s. Optionally add `layout.tsx` for route-specific layouts.

## Pattern
1. Add link to sidebar/navigation
2. Create `app/route-name/page.tsx` with at least a basic component
3. Optionally create `app/route-name/layout.tsx` for route-specific wrapping
4. Test navigation to verify no 404

## Evidence
- 2026-03-07: Mission Control sidebar had links to routes without page files, resulting in 404 errors until page.tsx files were created.
