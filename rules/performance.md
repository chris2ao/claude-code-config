# Performance Optimization

## Model Selection Strategy

**Haiku 4.5** (90% of Sonnet capability, 3x cost savings):
- Lightweight agents, background tasks, pair programming

**Sonnet 4.5** (Best coding model):
- Main development work, complex coding tasks

**Opus 4.6** (Deepest reasoning):
- Architectural decisions, security analysis, research

## Context Window Management

Avoid last 20% of context window for large-scale refactoring, multi-file features, and complex debugging. Single-file edits, utilities, docs, and simple bug fixes are fine at any context level.
