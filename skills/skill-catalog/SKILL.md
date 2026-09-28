---
platform: portable
description: "List all available agents, skills, commands, and hooks with descriptions"
---

# /skill-catalog - Full Capability Inventory

List all available agents, skills, commands, and hooks.

## File Listing

!`ls -1 ~/.claude/agents/*.md ~/.claude/skills/*/SKILL.md ~/.claude/skills/*/skill.md ~/.claude/skills/learned/*.md ~/.claude/commands/*.md ~/.claude/workflows/*.js 2>/dev/null`

## Catalog Construction

Read the description from each file's YAML frontmatter and present organized tables:

### 1. Plugin Agents (everything-claude-code)
Known: planner, architect, tdd-guide, code-reviewer, security-reviewer, build-error-resolver, e2e-runner, refactor-cleaner, doc-updater

### 2. Custom Agents (~/.claude/agents/)
List each .md file found above with its frontmatter description. Mark whether it has a `name:` field: only named files are registered subagent types (usable as `subagent_type` or a workflow `agentType`). Unnamed files are instruction documents that a general-purpose agent reads.

### 3. Custom Skills (~/.claude/skills/)
List each SKILL.md (or skill.md) found above with its frontmatter description.

### 3b. Saved Workflows (~/.claude/workflows/)
List each `.js` file with the `description` and `whenToUse` from its `export const meta` block, and the skill that calls it.

### 4. Learned Skills (~/.claude/skills/learned/)
List each .md found above, grouped by category.

### 5. Active Hooks
Read `.claude/settings.local.json` in the current project and list configured hooks.

## Output
Present as categorized tables with counts at the top.
