# Architecture

This document explains how all components in the CJClaudin_Mac configuration system interact to extend Claude Code with custom rules, agents, skills, and learning capabilities.

## Overview

The configuration lives in `~/.claude/` and applies globally to all Claude Code sessions. When you install CJClaudin_Mac, it populates this directory with:

- **Rules** (`~/.claude/rules/`) loaded automatically into every session
- **Agents** (`~/.claude/agents/`) spawned via the Task tool
- **Skills** (`~/.claude/skills/`) invoked via `/commands`
- **Scripts** (`~/.claude/scripts/`) called by agents and skills
- **Homunculus** (`~/.claude/homunculus/`) continuous learning system
- **Commands** (`~/.claude/commands/`) user-facing shortcuts
- **Per-project hooks** (optional, in project `.claude/hooks/`)

The configuration applies to all projects on your machine. Project-specific hooks allow per-project customization.

## Component Flow

### Session Initialization

When a Claude Code session starts:

1. **Rules are loaded** from `~/.claude/rules/` into the system prompt
   - Core rules (coding style, security, agentic workflow)
   - Development rules (git workflow, patterns, testing)
   - Operations rules (hooks, performance, macOS platform)

2. **MCP servers connect** (if configured in `~/.claude.json`)
   - Context7 for documentation lookups
   - GitHub for repository operations
   - project-tools for repo status, blog tools, session artifacts
   - Custom MCP servers for additional capabilities

3. **Hooks are registered** from project `.claude/hooks/`
   - PreToolUse hooks validate operations before execution
   - PostToolUse hooks observe tool usage (file protection, logging, learning)
   - Stop hooks run when the session ends (notifications, cleanup)
   - SessionEnd hooks run when the session closes (archiving, backups)

### During the Session

**Agents are spawned** based on rules (automatic triggers):
- Complex feature request triggers `planner` agent
- Code changes trigger `code-reviewer` agent
- Security-sensitive changes trigger `security-reviewer` agent
- Multiple independent research queries trigger parallel `Explore` agents

**Skills are invoked** by the user via `/command` syntax:
- `/blog-post` generates blog posts from session transcripts
- `/wrap-up` runs 5-phase session cleanup (commit, push, archive, evolve, notify)
- User-defined commands can be added to `~/.claude/commands/`

**Scripts are executed** by agents and skills:
- `context-health.sh` monitors context window usage
- `wrap-up-survey.sh` presents session summary in dialog format
- `cleanup-session.sh` removes temporary files and logs

### Session End

When the session completes:

1. **SessionEnd hooks archive** the transcript to `~/.claude/transcripts/`
2. **Stop hooks notify** via system notification (macOS `osascript`)
3. **Homunculus observes** tool usage logged by PostToolUse hooks
4. **User invokes `/wrap-up`** (optional) to commit, push, and evolve instincts

## The Learning Loop (Homunculus v2)

Homunculus is a continuous learning system that observes sessions and evolves reusable patterns into instincts, skills, and agents.

### Observation Phase

**PostToolUse Hook** (`observe-homunculus.sh`) logs:
- Tool name and parameters
- Success/failure status
- Context (current directory, branch)
- Timestamp

Logs are written to `~/.claude/homunculus/observations/YYYYMMDD-HHMMSS.jsonl`.

### Extraction Phase

**skill-extractor Agent** (`~/.claude/agents/skill-extractor.md`) mines patterns:
1. Reads session transcripts from `~/.claude/transcripts/`
2. Identifies non-obvious fixes, platform quirks, repeated corrections
3. Extracts patterns into instincts in `~/.claude/homunculus/instincts/personal/`

Each instinct has:
- **Trigger** (when to apply the pattern)
- **Action** (what to do)
- **Pattern** (step-by-step instructions)
- **Evidence** (session dates where this pattern appeared)
- **Confidence** (0.3 to 0.9, based on evidence strength)
- **Domain** (platform, security, frontend, backend, etc.)

### Evolution Phase

**`/evolve` command** clusters related instincts:
- When 3+ instincts share the same domain, they can be evolved into:
  - A **learned skill** in `~/.claude/skills/learned/`
  - A **command** in `~/.claude/commands/`
  - An **agent** in `~/.claude/agents/`

Evolved components are promoted and the source instincts are marked as graduated.

### Identity Tracking

**`~/.claude/homunculus/identity.json`** records:
- Session count
- Total tools used
- Instincts learned
- Skills evolved
- Timestamp of last session

This creates a persistent identity that grows with each session.

## Execution Model

### Rules

Rules are markdown files in `~/.claude/rules/`. They are concatenated and injected into the system prompt at session start. Changes to rules require restarting Claude Code to take effect.

### Agents

Agents are markdown files in `~/.claude/agents/` with YAML frontmatter:

```markdown
---
description: "What the agent does"
model: haiku|sonnet|opus
tools: [Read, Write, Bash, Grep, Glob]
---

# Agent Instructions

The agent's system prompt goes here.
```

Agents are spawned via the Task tool:
```
Task with subagent_type="changelog-writer", model="haiku"
```

