# Learned Skills Index

23 skills organized by domain. Original files remain at `learned/` root for backward compatibility.
Organized copies in subdirectories for browsing.

## Platform (3 skills)
- `platform/powershell-stdin-hooks.md` — PowerShell stdin reading in hooks
- `platform/git-bash-npm-path-mangling.md` — Git Bash path rewriting breaks npm
- `platform/git-bash-powershell-variable-stripping.md` — Git Bash strips $ from PowerShell

## Security (4 skills)
- `security/cookie-auth-over-query-strings.md` — httpOnly cookie auth with HMAC tokens
- `security/ssrf-prevention-ip-validation.md` — Block private IPs before external calls
- `security/slug-path-traversal-guard.md` — URL slug params need sanitization
- `security/token-secret-safety.md` — Never echo full token values

## Claude Code (8 skills)
- `claude-code/mcp-config-location.md` — MCP config file location
- `claude-code/command-yaml-frontmatter.md` — YAML frontmatter requirement
- `claude-code/claude-code-debug-diagnostics.md` — Debug startup diagnostics
- `claude-code/heredoc-permission-pollution.md` — HEREDOC commit body pollution
- `claude-code/shallow-fetch-force-push.md` — Shallow fetch breaks force push
- `claude-code/settings-validation-debugging.md` — Debug "invalid settings files" crash loops
- `claude-code/interactive-mode-freeze-recovery.md` — Fix TUI keyboard freeze via stale state cleanup
- `claude-code/context-compaction-pre-flight.md` — Plan for context window limits in large sessions

## API (1 skill)
- `anthropic-model-id-format.md` — Anthropic model IDs require exact date suffixes, no `-latest` for Haiku

## Testing (1 skill)
- `vitest-class-mock-constructor.md` — Class-based factory mock for SDK constructors in vitest

## Next.js (4 skills)
- `nextjs/nextjs-client-component-metadata.md` — Client component metadata workaround
- `nextjs/mdx-same-date-sort-order.md` — Same-date MDX sort fix
- `nextjs/mdx-blog-design-system.md` — MDX callouts and product badges
- `nextjs/vercel-json-waf-syntax.md` — vercel.json WAF route syntax

## Workflow (2 skills)
- `blog-post-production-pipeline.md` — Repeatable 8-step blog post production workflow
- `parallel-agent-decomposition.md` — When and how to parallelize with agents for 45%+ time savings
