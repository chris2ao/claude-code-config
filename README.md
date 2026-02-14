# Claude Code Config

A real-world Claude Code configuration built through hands-on exploration, not theory. This repo captures the rules, agents, skills, and hard-won knowledge from pushing Claude Code to its limits over multiple intensive sessions.

If you've just installed Claude Code and wondered "what can this thing really do?" you're in the right place.

## Prerequisites

The **rules** in this repo work standalone. Copy `rules/` into `~/.claude/` and they're active immediately. No plugin or external dependency needed.

The **plugin agents** (`agents.md`) require the [everything-claude-code](https://github.com/affaan-m/everything-claude-code) plugin by Affaan Mustafa. Without it, plugin agent references like "use the planner agent" won't do anything. Install it with:

```bash
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code
```

The **custom agents** (`agents/`) work standalone with Claude Code's built-in Task tool. No plugin needed.

The **MCP servers** we recommend (memory, context7) require [Node.js](https://nodejs.org/) installed. They auto-install via `npx` on first use.

## What You'll Find Here

This isn't a toy config. It's a production-ready setup that turns Claude Code from a smart autocomplete into something closer to a full engineering team. Here's what's inside:

### 10 Global Rule Files (3 subdirectories)

Rules in `rules/` are loaded automatically into every Claude Code session across all your projects. They act as persistent instructions that shape how Claude works.

```
rules/
  agents.md              — Agent orchestration (plugin + custom agents)
  core/
    agentic-workflow.md   — Mandatory task decomposition, parallel agent patterns
    coding-style.md       — Immutability, file organization, em-dash prohibition
    security.md           — Pre-commit security checklist, secret management
  development/
    git-workflow.md       — Conventional commits (Hulk Hogan body), PRs, TDD workflow
    patterns.md           — Repository pattern, API response envelopes
    testing.md            — 80% coverage, TDD: RED-GREEN-REFACTOR
  operations/
    hooks.md              — Hook types, file protection, context preservation
    performance.md        — Model routing (Haiku/Sonnet/Opus), cost optimization
    windows-platform.md   — PowerShell stdin, path mangling, OneDrive workarounds
```

Total context cost across all 10 files: ~250 lines.

### 7 Custom Agents

Agents in `agents/` are specialized agent definitions that Claude Code's Task tool can spawn. Each has a focused purpose and optimal model assignment:

| Agent | Model | Purpose |
|-------|-------|---------|
| **changelog-writer** | haiku | Auto-generate CHANGELOG.md entries from git diffs |
| **multi-repo-orchestrator** | haiku | Parallel git operations across all project repos |
| **session-analyzer** | sonnet | Extract patterns from session archive transcripts |
| **deploy-verifier** | haiku | Post-deploy verification for cryptoflexllc.com |
| **config-sync** | haiku | Compare local config against this git repo |
| **context-health** | haiku | Monitor context window, suggest compaction points |
| **skill-extractor** | sonnet | Extract reusable skills from conversation history |

### 18 Learned Skills

Skills in `skills/learned/` are reusable patterns extracted from real debugging sessions. Each one documents a problem that wastes hours if you don't know about it:

| # | Skill | The Gotcha |
|---|-------|-----------|
| 1 | **powershell-stdin-hooks** | PowerShell's `$input` silently returns nothing when hooks are invoked via `-File`. You need `[Console]::In.ReadToEnd()` + dot-sourcing. |
| 2 | **mcp-config-location** | `~/.claude/mcp-servers.json` is for Claude Desktop, not Claude Code. Claude Code reads `~/.claude.json`. |
| 3 | **command-yaml-frontmatter** | Custom slash commands are silently ignored without YAML frontmatter. |
| 4 | **git-bash-npm-path-mangling** | Git Bash rewrites Windows paths, breaking npm module resolution. |
| 5 | **nextjs-client-component-metadata** | Can't export `metadata` from a `"use client"` component. Fix: wrapper `layout.tsx`. |
| 6 | **mdx-same-date-sort-order** | Blog posts with identical date strings sort non-deterministically. Fix: use ISO timestamps. |
| 7 | **slug-path-traversal-guard** | URL slug parameters in `path.join()` allow path traversal attacks. |
| 8 | **git-bash-powershell-variable-stripping** | Git Bash strips `$` from inline PowerShell commands. Fix: temp `.ps1` file. |
| 9 | **claude-code-debug-diagnostics** | `claude doctor` requires interactive TTY. Fix: `--debug --debug-file`. |
| 10 | **token-secret-safety** | Reading config files with plaintext API keys exposes them in transcripts. |
| 11 | **heredoc-permission-pollution** | HEREDOC commit bodies with parentheses pollute auto-approved permissions. |
| 12 | **cookie-auth-over-query-strings** | httpOnly cookies with HMAC-derived tokens, not `?secret=X` in URLs. |
| 13 | **ssrf-prevention-ip-validation** | Validate IPs against private ranges before external API calls. |
| 14 | **shallow-fetch-force-push** | `git fetch --depth=1` then `git push --force` fails. Fix: full fetch. |
| 15 | **mdx-blog-design-system** | MDX callout components and product badges for blog posts. |
| 16 | **vercel-json-waf-syntax** | vercel.json uses `routes` with `mitigate`, not `rules`. |
| 17 | **anthropic-model-id-format** | Haiku requires exact date suffix (`-20251001`), not `-latest`. |
| 18 | **vitest-class-mock-constructor** | Arrow functions can't be `new`'d. Use `class` in `vi.mock` factories. |

Organized into 6 categories via `INDEX.md`: Platform (3), Security (4), Claude Code (5), API (1), Testing (1), Next.js (4).

### 4 Custom Skills

Skills in `skills/` (with `SKILL.md` files) are user-invocable workflows:

| Skill | What It Does |
|-------|-------------|
| **`/wrap-up`** | 12-step end-of-session agent: pulls repos, updates CHANGELOG/README/MEMORY, extracts skills, cleans state, commits, pushes. |
| **`/blog-post`** | Interactive blog writing agent. Asks topic/angle, writes MDX post, delegates to Sonnet for content generation. |
| **`/multi-repo-status`** | Quick dashboard: git status across all 4 project repos in parallel. |
| **`/skill-catalog`** | Full inventory of all agents, skills, commands, and hooks with descriptions. |

### 2 Custom Commands

Commands in `commands/` are backward-compatible versions of the `/wrap-up` and `/blog-post` skills. Skills take priority when both exist.

### The Complete Guide

**[COMPLETE-GUIDE.md](./COMPLETE-GUIDE.md)** is a ~750-line walkthrough of this entire configuration, written for beginners. It covers every config file, every setting, every rule, and every MCP server with plain-English explanations.

## Recommended MCP Servers

We started with 5 MCP servers and trimmed to 2 that provide genuinely unique capabilities not already built into Claude Code:

| Server | Package | Why It's Worth It |
|--------|---------|------------------|
| **memory** | `@modelcontextprotocol/server-memory` | Persistent knowledge graph across sessions. Claude Code has no built-in cross-session memory. |
| **context7** | `@upstash/context7-mcp` | Live documentation lookup for any library. Gets current docs instead of relying on training data. |

**Servers we dropped** (and why):
- **filesystem** — Claude Code's built-in Read, Write, Edit, Glob, and Grep tools already handle file operations.
- **sequential-thinking** — Claude Code's built-in extended thinking (up to 31,999 tokens) covers this.
- **github** — The `gh` CLI via Bash covers most GitHub operations. Optional if you do heavy GitHub work.

Install the recommended servers:
```bash
claude mcp add --scope user memory -- npx -y @modelcontextprotocol/server-memory
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
```

## Why This Setup is Worth Stealing

Out of the box, Claude Code is impressive. But with the right configuration, it becomes something else entirely:

- **Specialized agents** automatically activate for different tasks. A planner breaks down features, a security reviewer catches vulnerabilities, a TDD guide enforces test-first development. You don't invoke them manually; Claude knows when to use them based on context.
- **Custom agents** extend beyond the plugin with project-specific automation: changelog generation, multi-repo orchestration, deploy verification, config drift detection, and skill extraction.
- **MCP servers** give Claude persistent memory across sessions and live documentation lookup for any library.
- **The hooks system** turns Claude Code into an observable system. Every tool operation is logged with timestamps. Every session transcript is archived automatically.
- **Learned skills** mean Claude gets smarter over time. Debugging a nasty issue once means you never debug it again.

## What Advanced Features Should You Try?

If you're just getting started with Claude Code, here's the progression that worked for us:

1. **Start with rules.** Copy `rules/` into `~/.claude/` and immediately get better code quality, security checks, and TDD enforcement.

2. **Add MCP servers.** The memory server and context7 (live docs) are game-changers. See install commands above.

3. **Install the everything-claude-code plugin.** One install gives you `/plan`, `/verify`, `/learn`, `/tdd`, and 30+ more commands. The agents start activating automatically.

4. **Copy the custom agents.** Drop `agents/` into `~/.claude/` for project-specific automation.

5. **Use `/learn` after hard debugging sessions.** Extract the patterns that took you hours to figure out. Your future self will thank you.

6. **Explore orchestrated workflows.** Multi-agent pipelines like planner -> tdd-guide -> code-reviewer -> security-reviewer run automatically for complex features. This is where Claude Code starts feeling like a team, not a tool.

## Directory Structure

```
rules/
  agents.md                              — Agent orchestration (plugin + custom)
  core/
    agentic-workflow.md                   — Parallel task decomposition rules
    coding-style.md                       — Code quality + writing style
    security.md                           — Security checklist + secret management
  development/
    git-workflow.md                       — Commits, PRs, feature workflow
    patterns.md                           — Repository pattern, API envelopes
    testing.md                            — TDD, 80% coverage
  operations/
    hooks.md                              — Hook types, file protection
    performance.md                        — Model routing, cost optimization
    windows-platform.md                   — Windows/PowerShell/OneDrive quirks

agents/
  changelog-writer.md                     — CHANGELOG generation from diffs
  multi-repo-orchestrator.md              — Parallel cross-repo git operations
  session-analyzer.md                     — Pattern extraction from transcripts
  deploy-verifier.md                      — Post-deploy site verification
  config-sync.md                          — Config drift detection
  context-health.md                       — Context window monitoring
  skill-extractor.md                      — Skill extraction from sessions

skills/
  wrap-up/SKILL.md                        — End-of-session documentation
  blog-post/SKILL.md                      — Blog post writing agent
  multi-repo-status/SKILL.md              — Multi-repo git dashboard
  skill-catalog/SKILL.md                  — Full capability inventory
  learned/
    INDEX.md                              — Organized index (18 skills, 6 categories)
    powershell-stdin-hooks.md
    mcp-config-location.md
    command-yaml-frontmatter.md
    git-bash-npm-path-mangling.md
    nextjs-client-component-metadata.md
    mdx-same-date-sort-order.md
    slug-path-traversal-guard.md
    git-bash-powershell-variable-stripping.md
    claude-code-debug-diagnostics.md
    token-secret-safety.md
    heredoc-permission-pollution.md
    cookie-auth-over-query-strings.md
    ssrf-prevention-ip-validation.md
    shallow-fetch-force-push.md
    mdx-blog-design-system.md
    vercel-json-waf-syntax.md
    anthropic-model-id-format.md
    vitest-class-mock-constructor.md

commands/
  wrap-up.md                              — /wrap-up (backward compat)
  blog-post.md                            — /blog-post (backward compat)
```

## Setup

These files belong in `~/.claude/` (your user home). Claude Code automatically loads them for every project.

To replicate this config on a new machine:
1. Clone this repo into `~/.claude/`
2. Follow the setup steps in [COMPLETE-GUIDE.md](./COMPLETE-GUIDE.md#how-to-set-this-up-from-scratch)

## Credits

The rules, agents, and many of the skills in this config are built on top of [**everything-claude-code**](https://github.com/affaan-m/everything-claude-code) by [Affaan Mustafa](https://github.com/affaan-m), an incredible open-source collection of Claude Code configurations developed over 10+ months of intensive daily use. It provides 13 specialized agents, 30+ slash commands, 30+ skills, and a plugin system. MIT licensed, 41K+ stars, and well-deserved.

We installed everything-claude-code as a plugin and adapted the rule files for our workflow. The learned skills are original, extracted from our own debugging sessions. If you're looking for the most comprehensive Claude Code configuration available, everything-claude-code is the gold standard.
