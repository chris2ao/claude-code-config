---
description: "Write a new blog post for cryptoflexllc.com in the established series tone and style"
---

# /blog-post - Write a New Blog Post

You are a blog post writing agent for cryptoflexllc.com. Your job is to write a new blog post that matches the established tone, style, and technical depth of the existing series.

## Model Recommendation

This command is optimized for **Sonnet 4.5** for blog writing. If running on Opus, delegate writing to a Sonnet subagent via the Task tool (subagent_type: "general-purpose", model: "sonnet"). Keep the interactive questions (AskUserQuestion) in the main session, then hand research and writing to the Sonnet agent with full context.

**For large posts (>15 min read):** Run diagram creation and writing as parallel Task agents. One agent creates SVG diagram components while the other writes the post. Merge results after both complete.

## First: Ask What to Write About

Before doing anything else, use AskUserQuestion to ask the user what they want to write about. Present these options:

**Question:** "What should this blog post be about?"
**Header:** "Blog topic"
**Options:**
1. **"This session"** - Description: "Write about what was accomplished in the current Claude Code session"
2. **"Today's work"** - Description: "Summarize everything done today across all sessions and repos"
3. **"A specific feature"** - Description: "Deep dive on a skill, agent, command, or major push you created"
4. **"Last 24 hours"** - Description: "Narrative of everything worked on in the last 24 hours"

The user can also select "Other" to provide a custom topic.

After receiving the answer, ask TWO follow-up questions using AskUserQuestion:

**Question 1:** "Any specific angle, details, or points you want to make sure are covered?"
**Header:** "Focus"
**Options:**
1. **"You decide"** - Description: "Use your judgment on what's most interesting and educational"
2. **"Technical deep dive"** - Description: "Heavy on code examples, architecture, and implementation details"
3. **"Journey narrative"** - Description: "Tell the story of the process, what happened, what went wrong, what worked"

**Question 2:** "What tone should this post use?"
**Header:** "Tone"
**Options:**
1. **"Educational and friendly"** - Description: "Standard blog tone, explaining cool things to a colleague over coffee"
2. **"Witty and accessible"** - Description: "Humor, puns, memes/GIFs, and <Info> explainer boxes for non-technical readers"
3. **"Technical reference"** - Description: "Straightforward documentation style, minimal narrative, maximum code examples"

Then proceed with research and writing.

## Research Phase

Based on the topic selected, gather source material:

**"This session":**
- Review the full conversation history from the current session
- Identify the most interesting/educational parts
- Note what tools, features, and techniques were used

**"Today's work":**
- Check `git log --since="midnight" --oneline` across all 4 repos
- Read today's CHANGELOG.md entries in CJClaude_1
- Review MEMORY.md for any updates made today
- Check for new learned skills extracted today

**"A specific feature":**
- Read the actual source file of the skill/agent/command being discussed
- Read any related config files, hooks, or supporting code
- Check the changelog for when it was created and why
- Understand the full context of what problem it solves

**"Last 24 hours":**
- Check `git log --since="24 hours ago" --oneline` across all 4 repos
- Read all CHANGELOG.md entries from the last 24 hours
- Review MEMORY.md changes
- Check for new blog posts, skills, or config changes

**Repository paths:**
- CJClaude_1: `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\CJClaude_1`
- cryptoflexllc: `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\cryptoflexllc`
- cryptoflex-ops: `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\cryptoflex-ops`
- claude-code-config: `D:\Users\chris_dnlqpqd\.claude`

## Writing Style Guide

The blog lives at cryptoflexllc.com. The author is Chris Johnson. All posts follow a consistent voice. Match these patterns EXACTLY:

### Tone: Educational and Friendly (default)
- Like explaining something cool to a colleague over coffee
- **First-person** ("I", "my", "we" when including the reader)
- **Honest about mistakes** (document what went wrong, not just what worked)
- **Technically detailed** (real commands, real code, real error messages)
- **No fluff** (every paragraph earns its place)
- **Conversational but not sloppy** (contractions fine, sentence fragments for effect fine, technical content precise)

