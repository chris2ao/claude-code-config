# Agent Orchestration

## Plugin Agents (everything-claude-code)

> **Requires:** [everything-claude-code](https://github.com/affaan-m/everything-claude-code) plugin.

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| planner | Implementation planning | Complex features, refactoring |
| architect | System design | Architectural decisions |
| tdd-guide | Test-driven development | New features, bug fixes |
| code-reviewer | Code review | After writing code |
| security-reviewer | Security analysis | Before commits |
| build-error-resolver | Fix build errors | When build fails |
| e2e-runner | E2E testing | Critical user flows |
| refactor-cleaner | Dead code cleanup | Code maintenance |
| doc-updater | Documentation | Updating docs |

## Custom Agents (~/.claude/agents/)

| Agent | Purpose | Model |
|-------|---------|-------|
| changelog-writer | Auto-generate CHANGELOG entries | haiku |
| multi-repo-orchestrator | Parallel cross-repo operations | haiku |
| session-analyzer | Extract patterns from archives | sonnet |
| deploy-verifier | Post-deploy verification | haiku |
| config-sync | Sync config to git repo | haiku |
| context-health | Monitor context window | haiku |
| skill-extractor | Extract instincts from transcripts (Homunculus v2) | sonnet |

## Immediate Agent Usage

No user prompt needed:
1. Complex feature requests - Use **planner** agent
2. Code just written/modified - Use **code-reviewer** agent
3. Bug fix or new feature - Use **tdd-guide** agent
4. Architectural decision - Use **architect** agent

## Mandatory Parallel Execution

See `rules/core/agentic-workflow.md` for full decomposition rules.
ALWAYS use parallel Task execution for independent operations.
