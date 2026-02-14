# Blog Post Production Pipeline

**Extracted:** 2026-02-13
**Context:** Feb 9-13 mature workflow, 5 blog posts shipped

## Pattern
By Feb 13, a repeatable blog post production workflow emerged with zero build failures and 100% first-draft acceptance rate:

### Step 1: Topic Selection
**Ask user for:**
- Topic (e.g., "security hardening sprint")
- Angle (e.g., "first-person narrative of findings")
- Target word count (1,500-3,500 typical)

### Step 2: Research Phase
**Gather context from:**
- Existing blog posts (read 2-3 recent posts for tone calibration)
- Source material (session transcripts, code diffs, documentation)
- Related posts in the series (check frontmatter `series` field)

### Step 3: Delegation to Sonnet
**Launch a Sonnet subagent with:**
- Full context (research findings + tone examples)
- Clear deliverable spec (frontmatter format, word count, structure)
- Series navigation context (which post comes before/after)

**Example prompt:**
```
Write a blog post about [topic] following this structure:

Frontmatter:
- title: [engaging, under 70 chars]
- description: [SEO-friendly, 140-160 chars]
- date: 2026-02-[day]
- tags: [3-5 relevant tags]
- series: [series name if applicable]

Body:
- Opening hook (personal, relatable)
- Technical narrative (detailed, with code examples)
- Lessons learned (actionable takeaways)
- Conclusion (forward-looking)

Tone: First-person, conversational, technical depth without jargon.
No em dashes (use commas, colons, periods, parentheses instead).
```

### Step 4: Review & Fix
**Check the draft for:**
- Inaccuracies (verify code snippets, commands, version numbers)
- Tone consistency (compare to recent posts)
- Em dashes (search and replace with natural alternatives)
- Series navigation (update previous post's "Next:" link)

### Step 5: Build Verification
**Always run before commit:**
```bash
export PATH="/c/Program Files/nodejs:$PATH"
npx next build
```

**Verify:**
- Zero build errors
- Zero TypeScript errors
- Zero console.log statements
- All routes generated

### Step 6: Manual Review Handoff
**Present to user:**
- Title (for approval)
- Description (for SEO check)
- Tags (for relevance)
- Word count (meets target?)
- First paragraph (hook quality check)

**Wait for confirmation before committing.**

### Step 7: Commit & Push
**Conventional commit:**
```bash
git add src/content/blog/[slug].mdx
git commit -m "$(cat <<'EOF'
feat: add blog post [number] - [title]

[Hulk Hogan persona body explaining what the post covers]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
git push
```

### Step 8: Deployment
**Vercel auto-deploys from `main` branch (24h turnaround typical).**
- No manual deployment needed
- Monitor Vercel dashboard for build status
- Verify live URL after deployment

## Quality Metrics (Feb 9-13)
- **Build failures:** 0/5 posts
- **First-draft rejection rate:** 0/5 (all accepted with minor edits)
- **Series navigation breaks:** 0/5 (all links maintained correctly)
- **Average time per post:** 1.5-2 hours (research + draft + review)
- **User revisions requested:** 0/5 (Sonnet drafts were publication-ready)

## Anti-pattern
```
# DON'T: Write directly in main session without research
User: "Write a post about X"
Claude: (writes generic post without context)
(Build fails, tone is off, contains inaccuracies)

# DO: Research, delegate to Sonnet, verify build
User: "Write a post about X"
Claude: (reads 3 recent posts for tone)
Claude: (launches Sonnet subagent with full context)
Claude: (reviews draft, fixes 2 inaccuracies, removes em dashes)
Claude: (runs build verification, all pass)
Claude: (presents to user for approval)
```

## When to Use
- Creating any new blog post for the cryptoflexllc site
- After completing a significant feature or learning milestone
- When documenting a debugging journey or technical insight
- Building a blog series (technical deep-dives, tutorials, narratives)
