# MDX Blog Design System for cryptoflexllc.com

**Extracted:** 2026-02-10
**Context:** When writing or editing blog posts (`.mdx` files) in `src/content/blog/` for cryptoflexllc.com

## Problem
Blog posts written as plain markdown lack visual hierarchy. Key warnings, tips, and lessons blend into the surrounding text, making posts harder to scan and reducing the impact of important information.

## Solution
Use the custom MDX component library registered in the blog renderer. Every blog post should include:

**Callout components** — highlight key information with typed, colored boxes:
- `<Tip title="...">content</Tip>` — green, lightbulb icon. Best practices, things that worked.
- `<Info title="...">content</Info>` — cyan, circle-i icon. Explanations, context.
- `<Warning title="...">content</Warning>` — amber, triangle icon. Gotchas, pitfalls.
- `<Stop title="...">content</Stop>` — red, octagon icon. Critical issues, wrong approaches.
- `<Security title="...">content</Security>` — cyan, shield icon. Auth, validation, security notes.

**Product badges** — inline badges with SVG logos for first mention of products:
- `<Vercel>text</Vercel>` or `<Vercel />` — Vercel badge
- `<Nextjs>text</Nextjs>` — Next.js badge
- `<Cloudflare>text</Cloudflare>` — Cloudflare badge

**Rules:**
- Convert "lessons learned" items into individual typed callouts
- Use `<Warning>` for gotchas and silent failures
- Use `<Stop>` for fundamentally wrong approaches
- Use badges on first mention per section, not every occurrence
- Don't use badges in code blocks, headings, or table cells
- Minimum 3-5 callouts per post; 10-20 for long posts (15+ min)

## When to Use
- Writing any new `.mdx` blog post for cryptoflexllc.com
- Editing existing blog posts (add components to sections being modified)
- Any time blog content is being created or substantially revised
