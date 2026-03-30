---
platform: portable
description: "Write a new blog post for cryptoflexllc.com in the established series tone and style"
---

# /blog-post - Blog Post Generator

Multi-agent blog post production pipeline. Coordinates a team of 5 specialists: writer, voice agent, senior editor, UX/UI agent, and captain orchestrator.

## Post Inventory

First, run the blog inventory script to see what posts exist:
```bash
bash ~/.claude/scripts/blog-inventory.sh --minimal
```

## Voice Profile

Read the current voice profile:
```
~/.claude/skills/blog-voice-profile.md
```

Store the full contents of this file in a variable to pass to the captain agent.

## User Discovery

Ask the user (use AskUserQuestion):
1. **Destination:** Publish directly to the live blog, or save as a backlog draft?
   - "Production" - Write to `src/content/blog/` (live on cryptoflexllc.com after deploy)
   - "Backlog" - Write to `src/content/backlog/` (draft, publish later via /backlog admin page)
2. **Topic/Focus:** What is this post about? (be specific)
3. **Series:** Which blog series does this belong to? (or standalone)
   - "Building in Public" - The journey from zero to production site
   - "Site Feature Builds" - Adding specific features (analytics, newsletter, comments, etc.)
   - "Claude Code Workflow" - Automation, hooks, agents, optimization
   - "Security Engineering" - Audits, WAFs, pentesting
   - "Game Development with Claude Code" - Retro game rebuilds (Second Conflict, Third Conflict, Cann Cann)
   - "None (standalone)" - Not part of a series
   NOTE: If "Other" is selected, the user provides a new series name.
   When a series is selected (not "None"), look up the current highest seriesOrder for that series from the inventory and set seriesOrder to the next value.
4. **Target Audience:** Technical developers / Business audience / General readers
5. **Tone:** Educational and friendly / Witty and accessible / Technical reference

## Orchestration

After getting user answers, spawn a Task agent:
- **subagent_type:** general-purpose
- **model:** opus
- **name:** blog-captain

Pass to the agent:
1. The inventory JSON output from above
2. The user's answers (destination, topic, series, audience, tone)
3. The voice profile content (full text of blog-voice-profile.md)
4. Instruction: "You are the Blog Captain. Follow the instructions in ~/.claude/agents/blog-captain.md"
5. If destination is "Backlog", add: "Write the post to src/content/backlog/ instead of src/content/blog/. Skip series navigation updates. The commit message should use 'chore: add backlog draft' prefix instead of 'feat: add blog post'."
6. If a series was selected (not "None"), determine the next seriesOrder by scanning existing posts in that series (grep for `series: '<name>'` in the blog directory), then tell the agent: "Add `series: '<name>'` and `seriesOrder: <next>` to the frontmatter."

## After Agent Returns

The captain returns a JSON report with post details, scores, revision history, and voice profile changes.

1. Display the post details and scores to the user
2. If the captain did not commit (user approval pending), offer to commit and push
3. Update MEMORY.md blog post list with the new entry if appropriate
