---
platform: portable
---

# Agent Orchestration

Default to the main session. Use a helper agent only when `rules/core/agentic-workflow.md` allows one: the owner asks, a wide search, large truly separate work, a skill that requires it, or the Review Policy.

## Automatic

No user prompt needed:
1. **Idea or complex feature request** - Use the `brainstorming` skill, then the `writing-plans` skill for project-size work
2. **End of a work wave, or a critical change** - Use the code-reviewer agent once on the combined diff (see Review Policy in `rules/core/agentic-workflow.md`); skip small, already-verified edits
3. **Bug fix or new feature** - Test first, per `rules/development/testing.md`
4. **Architectural decision** - Reason it through in the main session; use a `Plan` agent (opus) only if the owner wants a second opinion
5. **Bug, test failure, or build failure** - Use the `systematic-debugging` skill in the main session
6. **Security-sensitive change** - Use the security-reviewer agent once per wave

## Agent Discovery

The live inventory is the agent and skill listing loaded into each session. On disk: `~/.claude/agents/`, `~/.claude/skills/`, `~/.claude/commands/`, `~/.claude/workflows/`, and hooks in `~/.claude/settings.json`. Retired components live in `~/.claude/archive/`.

## Parallel Work

Run independent tool calls in parallel within one message. Parallel agents follow the limits in `rules/core/agentic-workflow.md`.
