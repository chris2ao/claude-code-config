# Performance Optimization

## Model Selection Strategy

**Haiku 4.5** (90% of Sonnet capability, 3x cost savings):
- Lightweight agents, background tasks, pair programming

**Sonnet 4.5** (Best coding model):
- Main development work, complex coding tasks

**Opus 4.6** (Deepest reasoning):
- Architectural decisions, security analysis, research

## Subagent Model Routing

| Task Type | Subagent Type | Recommended Model |
|-----------|--------------|-------------------|
| File search, codebase exploration | Explore | haiku |
| Implementation planning | Plan | inherit |
| Code writing, bug fixes | general-purpose | sonnet |
| Code review | code-reviewer | inherit |
| Security analysis | security-reviewer | inherit |
| Build errors | build-error-resolver | inherit |
| Architecture decisions | architect | opus |
| Documentation updates | doc-updater | haiku |
| Research, web search | general-purpose | haiku |

## Context Window Management

Avoid last 20% of context window for large-scale refactoring, multi-file features, and complex debugging. Single-file edits, utilities, docs, and simple bug fixes are fine at any context level.

## Cost Optimization

- Use `model: "haiku"` for read-only exploration and search agents
- Use `model: "sonnet"` for code generation agents
- Use `model: "opus"` only for architecture and security decisions
- Default to `inherit` when the parent session model is appropriate
