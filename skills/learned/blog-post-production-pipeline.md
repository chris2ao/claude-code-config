# Blog Post Production Pipeline

**Extracted:** 2026-02-13
**Updated:** 2026-02-14
**Context:** Feb 9-13 mature workflow, 5 blog posts shipped

## Workflow

Use the `/blog-post` command (`~/.claude/commands/blog-post.md`) which orchestrates the full pipeline:
Phase 0 (topic selection) -> Phase 1 (parallel research) -> Phase 2 (Sonnet writing) -> Phase 3 (parallel validation) -> Phase 4 (publish)

Reference docs injected into the writer subagent:
- `~/.claude/skills/blog-style-guide.md` (tone, structure, examples, GIFs)
- `~/.claude/skills/blog-mdx-reference.md` (callouts, badges, diagrams)

## Quality Metrics (Feb 9-13)

- **Build failures:** 0/5 posts
- **First-draft rejection rate:** 0/5 (all accepted with minor edits)
- **Series navigation breaks:** 0/5 (all links maintained correctly)
- **Average time per post:** 1.5-2 hours (research + draft + review)
- **User revisions requested:** 0/5 (Sonnet drafts were publication-ready)

## Key Lessons

1. **Always delegate writing to Sonnet.** Opus orchestrates, Sonnet writes. Sonnet produces better creative/narrative output for blog posts.
2. **Read 2-3 recent posts before writing.** Tone calibration from real posts beats relying on style guide alone.
3. **Dynamic post discovery beats hardcoded lists.** Read the blog directory at runtime to avoid staleness.
4. **Automated validation catches mechanical issues.** Em dashes, duplicate GIFs, missing alt text are deterministic checks, not judgment calls.
5. **Series navigation is error-prone.** Auto-detect the previous post from date-sorted filenames rather than relying on manual tracking.

## Anti-pattern

```
# DON'T: Write directly in main session without research
User: "Write a post about X"
Claude: (writes generic post without context)
(Build fails, tone is off, contains inaccuracies)

# DO: Use /blog-post orchestrator
User: /blog-post
Claude: (asks topic/angle/tone, researches, delegates to Sonnet, validates, publishes)
```

## When to Use

- Creating any new blog post for the cryptoflexllc site
- After completing a significant feature or learning milestone
- When documenting a debugging journey or technical insight
