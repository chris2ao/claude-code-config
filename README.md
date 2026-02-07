# Claude Code Config

Personal Claude Code configuration — rules, skills, and settings.

## The Complete Guide

**[COMPLETE-GUIDE.md](./COMPLETE-GUIDE.md)** — A line-by-line walkthrough of this entire configuration, written for beginners. Covers every config file, every setting, every rule, every MCP server, and every hook script with plain-English explanations. Suitable as a blog post or tutorial.

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

### Guide (`COMPLETE-GUIDE.md`)
Comprehensive educational walkthrough of the entire configuration — from "what is a CLI?" to advanced MCP server setup. Includes:
- What Claude Code is and how it works
- How user-level vs project-level config works
- Line-by-line explanation of every config file
- Step-by-step setup instructions for new machines
- Key programming concepts explained for beginners
- Troubleshooting common issues

## Setup

These files belong in `~/.claude/` (your user home). Claude Code automatically loads them for every project.

To replicate this config on a new machine:
1. Clone this repo into `~/.claude/`
2. Follow the setup steps in [COMPLETE-GUIDE.md](./COMPLETE-GUIDE.md#how-to-set-this-up-from-scratch)
