# Blog MDX Component Reference - cryptoflexllc.com

All components are pre-registered in the blog renderer. Use them directly in MDX.

## Callout Components

Each has a `title` prop and children content.

| Component | Color | Icon | When to Use |
|-----------|-------|------|-------------|
| `<Tip title="...">` | Green | Lightbulb | Best practices, recommendations, things that worked well |
| `<Info title="...">` | Cyan | Circle-i | Explanations, context, how things work |
| `<Warning title="...">` | Amber | Triangle | Gotchas, pitfalls, things that can go wrong |
| `<Stop title="...">` | Red | Octagon | Critical issues, wrong approaches, things to never do |
| `<Security title="...">` | Cyan/shield | Shield | Security-relevant information, auth patterns, vulnerability notes |

**Usage rules:**
- Convert ALL "lessons learned" and "key takeaway" items into individual typed callouts
- `<Warning>` for platform gotchas, silent failures, debugging traps
- `<Stop>` for fundamentally wrong approaches and critical security issues
- `<Tip>` for practical advice and things that worked well
- `<Info>` for explanatory context and "how it works" sections
- `<Security>` for anything security-related (auth, validation, SSRF, secrets)
- Concise titles (2-6 words), meaningful content (1-3 paragraphs)
- Don't overuse in standard posts. Reserve for genuinely notable points
- For "Witty and accessible" tone, use `<Info>` liberally (10-20 per long post)

**Example:**
```mdx
<Warning title="PowerShell Stdin Gotcha">
PowerShell's `$input` variable does NOT work when invoked via `powershell -File`.
You must use `[Console]::In.ReadToEnd()` and invoke via `-Command ". 'script.ps1'"` instead.
</Warning>
```

## Product Badge Components

Inline badges with official SVG logos. Render as small inline elements.

| Component | Use When |
|-----------|----------|
| `<Vercel>text</Vercel>` or `<Vercel />` | Mentioning Vercel |
| `<Nextjs>text</Nextjs>` or `<Nextjs />` | Mentioning Next.js |
| `<Cloudflare>text</Cloudflare>` or `<Cloudflare />` | Mentioning Cloudflare |

**Rules:**
- Use on FIRST mention of each product in a section, not every occurrence
- Don't use inside code blocks, headings, or table cells
- Don't use inside callout titles, only in body text

## Pre-built Architecture Diagrams

Available SVG diagram components (use as self-closing tags):

| Component | Description |
|-----------|------------|
| `<CloudflareDoubleHop />` | Cloudflare proxy + Vercel request path |
| `<VercelNativeWAF />` | Direct-to-Vercel request path with WAF |
| `<TwoLayerWAF />` | Dual-layer WAF architecture |
| `<OldVsNewStack />` | Apache/FTP vs Vercel/Next.js/Git comparison |
| `<SiteArchitectureDiagram />` | Full site architecture |
| `<MDXPipelineDiagram />` | MDX rendering pipeline |
| `<DeploymentFlowDiagram />` | Deployment workflow |
| `<SEOStackDiagram />` | SEO metadata/rendering |
| `<GoogleCrawlFlowDiagram />` | Google crawler request path |
| `<MetadataFlowDiagram />` | Metadata collection/rendering |
| `<SEOBeforeAfterDiagram />` | SEO improvements |
| `<CommentSystemDiagram />` | Comment system architecture |
| `<JourneyTimelineDiagram />` | 7-day build timeline |
| `<WelcomeEmailSagaDiagram />` | 5-PR welcome email flowchart |
| `<BeforeAfterArchitectureDiagram />` | Day 1 vs Day 7 architecture |

## Creating Custom Diagrams

For posts that need new visual elements:

1. **File location:** `src/components/mdx/diagrams-[topic].tsx`
2. **Pattern reference:** Read `src/components/mdx/diagrams.tsx` (first 100 lines) for `DiagramWrapper` and color conventions
3. **Key conventions:**
   - Use `DiagramWrapper` for consistent container styling
   - Tailwind className for colors (cyan-400, emerald-400, amber-400, red-400)
   - Unique marker IDs (prefix with diagram name to avoid conflicts)
   - Guard against `split()` on labels: `const words = label.split(" "); words.length > 1 && ...`
   - No unnecessary React imports (Next.js handles JSX transform)
4. **Registration:** Export from `src/components/mdx/index.ts` and add to `components` prop in `src/app/blog/[slug]/page.tsx`

## Design Philosophy

The goal is **visual hierarchy and scannability**. A reader should be able to skim and immediately identify:
- Warnings and pitfalls (amber/red callouts)
- Key takeaways (green tips)
- Technical context (cyan info boxes)
- Security considerations (shield callouts)
- Product references (inline badges)
- Emotional beats (GIFs, for narrative posts)

Every post should have at minimum 3-5 callouts. Long posts (15+ min read) should have 10-20.
