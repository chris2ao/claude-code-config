---
platform: portable
---

# Agent Use (cost-aware)

Helper agents (subagents) start with a fresh context and re-read files on their own, so every one adds rate-limit usage. Default to doing the work in the main session.

## Default: the main session

Do the work directly: reading, searching, editing, testing, debugging, planning, docs and quick research. Independent tool calls (several reads, greps, or commands) go in parallel in one message; that is cheap and still expected.

## When a helper agent is worth it

Use one only when:

1. **The owner asks** for agents, parallel work, or a workflow.
2. **A wide search would flood the context**: sweeping many directories or naming conventions when only the conclusion matters. One `Explore` (haiku) agent, not several.
3. **The work is large and truly separate**: substantial independent work in separate repos, or a plan's `parallel-safe` tasks when the owner chose parallel execution.
4. **A skill or command requires it** (for example deep-research, light-research, blog-post, ui-ux, sync).
5. **The Review Policy below calls for a review.**

Never spawn an agent for something a few direct tool calls can finish, and never spawn several where one would do.

## Routing (when an agent is warranted)

| Task | Where | Model |
|------|-------|-------|
| Wide codebase search | `Explore` agent | haiku |
| Parallel implementation (owner-approved) | `general-purpose` agents | sonnet |
| Code review (see Review Policy) | `code-reviewer` | sonnet |
| Security review (auth, input, APIs, secrets) | `security-reviewer` | inherit |
| Ideas and complex features | main session: `brainstorming`, then `writing-plans` | n/a |
| Bugs, test and build failures | main session: `systematic-debugging` | n/a |
| Architecture decisions | main session; a `Plan` agent only if the owner wants a second opinion | opus |
| Docs, research, web search | main session; `light-research` or `deep-research` for bigger questions | n/a |

## Automatic triggers

No prompt needed:

1. **Idea or complex feature request** → `brainstorming` skill, then `writing-plans` for project-size work
2. **Bug report or failure** → `systematic-debugging` skill in the main session
3. **End of a work wave, or a critical change** → `code-reviewer` agent (see Review Policy)
4. **Change touching auth, input, APIs, or secrets** → `security-reviewer` once per wave; no second code review of already-reviewed code at commit
5. **Multi-repo operation** → work through the repos in the main session; one agent per repo only when each needs substantial independent work

## Review Policy (cost control)

Reviewer subagents re-read the changed code, so they are expensive. Run them only:
- **At the end of a work wave**: once per finished feature, phase, or batch of related edits, covering the combined diff. Never per edit, and never a second time at commit for code already reviewed in that wave.
- **For critical changes**: safety, deletion or destructive operations, auth, secrets or credentials, data migrations.

Skip review for small edits already verified by a direct test or run. Per-project review requirements still apply.

## Model choice for agents

- `haiku` for read-only search agents
- `sonnet` for code-writing and code-review agents
- `opus` (or `inherit` on an Opus session) only for security review and owner-requested architecture review
