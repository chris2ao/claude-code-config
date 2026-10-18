---
platform: portable
---

# Agent Orchestration

## Immediate Agent Usage

No user prompt needed. Activate these automatically:
1. **Idea or complex feature request** - Use the `brainstorming` skill, then the `writing-plans` skill for project-size work
2. **End of a work wave, or a critical change** - Use the code-reviewer agent once on the combined diff (see Review Policy in `rules/core/agentic-workflow.md`); skip small, already-verified edits
3. **Bug fix or new feature** - Test first, per `rules/development/testing.md`
4. **Architectural decision** - Use the Plan agent with model: opus
5. **Bug, test failure, or build failure** - Use the `systematic-debugging` skill in the main session
6. **Security-sensitive change** - Use the security-reviewer agent before commit

## Agent Discovery

The live inventory is the agent and skill listing loaded into each session. On disk: `~/.claude/agents/`, `~/.claude/skills/`, `~/.claude/commands/`, `~/.claude/workflows/`, and hooks in `~/.claude/settings.json`. Retired components live in `~/.claude/archive/`.

## Mandatory Parallel Execution

See `rules/core/agentic-workflow.md` for full decomposition rules.
ALWAYS use parallel agent execution for independent operations.
