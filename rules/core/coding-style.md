# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones.

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Functions under 50 lines, nesting under 4 levels
- Organize by feature/domain, not by type

## Error Handling

- Handle errors explicitly at every level
- Provide user-friendly error messages in UI-facing code
- Log detailed error context on the server side
- Never silently swallow errors

## Writing Style

- NEVER use em dashes (—) in any written content: blog posts, documentation, READMEs, changelogs, comments, or commit messages
- Rewrite sentences to flow naturally without them — use commas, periods, colons, or parentheses instead
- This applies to all prose output, not just code

## Input Validation

- Validate all user input at system boundaries
- Use schema-based validation where available
- Fail fast with clear error messages
- Never trust external data (API responses, user input, file content)
