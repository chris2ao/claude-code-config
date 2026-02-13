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
| Code review (after ANY code change) | code-reviewer | inherit |
| Security analysis (before commits) | security-reviewer | inherit |
| Build errors | build-error-resolver | inherit |
| Architecture decisions | architect | opus |
| Documentation updates | doc-updater | haiku |
| Research, web search | general-purpose | haiku |

## Automatic Agent Triggers

No user prompt needed — activate immediately:
1. **2+ independent research queries** → parallel Explore agents
2. **Code just written/modified** → code-reviewer agent
3. **Complex feature request** → planner agent first, then parallel implementation
4. **Bug report** → parallel: Explore (find root cause) + Explore (find test coverage)
5. **Pre-commit** → parallel: security-reviewer + code-reviewer
6. **Multi-repo operation** → parallel agents per repo

## Parallel Patterns

### Research Fan-Out
When exploring unfamiliar code, launch 2-3 Explore agents simultaneously:
- Agent 1: Search for the specific files/classes
- Agent 2: Find related tests and usage patterns
- Agent 3: Check configuration and dependencies

### Write-Then-Review Pipeline
1. Write code (main context or general-purpose agent)
2. Immediately launch in parallel:
   - code-reviewer agent
   - security-reviewer agent (if touches auth, input, or API)
3. Address findings before presenting to user

### Multi-File Changes
When modifying 3+ files:
1. Plan agent designs the approach
2. Parallel agents implement independent file changes
3. code-reviewer validates the combined result

## Cost Optimization
- Use `model: "haiku"` for read-only exploration and search
- Use `model: "sonnet"` for code generation
- Use `model: "opus"` only for architecture and security decisions
- Default to `inherit` when the parent session model is appropriate
