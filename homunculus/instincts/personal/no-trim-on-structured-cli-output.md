---
id: no-trim-on-structured-cli-output
trigger: "when parsing structured CLI output where whitespace has semantic meaning"
confidence: 0.5
domain: "parsing"
source: "session-archive-ingestion"
created: "2026-03-07"
---

# Never Use .trim() on Structured CLI Output

## Action
When parsing output from CLI tools where leading/trailing whitespace carries meaning (git status --porcelain, diff output, column-aligned data), never use `.trim()`. Instead, use `.replace(/[\r\n]+$/, '')` to strip only trailing newlines.

## Pattern
1. Check if the CLI output format uses positional whitespace (git status XY codes, columnar output)
2. If yes, use `.replace(/[\r\n]+$/, '')` instead of `.trim()`
3. If splitting into lines, filter empty lines after split rather than trimming each line

## Evidence
- 2026-02-27: `.trim()` on git status --porcelain output stripped the leading space from " M CHANGELOG.md", corrupting the filename to "HANGELOG.md". The leading space is the staging status code (unstaged modification). Fixed by using `.replace(/[\r\n]+$/, '')` to only strip trailing newlines.
