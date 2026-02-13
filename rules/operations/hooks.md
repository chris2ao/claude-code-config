# Hooks System

## Hook Types

- **PreToolUse**: Before tool execution (validation, parameter modification, file protection)
- **PostToolUse**: After tool execution (auto-format, checks, logging)
- **Stop**: When session ends (final verification, notifications)
- **SessionEnd**: When session closes (archiving, cleanup)

## PreToolUse File Protection

Block Edit/Write operations on sensitive files:
- `.env`, `.env.*` — environment secrets
- `*.pem`, `*.key` — certificates
- `credentials.json`, `*.secret` — credential files
- Hook should exit with non-zero code and error message to block the operation

## Auto-Accept Permissions

- Enable for trusted, well-defined plans
- Disable for exploratory work
- Never use dangerously-skip-permissions flag
- Configure `allowedTools` in `~/.claude.json` instead

## Context Preservation Before Compaction

Before compacting, ensure critical context is preserved:
- Active task state and progress
- Key architectural decisions made in session
- File paths and patterns being worked on
- Use MEMORY.md or knowledge graph to persist essential context
