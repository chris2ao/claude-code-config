---
platform: portable
---

# Agentic-First Workflow

CRITICAL: Every non-trivial task MUST be decomposed into parallel agents.

## Mandatory Decomposition

Before starting ANY task with 2+ independent steps:
1. Identify independent subtasks that can run in parallel
2. Launch Task tool calls with appropriate subagent_type in a SINGLE message
3. Never do serial work when parallel is possible
4. Use background agents (`run_in_background: true`) for long-running tasks

## Subagent Routing

| Task Type | Subagent Type | Model |
|-----------|--------------|-------|
| File search, codebase exploration | Explore | haiku |
| Implementation planning | Plan | inherit |
| Code writing, bug fixes | general-purpose | sonnet |
| Code review (end of wave or critical change, see Review Policy) | code-reviewer | sonnet |
| Security analysis (changes touching auth, input, APIs, secrets) | security-reviewer | inherit |
| Bugs, test and build failures | main session (`systematic-debugging` skill) | n/a |
| Architecture decisions | Plan | opus |
| Documentation updates | general-purpose | haiku |
| Research, web search | general-purpose | haiku |

## Automatic Agent Triggers

No user prompt needed — activate immediately:
1. **2+ independent research queries** → parallel Explore agents
2. **End of a work wave, or a critical change** → code-reviewer agent (see Review Policy)
3. **Idea or complex feature request** → `brainstorming` skill, then `writing-plans` for project-size work
4. **Bug report** → `systematic-debugging` skill in the main session; an Explore (haiku) agent only for a wide read-only search
5. **Pre-commit** → security-reviewer only if the change touches auth, input, APIs, or secrets; no second code review of already-reviewed code
6. **Multi-repo operation** → parallel agents per repo

## Parallel Patterns

### Research Fan-Out
When exploring unfamiliar code, launch 2-3 Explore agents simultaneously:
- Agent 1: Search for the specific files/classes
- Agent 2: Find related tests and usage patterns
- Agent 3: Check configuration and dependencies

### Wave-End Review
1. Write and verify code (main context or general-purpose agent)
2. When the wave is done, launch one review of the combined diff:
   - code-reviewer agent
   - security-reviewer agent in parallel (only if it touches auth, input, APIs, or secrets)
3. Address findings before presenting to user

### Multi-File Changes
When modifying 3+ files:
1. Plan agent designs the approach
2. Parallel agents implement independent file changes
3. code-reviewer validates the combined result

## Review Policy (cost control)

Reviewer subagents re-read the changed code, so they are expensive. Run them only:
- **At the end of a work wave**: once per finished feature, phase, or batch of related edits, covering the combined diff. Never per edit, and never a second time at commit for code already reviewed in that wave.
- **For critical changes**: safety, deletion or destructive operations, auth, secrets or credentials, data migrations.

Skip review for small edits already verified by a direct test or run. Per-project review requirements still apply.

## Cost Optimization
- Use `model: "haiku"` for read-only exploration and search
- Use `model: "sonnet"` for code generation
- Use `model: "opus"` only for architecture and security decisions
- Default to `inherit` when the parent session model is appropriate
