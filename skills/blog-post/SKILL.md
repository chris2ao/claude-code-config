---
description: "Write a new blog post for cryptoflexllc.com in the established series tone and style"
---

# /blog-post - Blog Post Generator

Automates blog post creation from research through MDX file generation.

## Post Inventory

!`bash ~/.claude/scripts/blog-inventory.sh --minimal`

## User Discovery

Ask the user (use AskUserQuestion):
1. **Topic/Focus:** What is this post about? (be specific)
2. **Target Audience:** Technical developers / Business audience / General readers
3. **Tone:** Educational and friendly / Witty and accessible / Technical reference
4. **Unique Angle:** What makes this post different or interesting?

## Orchestration

After getting user answers, spawn a Task agent:
- **subagent_type:** general-purpose
- **model:** sonnet
- **name:** blog-post-orchestrator

Pass to the agent:
1. The inventory JSON output from above
2. The user's answers to all 4 questions
3. Instruction: "You are a blog post orchestrator. Follow the instructions in ~/.claude/agents/blog-post-orchestrator.md"

## After Agent Returns

The agent returns JSON with `filename`, `title`, `description`, `word_count`, `tags`, `summary`.

1. Display the post details to the user
2. Update MEMORY.md blog post list with the new entry
3. Offer to verify the build: `export PATH="/c/Program Files/nodejs:$PATH" && cd "D:/Users/chris_dnlqpqd/OneDrive/AI_Projects/Claude/cryptoflexllc" && npx next build`
4. Ask if user wants to commit and push
