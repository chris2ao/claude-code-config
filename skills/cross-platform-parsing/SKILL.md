---
platform: portable
description: "Safe text and CLI output parsing patterns across Windows and Unix"
---

# /cross-platform-parsing - Cross-Platform Text and CLI Parsing

Activate when writing code that parses CLI output, processes text files, or runs shell commands in a cross-platform (Windows + macOS/Linux) context. These patterns prevent silent data corruption from line-ending and shell-interpretation differences.

## Steps

### 1. CRLF-Safe Regex for Line Endings

Never use `/\n/` in regex patterns. Use `/\r?\n/` to handle both Windows CRLF and Unix LF:

```ts
// Wrong: fails silently on Windows files
const parts = text.split('\n')
const hasFrontmatter = /^---\n/.test(content)

// Correct
const parts = text.split(/\r?\n/)
const hasFrontmatter = /^---\r?\n/.test(content)
```

This applies to: frontmatter delimiters, line splitting, multiline regex patterns, and any file read from disk on Windows.

### 2. execFileSync Instead of execSync for Special Characters

On Windows, `execSync` routes through `cmd.exe` which interprets `%`, `^`, `!`, and `&` as shell metacharacters. Git format strings, path patterns, and many CLI flags contain these characters.

Use `execFileSync(command, argsArray)` to bypass shell interpretation entirely:

```ts
import { execFileSync } from 'child_process'

// Wrong: cmd.exe eats the % characters
execSync('git log --format="%H|%s|%an|%ai"')

// Correct: args passed directly without shell
execFileSync('git', ['log', '--format=%H|%s|%an|%ai'])
```

### 3. Never .trim() Positional CLI Output

CLI tools like `git status --porcelain` use leading whitespace as semantic codes. `.trim()` corrupts these:

```ts
// Wrong: strips the staging status code from " M filename.ts"
const line = rawLine.trim()

// Correct: strip only trailing newlines
const line = rawLine.replace(/[\r\n]+$/, '')

// For splitting into lines, filter empty rather than trimming each
const lines = output.replace(/[\r\n]+$/, '').split(/\r?\n/).filter(Boolean)
```

Formats with positional whitespace: `git status --porcelain`, `git diff --stat`, `column`-aligned output.

## Source Instincts

- `use-crlf-safe-regex`: "when writing regex to match line endings in cross-platform code"
- `use-execfilesync-on-windows`: "when using execSync with format strings containing %, ^, !, or & on Windows"
- `no-trim-on-structured-cli-output`: "when parsing structured CLI output where whitespace has semantic meaning"
