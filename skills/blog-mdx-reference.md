---
platform: portable
---

# Blog MDX Component Reference - cryptoflexllc.com

All components are pre-registered in the blog renderer. Use them directly in MDX. Current source of truth: `src/components/mdx/index.ts` (~118 exports); grep it rather than trusting any static list here.

## Callout Components

Each has a `title` prop and children content.

| Component | Color | Icon | When to Use |
|-----------|-------|------|-------------|
| `<Tip title="...">` | Green | Lightbulb | Best practices, things that worked well |
| `<Info title="...">` | Cyan | Circle-i | Explanations, context, how things work |
| `<Warning title="...">` | Amber | Triangle | Gotchas, pitfalls, silent failures |
| `<Stop title="...">` | Red | Octagon | Critical issues, wrong approaches |
| `<Security title="...">` | Cyan/shield | Shield | Auth patterns, vulnerabilities, secrets |

**Usage rules:**
- `<Warning>` for platform gotchas and debugging traps; `<Stop>` for fundamentally wrong approaches; `<Tip>` for practical advice; `<Info>` for context; `<Security>` for anything security-related
- Concise titles (2-6 words), meaningful content (1-3 paragraphs)
- Standard posts: 3-5+ callouts. Long posts (15+ min): 10-20. Witty tone: `<Info>` liberally for every technical concept
- Never nest callouts. Every callout must be closed.
- Do NOT restate the same point in prose, a callout, and a lessons list (see the de-slop check in the voice profile)

## Product Badge Components

`<Vercel>`, `<Nextjs>`, `<Cloudflare>` (with children or self-closing). First mention per section only; never inside code blocks, headings, table cells, or callout titles.

## Embeds

| Component | Notes |
|-----------|-------|
| `<YouTubeEmbed id="..." title="..." caption="..." start={...} />` | Lazy, privacy-friendly. Verify video IDs via oEmbed before use |
| `<CodePlayground ... />` | **Blog pages only**; does not render on backlog pages |
| `<MermaidDiagram>` | Exists but is NOT allowed in published posts; custom SVG diagram components are the rule |

## Images and Zoom

- Markdown images (`![alt](src)`) route through the global `img -> ImageLightbox` mapping (present in BOTH blog and backlog registries) and get click-to-zoom automatically. Raw JSX `<img>` tags BYPASS the components map in next-mdx-remote/rsc and render as plain HTML with no lightbox. ALWAYS use markdown image syntax; never `<img ...>` JSX. Avoid `]` and `<word>` patterns inside alt text (markdown/JSX delimiters).
- Cover images (`coverImage` frontmatter) render through `CoverImageLightbox` as the hero on blog pages (not on backlog pages) and drive OG/Twitter/JSON-LD images.
- Static assets: `public/blog/<slug>/<name>.png`, referenced as `/blog/<slug>/<name>.png`. Every image needs descriptive alt text.
- GIFs: Giphy CDN format `https://media.giphy.com/media/{ID}/giphy.gif`, unique URLs within a post, placed at emotional peaks.

## Diagrams

~56 pre-built SVG diagram components exist (32 `diagrams-*.tsx` files). Before creating one, check `src/components/mdx/index.ts` for a reusable match (e.g. `<CloudflareDoubleHop />`, `<SiteArchitectureDiagram />`, `<DeploymentFlowDiagram />`).

**Creating custom diagrams:**
1. File: `src/components/mdx/diagrams-<post-slug>.tsx`
2. Pattern reference: `src/components/mdx/diagrams.tsx` (first 100 lines) for `DiagramWrapper` and color conventions
3. Conventions: Tailwind className colors (cyan-400, emerald-400, amber-400, red-400) from static class maps only (never `` `bg-${x}-600` `` interpolation, Tailwind v4 purges it silently); unique SVG marker IDs prefixed with the diagram name; no unnecessary React imports
4. Zoom: wrap content with `DiagramLightbox` inside the component (it is internal to diagram components, not used directly in MDX)
5. **Register in THREE places**: `src/components/mdx/index.ts`, the component map in `src/app/blog/[slug]/page.tsx`, AND the component map in `src/app/backlog/[slug]/page.tsx`. Missing the backlog registry is a known production failure.

## Frontmatter Schema (from `src/lib/blog.ts`)

```yaml
---
title: "Full Post Title"                 # required
date: "2026-MM-DDTHH:MM:SS"              # required; ISO with time for sort order
description: "One or two sentences."     # required; cards + SEO meta
tags: ["Claude Code", "Tag2", "Tag3"]    # required
author: "Chris Johnson"                  # required
readingTime: "8 min read"                # required; ~200 words/min
featured: false                          # optional; blog landing shows max 3 featured
series: Claude Code Workflow             # optional; UNQUOTED value, exact existing name
seriesOrder: 7                           # required when series is set; next number, provided by orchestrator
schemaType: TechArticle                  # optional; Article (default) | TechArticle | HowTo
coverImage: /blog/<slug>/infographic.png # optional; added by brand-graphics agent
coverImageAlt: "..."                     # required when coverImage is set
updatedAt: "2026-MM-DDTHH:MM:SS"         # optional; modified date
---
```

Series navigation (`BlogSeriesNav`: progress bar, "Part X of Y", post list) renders automatically from `series` + `seriesOrder`. Never write a manual series navigation footer and never edit previous posts' navigation.

## MDX Runtime Traps (no build error, breaks at render)

- Bare `<` before digits (`<100ms`) parses as a JSX tag start: wrap in backticks
- Nested double quotes inside a JSX attribute value renders an error boundary: rephrase or use single quotes inside
- Markdown (tables, headers, bold) inside code fences renders as literal text: code fences are for actual code only
- Slug/filename: `[a-z0-9-]` only, no dots ("Phase 1.1" becomes `phase-1-1`)

## Backlog Runtime Differences

Backlog pages (`src/app/backlog/[slug]/page.tsx`) do not render: CoverImageLightbox (hero), CodePlayground, heading anchors. The publish API rewrites `date` to publish day, validates the slug charset, and moves the file via 2 remote commits (run `git pull --ff-only` locally afterwards). Write drafts to work in both runtimes.

## Design Philosophy

Visual hierarchy and scannability: a skimming reader should immediately spot warnings (amber/red), takeaways (green), context (cyan), security notes (shield), product references (badges), and emotional beats (GIFs in narrative posts).
