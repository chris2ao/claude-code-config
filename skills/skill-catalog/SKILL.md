---
description: "List all available agents, skills, commands, and hooks with descriptions"
---

# /skill-catalog - Full Capability Inventory

List all available agents, skills, commands, and hooks with descriptions.

## Execution

### 1. Plugin Agents (everything-claude-code)

Known plugin agents:
| Agent | Purpose |
|-------|---------|
| planner | Implementation planning |
| architect | System design |
| tdd-guide | Test-driven development |
| code-reviewer | Code review |
| security-reviewer | Security analysis |
| build-error-resolver | Fix build errors |
| e2e-runner | E2E testing |
| refactor-cleaner | Dead code cleanup |
| doc-updater | Documentation |

### 2. Custom Agents (~/.claude/agents/)

List all `.md` files in `D:\Users\chris_dnlqpqd\.claude\agents\` and read their description from frontmatter.

### 3. Custom Skills (~/.claude/skills/)

List all `SKILL.md` files in `D:\Users\chris_dnlqpqd\.claude\skills\` subdirectories and read their descriptions.

### 4. Custom Commands (~/.claude/commands/)

List all `.md` files in `D:\Users\chris_dnlqpqd\.claude\commands\` and read their descriptions.

### 5. Learned Skills (~/.claude/skills/learned/)

List all `.md` files in `D:\Users\chris_dnlqpqd\.claude\skills\learned\` and summarize by category.

### 6. Active Hooks

Read `.claude/settings.local.json` in the current project and list all configured hooks.

## Output Format

Present as categorized tables with descriptions. Include counts at the top:
- X plugin agents
- X custom agents
- X skills (custom + learned)
- X commands
- X active hooks
