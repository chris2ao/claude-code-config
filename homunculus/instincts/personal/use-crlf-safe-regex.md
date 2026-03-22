---
id: use-crlf-safe-regex
trigger: "when writing regex to match line endings in cross-platform code"
confidence: 0.5
domain: "cross-platform"
source: "session-archive-ingestion"
created: "2026-03-07"
---

# Use CRLF-Safe Regex for Line Endings

## Action
When writing any regex that matches newlines (frontmatter delimiters, line splitting, multiline patterns), use `/\r?\n/` instead of `/\n/` to handle both Windows CRLF and Unix LF line endings.

## Pattern
1. Search for `/\n/` or `"\n"` in regex patterns
2. Replace with `/\r?\n/` or `"\r?\n"`
3. For split operations: `text.split(/\r?\n/)` instead of `text.split("\n")`
4. For frontmatter: `/^---\r?\n/` instead of `/^---\n/`

## Evidence
- 2026-02-27: Frontmatter regex `/^---\n/` failed silently on Windows because files had CRLF endings. Changed to `/^---\r?\n/` to fix parsing in the project-tools MCP server blog validator.
