---
platform: portable
---

# Performance Optimization

## Model Selection Strategy

**Haiku 4.5** (fastest, cheapest tier):
- Lightweight agents, background tasks, pair programming

**Sonnet 5** (Best coding model):
- Main development work, complex coding tasks

**Opus 5** (Deepest reasoning):
- Architectural decisions, security analysis, research

## Subagent Use and Routing

Default to the main session. When a helper agent is warranted, and which model it gets, is defined once in `rules/core/agentic-workflow.md`.

## Context Window Management

Avoid last 20% of context window for large-scale refactoring, multi-file features, and complex debugging. Single-file edits, utilities, docs, and simple bug fixes are fine at any context level.

## Cost Optimization

- Every subagent re-reads files in a fresh context, so the cheapest agent is the one not spawned
- Use `model: "haiku"` for read-only search agents and `model: "sonnet"` for code-writing and review agents
- Use opus only for security review and owner-requested architecture review
