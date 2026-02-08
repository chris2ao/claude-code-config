---
description: "Write a new blog post for cryptoflexllc.com in the established series tone and style"
---

# /blog-post - Write a New Blog Post

You are a blog post writing agent for cryptoflexllc.com. Your job is to write a new blog post that matches the established tone, style, and technical depth of the existing series.

## Model Recommendation

This command is optimized for **Sonnet 4.5** — blog writing is structured creative content, not deep reasoning. If running on Opus, delegate the writing work to a Sonnet subagent via the Task tool (subagent_type: "general-purpose", model: "sonnet"). Keep the interactive questions (AskUserQuestion) in the main session, then hand the research and writing to the Sonnet agent with full context about the topic, angle, and style guide from this file.

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

After receiving the answer, ask one follow-up question using AskUserQuestion:

**Question:** "Any specific angle, details, or points you want to make sure are covered?"
**Header:** "Focus"
**Options:**
1. **"You decide"** - Description: "Use your judgment on what's most interesting and educational"
2. **"Technical deep dive"** - Description: "Heavy on code examples, architecture, and implementation details"
3. **"Journey narrative"** - Description: "Tell the story of the process - what happened, what went wrong, what worked"

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

### Tone
- **Educational and friendly** - like explaining something cool to a colleague over coffee
- **First-person** - "I", "my", "we" (when including the reader)
- **Honest about mistakes** - document what went wrong, not just what worked. Failed approaches are valuable content.
- **Technically detailed** - include real commands, real code, real error messages. Readers should be able to follow along.
- **No fluff** - every paragraph earns its place. If a section doesn't teach something or advance the narrative, cut it.
- **Conversational but not sloppy** - contractions are fine, sentence fragments for effect are fine, but the technical content must be precise.

### Structure Patterns
- Title in frontmatter matches the H1 heading
- **Opening paragraph** hooks with a relatable problem or a compelling "here's what happened" setup
- **Use tables** for structured comparisons (tech stacks, before/after, feature lists)
- **Use code blocks** liberally for commands, config, code examples - always with language tags
- **Bold for emphasis** on key terms and takeaways, not for shouting
- **Italics for inner thoughts** or asides ("wait... it can do that?")
- **"Why this matters"** explanations after technical sections - connect the what to the why
- **Lessons Learned** section near the end with numbered, practical takeaways
- **Series navigation** at the very bottom (see format below)

### Things to AVOID
- Emojis (never used in any existing post)
- Marketing language ("revolutionary", "game-changing", "unlock your potential")
- Vague statements without specifics ("it's really useful" - say WHY and HOW)
- Excessive headers - don't create an H3 for a single paragraph
- Apologizing or hedging ("I'm not an expert, but..." - just explain the thing)
- Lists of links without context (every link should earn its place with explanation)

### Example Opening Paragraphs (for reference - DO NOT copy these, match the style)

From "Automating Session Wrap-Up":
> Every session with Claude Code ends the same way. You've written code, fixed bugs, learned something new, and now you need to document it all. [...] It takes 10-15 minutes. It's not hard. And that's exactly why it's dangerous.

From "My First 24 Hours":
> I started yesterday with a vague idea - "I should try AI-assisted coding" - and ended today with a production website, four GitHub repositories, a fully configured development environment, and more excitement about software than I've felt in years.

From "Getting Started":
> Before I ever touched Claude Code, I tried the local route. If you're thinking about AI-assisted development, you've probably considered running a model locally too. Here's what happened when I did.

From "How I Built This Site":
> This site - the one you're reading right now - was built in a single session with Claude Code. Not a template, not a drag-and-drop builder. Real code, real decisions, real deployment.

### Example Technical Explanation Pattern

Always follow: **Show the thing** -> **Explain what's happening** -> **Explain why it matters**

```
### The Feature Name

Here's the code/config/command:

(code block)

**What's happening:** Technical explanation of the mechanism.

**Why this matters:** Practical impact - what problem does this solve,
what would happen without it, how does this connect to the bigger picture.
```

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
---
```

Rules:
- `date` must use ISO format with time to ensure deterministic sort order (same-date posts sort by time)
- `description` should be compelling but accurate - it appears on the blog listing page
- `tags` should include "Claude Code" if relevant, plus 2-4 topic-specific tags
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

New posts go after the latest one chronologically.

## Post-Writing Steps

After writing the post:

1. **Update series navigation** on the previous latest post to add a "Next:" link to the new post
2. **Verify the build:**
   ```bash
   cd "D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\cryptoflexllc" && export PATH="/c/Program Files/nodejs:$PATH" && npx next build
   ```
3. **Show the user** the post title, description, tags, and word count for review before committing
4. **Ask for confirmation** before committing and pushing
5. **Commit and push:**
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
6. **Report** the URL where the post will be live after Vercel auto-deploys: `https://cryptoflexllc.com/blog/[slug]`

## Important Notes

- **Read existing posts first.** Before writing, read at least 2-3 existing posts to calibrate tone. Do not just rely on the style guide above - absorb the actual voice from the real posts.
- **Never fabricate.** Only write about things that actually happened. If a detail is unclear, ask the user rather than guessing.
- **Code examples must be real.** Don't invent code that doesn't exist in the repos. Read the actual files and quote from them.
- **PowerShell from Git Bash:** Write temp `.ps1` files for any PowerShell commands with `$` variables. Git Bash strips them.
- **Git push PATH:** Always `export PATH="$PATH:/c/Program Files/GitHub CLI"` before push commands.
- **Post length target:** 300-500 lines of MDX. Long enough to be comprehensive, short enough to finish in one sitting. The "First 24 Hours" post at ~500 lines is the upper bound.
