---
platform: portable
---

# Agent Orchestration

## Immediate Agent Usage

No user prompt needed. Activate these automatically:
1. **Complex feature request** - Use planner agent first, then parallel implementation
2. **Code just written/modified** - Use code-reviewer agent (superpowers:requesting-code-review)
3. **Bug fix or new feature** - Use TDD workflow (superpowers:test-driven-development)
4. **Architectural decision** - Use architect agent (model: opus)
5. **Build failure** - Use build-error-resolver agent
6. **Security-sensitive change** - Use security-reviewer agent before commit

## Agent Discovery

For a complete, up-to-date inventory of all agents, skills, commands, and hooks, run `/skill-catalog`. This dynamically reads from `~/.claude/agents/` and reports the current state.

## Mandatory Parallel Execution

See `rules/core/agentic-workflow.md` for full decomposition rules.
ALWAYS use parallel agent execution for independent operations.
