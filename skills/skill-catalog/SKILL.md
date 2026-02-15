---
description: "List all available agents, skills, commands, and hooks with descriptions"
---

# /skill-catalog - Full Capability Inventory

List all available agents, skills, commands, and hooks.

## File Listing

!`ls -1 ~/.claude/agents/*.md ~/.claude/skills/*/SKILL.md ~/.claude/skills/learned/*.md ~/.claude/commands/*.md 2>/dev/null`

## Catalog Construction

Read the description from each file's YAML frontmatter and present organized tables:

### 1. Plugin Agents (everything-claude-code)
Known: planner, architect, tdd-guide, code-reviewer, security-reviewer, build-error-resolver, e2e-runner, refactor-cleaner, doc-updater

### 2. Custom Agents (~/.claude/agents/)
List each .md file found above with its frontmatter description.

### 3. Custom Skills (~/.claude/skills/)
List each SKILL.md found above with its frontmatter description.

### 4. Learned Skills (~/.claude/skills/learned/)
List each .md found above, grouped by category.

### 5. Active Hooks
Read `.claude/settings.local.json` in the current project and list configured hooks.

## Output
Present as categorized tables with counts at the top.
