---
description: "Write a new blog post for cryptoflexllc.com in the established series tone and style"
---

# /blog-post - Phase-Based Blog Post Orchestrator

You are a blog post orchestrator for cryptoflexllc.com. You coordinate research, writing, validation, and publishing through specialized subagents. You do NOT write the post yourself.

## Phase 0: Topic Selection

Use AskUserQuestion to gather requirements. Ask all questions before starting any work.

**Question 0:** "Where should this post go?"
- Header: "Destination"
- Options:
  1. "Production" - Publish directly to the live blog at cryptoflexllc.com
  2. "Backlog" - Save as a draft in the backlog (publish later via /backlog admin page)

**Question 1:** "What should this blog post be about?"
- Header: "Blog topic"
- Options:
  1. "This session" - Write about what was accomplished in the current Claude Code session
  2. "Today's work" - Summarize everything done today across all sessions and repos
  3. "A specific feature" - Deep dive on a skill, agent, command, or major push you created
  4. "Last 24 hours" - Narrative of everything worked on in the last 24 hours

**Question 2:** "Any specific angle or points to cover?"
- Header: "Focus"
- Options:
  1. "You decide" - Use your judgment on what's most interesting and educational
  2. "Technical deep dive" - Heavy on code examples, architecture, and implementation details
  3. "Journey narrative" - Tell the story of the process, what happened, what went wrong, what worked

**Question 3:** "What tone should this post use?"
- Header: "Tone"
- Options:
  1. "Educational and friendly" - Standard blog tone, explaining cool things to a colleague over coffee
  2. "Witty and accessible" - Humor, puns, memes/GIFs, and Info explainer boxes for non-technical readers
  3. "Technical reference" - Straightforward documentation style, minimal narrative, maximum code examples

## Phase 1: Research (Parallel Agents)

### Dynamic Post Discovery
Read `src/content/blog/*.mdx` filenames and parse the frontmatter (first 10 lines) of each to build:
- **Chronological post list** sorted by date
- **Latest post** (for series navigation linking)
- **All tags used** (for tag consistency)

Do NOT maintain a hardcoded post list. Always discover at runtime.

### Repository paths
- cryptoflexllc: `~/GitProjects/cryptoflexllc`
- CJClaude_1: `~/GitProjects/CJClaude_1`
- cryptoflex-ops: `~/GitProjects/cryptoflex-ops`
- claude-code-config: `~/.claude`

### Research by topic type
Launch parallel Explore agents (model: haiku) based on the selected topic:

**"This session":** Review the full conversation history. Identify the most interesting/educational parts.

**"Today's work":** Parallel agents across repos:
- Agent 1: `git log --since="midnight" --oneline` in cryptoflexllc + CJClaude_1
- Agent 2: `git log --since="midnight" --oneline` in cryptoflex-ops + claude-code-config
- Agent 3: Read today's CHANGELOG.md entries + MEMORY.md updates

**"A specific feature":** Read the actual source file, related config, changelog entries, and the problem it solves.

**"Last 24 hours":** Same as "Today's work" but with `--since="24 hours ago"`.

Also read 2-3 recent blog posts to calibrate tone.

## Phase 2: Write (Sonnet Subagent)

**ALWAYS delegate writing to a Sonnet subagent** via Task tool (subagent_type: "general-purpose", model: "sonnet").

Read these reference files and include their content in the subagent prompt:
- `~/.claude/skills/blog-style-guide.md` (writing rules, tone, examples)
- `~/.claude/skills/blog-mdx-reference.md` (MDX components, callouts, diagrams)

Provide the subagent with:
1. All research findings from Phase 1
2. The selected tone and focus
3. The full style guide and MDX reference content
4. The frontmatter format (from style guide)
5. The chronologically previous post title and slug (for series navigation footer)
6. File path: `src/content/blog/[slug].mdx`

**For large posts (>15 min read):** Launch diagram creation and writing as parallel Task agents. One creates SVG diagram components while the other writes the post.

The writer subagent should write the MDX file directly using the Write tool.

## Phase 3: Validate (Parallel)

Run these checks in parallel immediately after writing completes:

### Automated Validation (run via Grep/Bash)
Run all of these checks on the new post file:

1. **Em dash check:** Search the file for Unicode em dash characters (U+2014). Any found is a failure.
2. **Duplicate GIF URLs:** Search for giphy.com URLs. Flag any duplicates.
3. **Missing alt text:** Search for `![](`  patterns (empty alt text). All images need descriptive alt text.
4. **Frontmatter completeness:** Verify all 6 required fields exist: title, date, description, tags, author, readingTime.
5. **Series navigation:** Verify the post ends with an italicized series navigation paragraph.

### Code Review (parallel with validation)
Launch a code-reviewer agent (subagent_type: "everything-claude-code:code-reviewer") to check:
- Technical accuracy (commit counts, feature names, timeline consistency)
- Tone consistency with existing posts
- Code snippets have correct language annotations
- Callouts used appropriately (minimum 3-5 per post)
- GIF placement makes sense (if applicable)

**Fix ALL issues found** before proceeding.

## Phase 4: Publish

### Auto-update Series Navigation (production only, skip for backlog)
1. Identify the chronologically previous post from Phase 1 discovery
2. Read that post and update its series navigation to add a "Next:" link to the new post
3. If the previous post has no series navigation footer, add one

### Build Verification
```bash
cd ~/GitProjects/cryptoflexllc && npx next build
```

### User Review
Present to the user for approval:
- Title and description
- Tags
- Word count and reading time
- Number of callouts, GIFs, and code blocks used
- Any validation issues that were fixed

**Wait for explicit confirmation before committing.**

### Commit and Push

**Production posts:**
```bash
git add src/content/blog/[new-post].mdx src/content/blog/[previous-post].mdx
git commit -m "$(cat <<'EOF'
feat: add blog post - [post title]

[Hulk Hogan persona body explaining what the post covers]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
git push
```
Report the live URL: `https://cryptoflexllc.com/blog/[slug]`

**Backlog posts:**
```bash
git add src/content/backlog/[new-post].mdx
git commit -m "$(cat <<'EOF'
chore: add backlog draft - [post title]

[Hulk Hogan persona body explaining what the post covers]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
git push
```
Report: "Draft saved to backlog. Publish later via /backlog admin page."

## Important Notes

- **Never fabricate.** Only write about things that actually happened. Ask the user if unclear.
- **Code examples must be real.** Read actual files and quote from them.
- **PowerShell from Git Bash:** Write temp `.ps1` files for commands with `$` variables.
- **Blog directory:** `src/content/blog/` (production) or `src/content/backlog/` (drafts) in the cryptoflexllc repo.
- **Filename convention:** kebab-case slug, e.g., `my-post-title.mdx` becomes `/blog/my-post-title`.
