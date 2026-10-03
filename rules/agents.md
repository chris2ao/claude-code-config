---
platform: portable
---

# Agent Orchestration

## Immediate Agent Usage

No user prompt needed. Activate these automatically:
1. **Complex feature request** - Use the Plan agent first, then parallel implementation
2. **Code just written/modified** - Use the code-reviewer agent
3. **Bug fix or new feature** - Use TDD workflow (superpowers:test-driven-development)
4. **Architectural decision** - Use the Plan agent with model: opus
5. **Build failure** - Use a general-purpose agent following superpowers:systematic-debugging
6. **Security-sensitive change** - Use the security-reviewer agent before commit

## Agent Discovery

The live inventory is the agent and skill listing loaded into each session. On disk: `~/.claude/agents/`, `~/.claude/skills/`, `~/.claude/commands/`, `~/.claude/workflows/`, and hooks in `~/.claude/settings.json`. Retired components live in `~/.claude/archive/`.

## Mandatory Parallel Execution

See `rules/core/agentic-workflow.md` for full decomposition rules.
ALWAYS use parallel agent execution for independent operations.
