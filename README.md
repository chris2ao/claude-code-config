# Claude Code Config

A real-world Claude Code configuration built through hands-on exploration — not theory. This repo captures the rules, skills, and hard-won knowledge from pushing Claude Code to its limits over multiple intensive sessions.

If you've just installed Claude Code and wondered "what can this thing really do?" — you're in the right place.

## What You'll Find Here

This isn't a toy config. It's a production-ready setup that turns Claude Code from a smart autocomplete into something closer to a full engineering team. Here's what's inside:

### 8 Global Rule Files

Rules in `rules/` are loaded automatically into every Claude Code session across all your projects. They act as persistent instructions that shape how Claude works:

| Rule | What It Does |
|------|-------------|
| **coding-style.md** | Enforces immutability, small files (200-400 lines), small functions (<50 lines), and comprehensive error handling. Claude stops writing 800-line monoliths. |
| **testing.md** | Makes TDD mandatory. Write the test first, watch it fail, then implement. 80% coverage minimum. No exceptions. |
| **security.md** | Pre-commit security checklist: no hardcoded secrets, validated inputs, SQL injection prevention, XSS protection. Claude flags issues before they ship. |
| **git-workflow.md** | Conventional commits (`feat:`, `fix:`, `refactor:`), structured PR descriptions, and a feature workflow (plan -> TDD -> review -> commit). |
| **agents.md** | Tells Claude when to automatically spin up specialized agents — planner for complex features, code-reviewer after writing code, tdd-guide for bug fixes. |
| **performance.md** | Model selection strategy (Opus for architecture, Sonnet for dev, Haiku for background tasks), context window management, and extended thinking configuration. |
| **patterns.md** | Repository pattern, consistent API response envelopes, and "search for skeleton projects before building from scratch." |
| **hooks.md** | Hook system guidelines, permission management, and progress tracking with TodoWrite. |

The result: Claude follows your team's standards automatically, every session, without you repeating yourself.

### 3 Learned Skills

Skills in `skills/learned/` are reusable patterns extracted from real debugging sessions using the `/learn` command. Each one documents a problem that wastes hours if you don't know about it:

| Skill | The Gotcha |
|-------|-----------|
| **powershell-stdin-hooks.md** | PowerShell's `$input` silently returns nothing when hooks are invoked via `-File`. You need `[Console]::In.ReadToEnd()` + dot-sourcing. No error, no warning — just empty data. |
| **mcp-config-location.md** | `~/.claude/mcp-servers.json` is for Claude Desktop, not Claude Code. Claude Code reads `~/.claude.json`. Servers configured in the wrong file silently don't appear. |
| **command-yaml-frontmatter.md** | Custom slash commands in `.md` files are silently ignored without `---\ndescription: ...\n---` YAML frontmatter. The file exists, the content is valid, but Claude Code acts like it doesn't exist. |

### The Complete Guide

**[COMPLETE-GUIDE.md](./COMPLETE-GUIDE.md)** is a ~750-line walkthrough of this entire configuration, written for beginners. It covers every config file, every setting, every rule, and every MCP server with plain-English explanations. If you're writing a blog post about Claude Code setup or onboarding someone new, start here.

## Why This Setup is Worth Stealing

Out of the box, Claude Code is impressive. But with the right configuration, it becomes something else entirely:

- **Specialized agents** automatically activate for different tasks — a planner agent breaks down complex features, a security reviewer catches vulnerabilities, a TDD guide enforces test-first development. You don't invoke them manually; Claude knows when to use them based on context.
- **MCP servers** give Claude persistent memory across sessions, live documentation lookup for any library (no more outdated training data), structured chain-of-thought reasoning, and full GitHub API access. Five servers, all auto-installing via npx.
- **The hooks system** turns Claude Code into an observable system. Every tool operation is logged with timestamps. Every session transcript is archived automatically. You get a complete audit trail of everything Claude did and why.
- **Learned skills** mean Claude gets smarter over time. The `/learn` command extracts reusable patterns from your sessions and saves them for future reference. Debugging a nasty issue once means you never debug it again.

## Credits

The rules, agents, and many of the skills in this config are built on top of [**everything-claude-code**](https://github.com/affaan-m/everything-claude-code) by [Affaan Mustafa](https://github.com/affaan-m) — an incredible open-source collection of Claude Code configurations developed over 10+ months of intensive daily use. It provides 13 specialized agents, 30+ slash commands, 30+ skills, and a plugin system. MIT licensed, 41K+ stars, and well-deserved.

We installed everything-claude-code as a plugin and adapted the rule files for our workflow. The learned skills are original — extracted from our own debugging sessions. If you're looking for a comprehensive starting point for Claude Code configuration, everything-claude-code is the gold standard.

## What Advanced Features Should You Try?

If you're just getting started with Claude Code, here's the progression that worked for us:

1. **Start with rules.** Copy the `rules/` directory into your `~/.claude/` and immediately get better code quality, security checks, and TDD enforcement — zero effort after setup.

2. **Add MCP servers.** The memory server and context7 (live docs) are game-changers. Run `claude mcp add --scope user` to set them up. See [COMPLETE-GUIDE.md](./COMPLETE-GUIDE.md) for the exact commands.

3. **Install the everything-claude-code plugin.** One install gives you `/plan`, `/verify`, `/learn`, `/tdd`, and 30+ more commands. The agents (planner, code-reviewer, security-reviewer) start activating automatically.

4. **Use `/learn` after hard debugging sessions.** Extract the patterns that took you hours to figure out. Your future self will thank you.

5. **Explore orchestrated workflows.** Multi-agent pipelines like planner -> tdd-guide -> code-reviewer -> security-reviewer run automatically for complex features. This is where Claude Code starts feeling like a team, not a tool.

The deeper you go, the more Claude Code surprises you. We started this journey thinking we'd build a simple session logger and ended up with a fully orchestrated AI development environment. Your path will be different, but the tools are all here.

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

### Skills (`skills/learned/`)
Learned patterns extracted from Claude Code sessions:
- `powershell-stdin-hooks.md` — PowerShell stdin reading in Claude Code hooks (Windows)
- `mcp-config-location.md` — MCP server config: Claude Code vs Claude Desktop
- `command-yaml-frontmatter.md` — YAML frontmatter requirement for slash commands

### Guide (`COMPLETE-GUIDE.md`)
Comprehensive educational walkthrough of the entire configuration — from "what is a CLI?" to advanced MCP server setup.

## Setup

These files belong in `~/.claude/` (your user home). Claude Code automatically loads them for every project.

To replicate this config on a new machine:
1. Clone this repo into `~/.claude/`
2. Follow the setup steps in [COMPLETE-GUIDE.md](./COMPLETE-GUIDE.md#how-to-set-this-up-from-scratch)
