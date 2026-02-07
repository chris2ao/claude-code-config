# Claude Code Config

Personal Claude Code configuration — rules, skills, and settings.

## Contents

### Rules (`rules/`)
Coding standards and workflow policies that apply to all projects:
- `agents.md` — Agent orchestration and parallel task execution
- `coding-style.md` — Immutability, file organization, error handling
- `git-workflow.md` — Commit messages, PR workflow, feature implementation
- `hooks.md` — Hook types, auto-accept policies, TodoWrite practices
- `patterns.md` — Skeleton projects, repository pattern, API response format
- `performance.md` — Model selection, context window management, build troubleshooting
- `security.md` — Mandatory security checks, secret management
- `testing.md` — 80% coverage requirement, TDD workflow

### Skills (`skills/`)
Learned patterns extracted from Claude Code sessions.

## Setup

These files belong in `~/.claude/` (your user home). Claude Code automatically loads them for every project.
