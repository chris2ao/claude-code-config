---
id: playwright-screenshots
trigger: "when dashboards need documentation screenshots"
confidence: 0.4
domain: "automation"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Playwright Screenshot Pipeline

## Action
Use Playwright installed in an isolated temp directory (/tmp) to capture screenshots from localhost dev server. Save directly to public/images/blog/ for blog posts.

## Pattern
1. Install Playwright in /tmp: `cd /tmp && npm init -y && npm i playwright`
2. Start dev server on known port (e.g., localhost:3333)
3. Write capture script targeting specific pages/viewports
4. Save screenshots to project's public image directory
5. Clean up /tmp install after capture

## Evidence
- 2026-03-07: Captured 5 Mission Control dashboard screenshots for blog post using Playwright in /tmp. Avoided polluting project dependencies.