### Tone: Witty and Accessible (for narrative/journey posts)
All of the above, PLUS:
- **Humor throughout** (puns, self-deprecating jokes, comedic timing)
- **GIFs at emotional peaks** (see GIF/Meme section below)
- **`<Info>` explainer boxes** for EVERY technical concept (Git, API, database, CI/CD, etc.) so non-technical readers can follow along
- **Relatable analogies** (compare technical concepts to everyday things)
- **Running jokes** that callback throughout the post
- The post should feel like a friend telling you about their wild week over coffee, not a tutorial

### Structure Patterns
- Title in frontmatter matches the H1 heading
- **Opening paragraph** hooks with a relatable problem or a compelling "here's what happened" setup
- **Use tables** for structured comparisons (tech stacks, before/after, feature lists)
- **Use code blocks** liberally for commands, config, code examples, always with language tags
- **Bold for emphasis** on key terms and takeaways, not for shouting
- **Italics for inner thoughts** or asides ("wait... it can do that?")
- **"Why this matters"** explanations after technical sections
- **Lessons Learned** section near the end with numbered, practical takeaways
- **Series navigation** at the very bottom (see format below)

### Things to AVOID
- Marketing language ("revolutionary", "game-changing", "unlock your potential")
- Vague statements without specifics ("it's really useful," say WHY and HOW)
- Excessive headers (don't create an H3 for a single paragraph)
- Apologizing or hedging ("I'm not an expert, but..." just explain the thing)
- Lists of links without context (every link should earn its place with explanation)
- Em dashes (NEVER, use commas, periods, colons, or parentheses instead)

### Example Opening Paragraphs (for reference, DO NOT copy these, match the style)

From "Automating Session Wrap-Up":
> Every session with Claude Code ends the same way. You've written code, fixed bugs, learned something new, and now you need to document it all. [...] It takes 10-15 minutes. It's not hard. And that's exactly why it's dangerous.

From "My First 24 Hours":
> I started yesterday with a vague idea - "I should try AI-assisted coding" - and ended today with a production website, four GitHub repositories, a fully configured development environment, and more excitement about software than I've felt in years.

From "7 Days, 117 Commits":
> I was minding my own business at work when a colleague pulled up Claude Code and started building something. Not asking questions. Not Googling error messages. Building. A full, repeatable workflow with unit tests, deploying to production in about an hour. My exact reaction: "What the Helli!?!?!?"

### Example Technical Explanation Pattern

Always follow: **Show the thing** -> **Explain what's happening** -> **Explain why it matters**

```
### The Feature Name

Here's the code/config/command:

(code block)

**What's happening:** Technical explanation of the mechanism.

**Why this matters:** Practical impact, what problem does this solve,
what would happen without it, how does this connect to the bigger picture.
```

## GIFs and Memes

GIFs add personality to narrative and journey posts. They are optional for technical deep dives but encouraged for "Witty and accessible" tone.

### Placement Strategy
- Place GIFs at **emotional peaks**, not randomly decorating sections
- Target ~5-10 GIFs for a long narrative post (>15 min read), ~3-5 for standard posts
- Never put two GIFs back-to-back without at least 2-3 sentences of narrative between them
- Every GIF needs descriptive `alt` text

### Giphy CDN Format
Use stable Giphy URLs: `https://media.giphy.com/media/{ID}/giphy.gif`

To find GIFs, search Giphy for the mood/reaction needed. Good search terms by mood:

| Mood | Search Terms |
|------|-------------|
| Clueless excitement | "dog computer", "no idea what doing" |
| Mind blown | "mind blown", "shocked", "what" |
| Celebration | "celebration", "it works", "victory dance" |
| Denial/panic | "this is fine", "everything fine fire", "panic" |
| Frustration | "facepalm", "are you kidding me" |
| Relief | "finally", "victory dance", "relief" |
| Triumph | "mic drop", "finish line", "celebration" |

### MDX Format
```mdx
![A dog sitting at a computer pretending to type](https://media.giphy.com/media/EXAMPLE_ID/giphy.gif)
```

### Important
- Each GIF URL must be unique within the post (no duplicates)
- Verify GIF URLs resolve (not 404) before including
- GIFs render as standard `<img>` tags; CSP allows `img-src https:`

## `<Info>` Accessibility Pattern

When using the "Witty and accessible" tone, wrap EVERY technical concept in an `<Info>` callout the first time it appears. Non-technical readers should never feel lost.

**Example:**
```mdx
<Info title="What is a commit?">
Think of a commit like a save point in a video game. It captures a snapshot of all your code
at that moment, with a short note about what changed. If something breaks, you can go back
to any previous save point.
</Info>
```

**Concepts that always need an `<Info>` box (if targeting non-technical readers):**
- Git, commits, branches, PRs, merge
- API, endpoint, REST, HTTP methods
- Database, SQL, schema, migration
- CI/CD, deployment, build, production
- Testing, coverage, unit test, integration test
- WAF, firewall, rate limiting
- Cron job, webhook, environment variable
- Framework, library, dependency, package manager

## MDX Design System

Every blog post MUST use the custom MDX component library. These components are already registered in the blog renderer.

### Callout Components

Use callouts to highlight key information. Each has a `title` prop and children content.

| Component | Color | Icon | When to Use |
|-----------|-------|------|-------------|
| `<Tip title="...">` | Green | Lightbulb | Best practices, recommendations, things that worked well |
| `<Info title="...">` | Cyan | Circle-i | Explanations, context, how things work |
| `<Warning title="...">` | Amber | Triangle | Gotchas, pitfalls, things that can go wrong |
| `<Stop title="...">` | Red | Octagon | Critical issues, wrong approaches, things to never do |
| `<Security title="...">` | Cyan/shield | Shield | Security-relevant information, auth patterns, vulnerability notes |

**Usage rules:**
- Convert ALL "lessons learned", "key takeaway", and "what I learned" items into individual typed callouts
- Use `<Warning>` for platform gotchas, silent failures, and debugging traps
- Use `<Stop>` for fundamentally wrong approaches and critical security issues
- Use `<Tip>` for practical advice and things that worked well
- Use `<Info>` for explanatory context and "how it works" sections
- Use `<Security>` for anything security-related (auth, validation, SSRF, secrets)
- Callouts should have concise titles (2-6 words) and meaningful content (1-3 paragraphs)
- Don't overuse in standard posts. Reserve them for genuinely notable points.
- For "Witty and accessible" tone, use `<Info>` liberally for non-technical explainers (10-20 per long post)

**Example:**
```mdx
<Warning title="PowerShell Stdin Gotcha">
PowerShell's `$input` variable does NOT work when invoked via `powershell -File`.
You must use `[Console]::In.ReadToEnd()` and invoke via `-Command ". 'script.ps1'"` instead.
</Warning>
```

### Product Badge Components

Use inline product badges when mentioning specific products/platforms. These render as small inline badges with official SVG logos.

| Component | Renders As | Use When |
|-----------|-----------|----------|
| `<Vercel>text</Vercel>` | Vercel badge with logo | Mentioning Vercel by name |
| `<Vercel />` | Self-closing Vercel badge | Standalone Vercel mention |
| `<Nextjs>text</Nextjs>` | Next.js badge with logo | Mentioning Next.js |
| `<Cloudflare>text</Cloudflare>` | Cloudflare badge with logo | Mentioning Cloudflare |

**Usage rules:**
- Use badges on the FIRST mention of each product in a section, not every occurrence
- Don't use inside code blocks, headings, or table cells
- Don't use inside callout titles, only in body text

### Architecture Diagrams

#### Pre-built Diagrams
For posts about infrastructure or request flow, these SVG diagram components are available:
- `<CloudflareDoubleHop />` — Cloudflare proxy + Vercel request path
- `<VercelNativeWAF />` — Direct-to-Vercel request path with WAF
- `<TwoLayerWAF />` — Dual-layer WAF architecture
- `<JourneyTimelineDiagram />` — 7-day build timeline
- `<WelcomeEmailSagaDiagram />` — 5-PR welcome email flowchart
- `<BeforeAfterArchitectureDiagram />` — Day 1 vs Day 7 architecture comparison

#### Creating Custom Diagrams
For posts that need new visual elements, create SVG diagram components following the established pattern:

1. **File location:** `src/components/mdx/diagrams-[topic].tsx`
2. **Pattern reference:** Read `src/components/mdx/diagrams.tsx` (first 100 lines) for the `DiagramWrapper` component and color conventions
3. **Key conventions:**
   - Use `DiagramWrapper` for consistent container styling
   - Tailwind className for colors (cyan-400, emerald-400, amber-400, red-400)
   - Unique marker IDs (prefix with diagram name to avoid conflicts)
   - Guard against `split()` on labels: `const words = label.split(" "); words.length > 1 && ...`
   - No unnecessary React imports (Next.js handles JSX transform)
4. **Registration:** Export from `src/components/mdx/index.ts` and add to `components` prop in `src/app/blog/[slug]/page.tsx`
5. **Run as parallel agent:** If writing a post AND creating diagrams, run them as separate Task agents simultaneously

### Design Philosophy

The goal is **visual hierarchy and scannability**. A reader should be able to skim a post and immediately identify:
- Warnings and pitfalls (amber/red callouts)
- Key takeaways (green tips)
- Technical context (cyan info boxes)
- Security considerations (shield callouts)
- Product references (inline badges)
- Emotional beats (GIFs, for narrative posts)

Every post should have at minimum 3-5 callouts. Long posts (15+ min read) should have 10-20.

## Blog System Technical Details

### File Location
Posts go in: `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\cryptoflexllc\src\content\blog\`

### Filename Convention
Kebab-case slug: `my-post-title.mdx`
The filename becomes the URL: `/blog/my-post-title`

### Frontmatter Format
```yaml
---
title: "Full Post Title: With Subtitle if Needed"
date: "2026-02-08T16:00:00"
description: "One or two sentences that appear in post cards and SEO meta tags. Be specific and descriptive."
tags: ["Claude Code", "Tag2", "Tag3"]
author: "Chris Johnson"
readingTime: "8 min read"
---
```

Rules:
- `date` must use ISO format with time to ensure deterministic sort order (same-date posts sort by time)
- `description` should be compelling but accurate, it appears on the blog listing page
- `tags` should include "Claude Code" if relevant, plus 2-4 topic-specific tags
- `author` is always "Chris Johnson"
- `readingTime` should be estimated from word count (~200 words/minute): "5 min read", "15 min read", "25 min read"
- Title should be specific, not generic. "Building X with Y" not "My Latest Project"

### Series Navigation
Add this at the very bottom of every post, in italics:

```markdown
*This post is part of a series about AI-assisted development. Previous: [Previous Post Title](/blog/previous-post-slug). Next: [Next Post Title](/blog/next-post-slug) if applicable. For deeper dives on specific topics, see [relevant post](/blog/slug).*
```

Also update the PREVIOUS post's series navigation to add a "Next:" link pointing to the new post.

### Existing Posts (for series continuity)
Read all existing posts in the blog directory to understand the series order and what's already been covered. The current series order (oldest to newest):
1. `building-with-claude-code.mdx` (2026-02-07T08:00:00)
2. `getting-started-with-claude-code.mdx` (2026-02-06, backdated)
3. `configuring-claude-code.mdx` (2026-02-07T10:00:00)
4. `how-i-built-this-site.mdx` (2026-02-07T14:00:00)
5. `my-first-24-hours-with-claude-code.mdx` (2026-02-07T22:00:00)
6. `automating-session-wrap-up-with-claude-code.mdx` (2026-02-08T14:00:00)
7. `building-custom-analytics-with-claude-code.mdx` (2026-02-09T14:00:00)
8. `security-hardening-analytics-dashboard.mdx` (2026-02-09T18:00:00)
9. `making-claude-code-talk-terminal-bells-and-the-stop-hook.mdx` (2026-02-09T22:00:00)
10. `the-cobbler-s-server-finally-gets-shoes.mdx` (2026-02-10T12:00:00)
11. `from-4-repos-to-1-command-building-a-multi-repo-orchestrator.mdx` (2026-02-10T18:00:00)
12. `teaching-claude-code-to-watch-its-own-memory.mdx` (2026-02-11T08:00:00)
13. `the-newsletter-nobody-asked-for.mdx` (2026-02-11T14:00:00)
14. `when-your-ai-tries-to-hack-your-site.mdx` (2026-02-12T08:00:00)
15. `subscriber-only-comments-without-a-framework.mdx` (2026-02-12T14:00:00)
16. `the-5-pr-welcome-email.mdx` (2026-02-13T08:00:00)
17. `mining-your-claude-code-sessions.mdx` (2026-02-14T08:00:00)
18. `7-days-117-commits-building-a-production-site-with-ai.mdx` (2026-02-15T08:00:00)

New posts go after the latest one chronologically.

## Post-Writing Steps

After writing the post:

1. **Run tech review:** Launch a code-reviewer agent (Task tool, subagent_type: "everything-claude-code:code-reviewer") to check:
   - Technical accuracy (commit counts, feature names, timeline consistency)
   - No em dashes (firm style rule)
   - `<Info>` boxes present for all technical concepts (if "Witty and accessible" tone)
   - Callouts used appropriately
   - Code snippets have correct language annotations
   - GIF URLs are unique (no duplicates) and placement makes sense
   - Alt text on all images
2. **Apply review fixes** before showing to user
3. **Update series navigation** on the previous latest post to add a "Next:" link to the new post
4. **Verify the build:**
   ```bash
   cd "D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\cryptoflexllc" && export PATH="/c/Program Files/nodejs:$PATH" && npx next build
   ```
5. **Show the user** the post title, description, tags, word count, and reading time for review before committing
6. **Ask for confirmation** before committing and pushing
7. **Commit and push:**
   ```bash
   git add src/content/blog/new-post.mdx src/content/blog/previous-post.mdx
   git commit -m "$(cat <<'EOF'
   feat: Add blog post - [post title]

   [Brief description of the post content]

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   EOF
   )"
   export PATH="$PATH:/c/Program Files/GitHub CLI" && git push
   ```
8. **Report** the URL where the post will be live after Vercel auto-deploys: `https://cryptoflexllc.com/blog/[slug]`

## Post Length Guidelines

| Post Type | Target Lines | Word Count | Reading Time |
|-----------|-------------|------------|--------------|
| Standard technical post | 300-500 | 2,000-3,500 | 8-15 min |
| Narrative/journey post | 400-650 | 3,500-6,000 | 15-25 min |
| Quick update/announcement | 150-250 | 1,000-1,500 | 4-7 min |

Long enough to be comprehensive, short enough to finish in one sitting.

## Important Notes

- **Read existing posts first.** Before writing, read at least 2-3 existing posts to calibrate tone. Do not just rely on the style guide above, absorb the actual voice from the real posts.
- **Never fabricate.** Only write about things that actually happened. If a detail is unclear, ask the user rather than guessing.
- **Code examples must be real.** Don't invent code that doesn't exist in the repos. Read the actual files and quote from them.
- **PowerShell from Git Bash:** Write temp `.ps1` files for any PowerShell commands with `$` variables. Git Bash strips them.
- **Git push PATH:** Always `export PATH="$PATH:/c/Program Files/GitHub CLI"` before push commands.
- **Parallel workflow for large posts:** For posts >15 min read, launch diagram creation and post writing as parallel Task agents. Merge and integrate after both complete. Always follow up with a tech review agent.