Agents run in isolated contexts with their own conversation history. They communicate with the main session via the task system.

### Skills

Skills are multi-file programs in `~/.claude/skills/[skill-name]/`:
- `SKILL.md` contains the skill's instructions
- Optional supporting files (scripts, templates)

Skills are invoked via `/command` syntax and run in the main session context.

### Commands

Commands are markdown files in `~/.claude/commands/` that expand into prompts.

### Scripts

Scripts are standalone executables in `~/.claude/scripts/`:
- Bash scripts (`.sh`) for macOS

Scripts are called by agents, skills, and hooks. They should be idempotent and handle errors gracefully.

### Hooks

Hooks are per-project scripts in `.claude/hooks/` that run at specific events:

- **PreToolUse** runs before tool execution (validation, file protection)
- **PostToolUse** runs after tool execution (logging, observation)
- **Stop** runs when the session ends (notifications)
- **SessionEnd** runs when the session closes (archiving, cleanup)

Hooks receive JSON input via stdin with tool name, parameters, and result. They can:
- **Block** the operation (PreToolUse only, exit with non-zero code)
- **Modify** parameters (PreToolUse only, output modified JSON)
- **Log** activity (PostToolUse, append to log files)
- **Clean up** state (Stop, SessionEnd)

### Configuration Files

**`~/.claude.json`** (global Claude Code config):
- MCP server definitions (including project-tools)
- Tool permissions
- Auto-accept settings
- Plugin configuration

**`.claude/settings.local.json`** (per-project settings):
- Project-specific hooks
- Hook event mappings
- Working directory overrides

## Platform

CJClaudin_Mac is designed for macOS (Apple Silicon and Intel).

### macOS

**zsh** is the default shell. Scripts use `#!/usr/bin/env bash` for portability.

**Hooks** are `.sh` files that receive JSON via stdin:
```bash
#!/usr/bin/env bash
INPUT=$(cat)
echo "$INPUT" | jq -r '.toolName'
```

**MCP servers** use direct `npx` invocation:
```json
{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"]
}
```

**Notifications** use `osascript`:
```bash
osascript -e 'display notification "Session complete" with title "Claude Code"'
```

All tools (git, gh, node, npm) are available via Homebrew on PATH. No PATH manipulation needed.

## Model Routing

CJClaudin_Mac optimizes costs by routing tasks to the appropriate model.

### Model Selection Strategy

| Model | Capability | Cost | Use Cases |
|-------|-----------|------|-----------|
| **Haiku 4.5** | 90% of Sonnet | 3x cheaper | Read-only exploration, background tasks, search agents |
| **Sonnet 4.5** | Best coding model | Standard | Main development work, code generation |
| **Opus 4.6** | Deepest reasoning | Most expensive | Architecture decisions, security analysis, research |

### Subagent Model Routing

| Task Type | Subagent Type | Recommended Model |
|-----------|--------------|-------------------|
| File search, codebase exploration | Explore | haiku |
| Implementation planning | Plan | inherit |
| Code writing, bug fixes | general-purpose | sonnet |
| Code review | code-reviewer | inherit |
| Security analysis | security-reviewer | inherit |
| Build errors | build-error-resolver | inherit |
| Architecture decisions | architect | opus |
| Documentation updates | doc-updater | haiku |
| Research, web search | general-purpose | haiku |

## Multi-Repo Coordination

CJClaudin_Mac includes orchestrator agents for working across multiple repositories.

### wrap-up-orchestrator Agent

Coordinates `/wrap-up` across 5 repositories in parallel:
1. **Survey phase** asks user which repos to wrap up
2. **Parallel execution** spawns one agent per repo
3. **5-phase cleanup** per repo: commit, push, archive, evolve, notify
4. **Summary** reports success/failure per repo

### multi-repo-orchestrator Agent

General-purpose parallel operations:
- Search across all repos
- Apply the same change to multiple repos
- Collect metrics across repos
- Verify consistent configuration

## Context Window Management

CJClaudin_Mac monitors context usage and triggers compaction before exhaustion.

### context-health Agent

Monitors context window usage:
- Warns when entering the last 20% (avoid large refactors)
- Recommends checkpoint or compaction
- Single-file edits are safe at any context level

### Avoiding Context Pollution

**HEREDOC permission pollution** (common trap):
When using HEREDOCs in git commit messages, parentheses in the commit body can pollute auto-approved permissions. Use the format:
```bash
git commit -m "$(cat <<'EOF'
Subject line

Body text here.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

**Never use `--no-verify`** to skip hooks.

## Summary

CJClaudin_Mac creates a layered system:
- **Foundation**: Rules loaded into every session
- **Execution**: Agents, skills, and scripts extend capabilities
- **Observability**: Hooks log activity and protect sensitive files
- **Learning**: Homunculus extracts patterns and evolves them into reusable components
- **Platform**: macOS-native, Homebrew-based tooling
- **Optimization**: Model routing minimizes costs while maintaining quality
- **Coordination**: Orchestrators manage multi-repo workflows

The system is designed to grow with you. Every session adds observations. Observations become instincts. Instincts evolve into skills. Skills become automatic.
