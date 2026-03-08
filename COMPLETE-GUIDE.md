# The Complete Guide to Configuring Claude Code

A comprehensive walkthrough of this configuration repository. Whether you have never used a CLI before or you are an experienced developer looking to optimize your AI-assisted workflow, this guide explains every component, every setting, and every decision.

---

## Table of Contents

1. [What Is Claude Code?](#what-is-claude-code)
2. [How Configuration Works](#how-configuration-works)
3. [User-Level Configuration](#user-level-configuration)
   - [Settings: `~/.claude/settings.json`](#settings-file)
   - [MCP Servers: `~/.claude.json`](#mcp-servers)
   - [Rules: `~/.claude/rules/`](#rules)
   - [Custom Agents: `~/.claude/agents/`](#custom-agents)
   - [Learned Skills: `~/.claude/skills/learned/`](#learned-skills)
   - [Custom Skills: `~/.claude/skills/*/SKILL.md`](#custom-skills)
   - [Custom Commands: `~/.claude/commands/`](#custom-commands)
   - [Hooks: `~/.claude/hooks/`](#hooks)
   - [Homunculus: Continuous Learning](#homunculus-continuous-learning)
   - [Templates](#templates)
   - [Backup Strategy](#backup-strategy)
4. [Project-Level Configuration](#project-level-configuration)
   - [Project Instructions: `CLAUDE.md`](#project-instructions-claudemd)
   - [Project Settings: `.claude/settings.local.json`](#project-settings)
5. [How to Set This Up From Scratch](#how-to-set-this-up-from-scratch)
6. [Key Concepts Explained](#key-concepts-explained)
7. [Troubleshooting](#troubleshooting)

---

## What Is Claude Code?

Claude Code is a command-line tool (CLI) made by Anthropic that lets you have conversations with Claude AI directly in your terminal. Unlike the web chat at claude.ai, Claude Code can:

- **Read and edit files** on your computer
- **Run terminal commands** (build software, run tests, manage git)
- **Search your codebase** to understand existing code
- **Create commits and pull requests** on GitHub
- **Use external tools** through MCP servers and plugins

Think of it as an AI assistant that lives inside your terminal and can directly interact with your files, tools, and development environment.

**Install it:**
```bash
npm install -g @anthropic-ai/claude-code
```

**Start it:**
```bash
cd your-project-folder
claude
```

That is all you need. You are now in a conversation with Claude inside your project.

---

## How Configuration Works

Claude Code reads configuration from **two levels**:

```
USER-LEVEL (~/.claude/)              PROJECT-LEVEL (your-project/.claude/)
Applies to ALL your projects         Applies to ONE project only
Lives in your home directory         Lives inside the project folder
Not shared with collaborators        Can be shared via git
```

| File | Level | Purpose |
|------|-------|---------|
| `~/.claude/settings.json` | User | Plugins, model, update preferences |
| `~/.claude.json` | User | MCP servers (external tools) |
| `~/.claude/rules/**/*.md` | User | Coding standards Claude follows everywhere |
| `~/.claude/agents/*.md` | User | Custom agent definitions |
| `~/.claude/skills/` | User | Invocable workflows and learned patterns |
| `~/.claude/hooks/` | User | Lifecycle automation scripts |
| `~/.claude/homunculus/` | User | Continuous learning instincts |
| `your-project/CLAUDE.md` | Project | Instructions specific to this project |
| `your-project/.claude/settings.local.json` | Project | Permissions, hooks, project-specific config |

When you open a project with Claude Code, it loads **both** levels automatically and merges them together. User-level settings apply everywhere. Project-level settings add or override for that specific project.

> **Where is `~`?**
> - **macOS:** `/Users/YourName/`
> - **Linux:** `/home/YourName/`
> - **Windows:** `C:\Users\YourName\`

---

## User-Level Configuration

These files live in your home directory under `~/.claude/` and apply to every project you open with Claude Code.

---

### Settings File

**File:** `~/.claude/settings.json`

This is Claude Code's main settings file. Here is the configuration from this repo's template (`templates/settings.json.template`):

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "permissions": {
    "allow": []
  },
  "model": "YOUR_PREFERRED_MODEL",
  "enabledPlugins": {
    "everything-claude-code@everything-claude-code": true
  },
  "autoUpdatesChannel": "latest"
}
```

**Field by field:**

| Field | What It Does |
|-------|-------------|
| `env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Enables experimental agent teams feature |
| `permissions.allow` | Pre-approved tool permissions (grows as you approve actions) |
| `model` | Default model (e.g., `claude-sonnet-4-20250514`) |
| `enabledPlugins` | Active plugins. Format: `"pluginName@marketplaceName": true` |
| `autoUpdatesChannel` | Update channel: `"latest"`, `"stable"`, or `"none"` |

**Installing the everything-claude-code plugin:**
```bash
# From inside a Claude Code session:
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code
```

This plugin provides 13 specialized agents, 30+ slash commands, and 30+ built-in skills. The `agents.md` rule file in this repo references its agents for automatic activation.

---

### MCP Servers

**File:** `~/.claude.json` (in your home directory, NOT inside `~/.claude/`)

MCP stands for **Model Context Protocol**. MCP servers are external programs that give Claude Code capabilities it does not have built in. Think of them as plugins that add new tools.

> **Common mistake:** `~/.claude/mcp-servers.json` is for Claude Desktop (the desktop app), not Claude Code. Claude Code reads MCP config from `~/.claude.json`. If you put servers in the wrong file, they will not load.

This repo configures 7 MCP servers. Here is what each one does and how to set it up.

#### Server 1: memory (Knowledge Graph)

Gives Claude persistent memory across sessions. Without this, Claude forgets everything when you close the terminal.

```bash
claude mcp add --scope user memory -- npx -y @modelcontextprotocol/server-memory
```

**Tools it adds:** `create_entities`, `create_relations`, `add_observations`, `search_nodes`, `open_nodes`, `delete_entities`, `delete_observations`, `delete_relations`, `read_graph`

**No API key required.** Data is stored locally.

#### Server 2: context7 (Live Documentation)

Fetches up-to-date documentation for any library or framework. Claude's training data has a cutoff date; context7 fills that gap by looking up current docs on demand.

```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest
```

**Tools it adds:** `resolve-library-id`, `query-docs`

**No API key required.** Pulls from the Context7 public index.

#### Server 3: sequential-thinking (Extended Reasoning)

Provides a structured reasoning tool for complex multi-step problems.

```bash
claude mcp add --scope user sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking
```

**Tools it adds:** `sequentialthinking`

**No API key required.**

#### Server 4: github (GitHub API)

Full GitHub API access for issues, pull requests, repositories, and code search.

```bash
claude mcp add-json --scope user github '{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_TOKEN_HERE" }
}'
```

**Setup:** Create a Personal Access Token at https://github.com/settings/tokens with `repo`, `read:org`, and `read:user` scopes.

> We use `add-json` instead of `add` because the `--env` flag can be unreliable with long token values.

#### Server 5: project-tools (Custom)

A custom MCP server providing project-specific tools: multi-repo git status, blog post inventory, style guide retrieval, blog post validation, and session artifact summary.

```json
"project-tools": {
  "type": "stdio",
  "command": "node",
  "args": ["YOUR_CONFIG_REPO_PATH/mcp-servers/project-tools/index.js"],
  "env": {
    "PROJECT_ROOT": "YOUR_PROJECTS_DIR",
    "CLAUDE_CONFIG": "YOUR_CLAUDE_HOME"
  }
}
```

**Setup:**
1. `cd mcp-servers/project-tools && npm install`
2. Update the `args` path to point to your local copy of `index.js`
3. Set `PROJECT_ROOT` to the directory containing your git repos
4. Set `CLAUDE_CONFIG` to your `~/.claude` directory

**Tools it adds:** `repo_status`, `blog_posts`, `style_guide`, `validate_blog_post`, `session_artifacts`

#### Server 6: vector-memory (Long-Term Memory)

Hybrid vector + keyword search for long-term memory storage. Uses Ollama for local embeddings and sqlite-vec for storage. This is the primary memory system for storing detailed context like bug resolutions, architectural decisions, and workarounds.

```json
"vector-memory": {
  "type": "stdio",
  "command": "YOUR_PYTHON_PATH",
  "args": ["-m", "mcp_memory_service.server"],
  "env": {
    "MCP_MEMORY_STORAGE_BACKEND": "sqlite_vec"
  }
}
```

**Setup:**
1. Install Ollama: https://ollama.com
2. Pull the embedding model: `ollama pull nomic-embed-text`
3. Install the Python package: `pip install mcp-memory-service`
4. Set `command` to your Python 3.11+ path (e.g., `/opt/homebrew/bin/python3.11` on macOS)

**Tools it adds:** `memory_store`, `memory_search`, `memory_list`, `memory_delete`, `memory_update`, `memory_stats`, `memory_health`, `memory_quality`, `memory_graph`, `memory_cleanup`, `memory_ingest`

#### Server 7: obsidian (Vault Access)

Read and write files in an Obsidian vault. Requires the Obsidian MCP Tools community plugin.

```json
"obsidian": {
  "type": "stdio",
  "command": "YOUR_OBSIDIAN_MCP_BINARY_PATH",
  "args": [],
  "env": {
    "OBSIDIAN_API_KEY": "YOUR_OBSIDIAN_API_KEY_HERE",
    "OBSIDIAN_USE_HTTP": "true"
  }
}
```

**Setup:**
1. Install the "MCP Tools" community plugin in Obsidian
2. Enable it and copy the API key from the plugin settings
3. Set `command` to the plugin's `mcp-server` binary path

#### Full Configuration Template

See `templates/claude.json.template` for a complete JSON file with the first 5 servers pre-configured. Copy it to `~/.claude.json` and fill in your paths and tokens.

#### Verifying Your Servers

After adding servers, restart Claude Code and verify:

```bash
# Inside a Claude Code session:
/mcp

# Or from the terminal:
claude mcp list
```

All servers should show as "connected." If any show "failed," see the [Troubleshooting](#troubleshooting) section.

---

### Rules

**Location:** `~/.claude/rules/` (organized in 4 subdirectories)

Rules are persistent instructions that Claude follows in every session, in every project. They are loaded automatically at session start. Each rule is a Markdown file.

This repo contains 12 rule files organized by domain:

```
rules/
  agents.md                  # Agent orchestration framework
  core/
    agentic-workflow.md      # Parallel task decomposition, model routing
    coding-style.md          # Immutability, file org, error handling, no em dashes
    memory-management.md     # Five memory systems with boundaries and triggers
    security.md              # Pre-commit security checklist, secret management
  content/
    blog-content.md          # Blog writing rules (no private repo links)
  development/
    git-workflow.md          # Conventional commits, PR workflow, TDD
    patterns.md              # Repository pattern, API envelopes, skeleton projects
    testing.md               # TDD workflow, 80% minimum coverage
  operations/
    hooks.md                 # Hook types, file protection, context preservation
    macos-platform.md        # macOS/zsh, Homebrew, osascript notifications
    performance.md           # Model selection (Haiku/Sonnet/Opus), cost optimization
    windows-platform.md      # PowerShell stdin, Git Bash path mangling, OneDrive
```

#### Key Rules Explained

**`coding-style.md`** enforces consistent code quality:
- Immutability: always create new objects, never mutate existing ones
- File organization: 200-400 lines typical, 800 max, organize by feature
- Error handling: handle explicitly at every level, never silently swallow errors
- Writing style: never use em dashes in any written content

**`security.md`** runs a mandatory pre-commit checklist:
- No hardcoded secrets
- All user inputs validated
- SQL injection prevention (parameterized queries)
- XSS prevention (sanitized HTML)
- Rate limiting on all endpoints
- Security response protocol (stop, fix, rotate, review)

**`agentic-workflow.md`** requires parallel task decomposition:
- Every non-trivial task must be broken into parallel agents
- Automatic agent triggers (code written -> code-reviewer, bug report -> parallel explore agents)
- Model routing table (haiku for search, sonnet for code, opus for architecture)
- Cost optimization (use the cheapest model that is good enough)

**`memory-management.md`** defines five distinct memory systems:

| System | Scope | Use For |
|--------|-------|---------|
| Auto memory (`MEMORY.md`) | Per-project, auto-loaded | Stable project facts (build commands, structure) |
| Vector memory (MCP) | Global, on-demand | Detailed context (bug fixes, decisions, workarounds) |
| Knowledge graph (MCP) | Global, on-demand | Entity relationships (service deps, data flows) |
| Homunculus (hooks) | Global, auto-captured | Behavioral pattern extraction |
| Session archive (hook) | Per-project, on exit | Full transcript backup |

**`testing.md`** enforces TDD with 80% minimum coverage:
1. RED: write a test that fails
2. GREEN: write minimal code to make it pass
3. REFACTOR: clean up with confidence
4. Verify 80%+ coverage

**`performance.md`** routes work to the right model:

| Model | Cost | Use For |
|-------|------|---------|
| Haiku 4.5 | $ | Background tasks, search, lightweight agents |
| Sonnet 4.5 | $$ | Day-to-day coding, code generation |
| Opus 4.6 | $$$ | Architecture decisions, security analysis |

---

### Custom Agents

**Location:** `~/.claude/agents/` (one `.md` file per agent)

Custom agents are specialized agent definitions that Claude Code's Task tool can spawn as subprocesses. Each agent has its own context window and focused instructions. No plugin required.

Each agent file uses YAML frontmatter to specify:
- `description`: what the agent does
- `model`: which Claude model to use (haiku, sonnet, opus, inherit)
- `tools`: which tools the agent can access

**This repo includes 13 agents:**

| Agent | Model | Purpose |
|-------|-------|---------|
| `blog-post-orchestrator` | sonnet | Orchestrate blog writing with research and MDX generation |
| `changelog-writer` | haiku | Generate CHANGELOG entries from git diffs |
| `config-sync` | haiku | Compare local config against git repo for drift |
| `context-health` | haiku | Monitor context window usage, suggest compaction |
| `deploy-verifier` | haiku | Post-deploy verification (build, live site) |
| `home-sync` | haiku | Sync config to backup repository |
| `multi-repo-orchestrator` | haiku | Parallel git operations across repos |
| `pre-commit-checker` | haiku | Pre-commit security and quality checks |
| `session-analyzer` | sonnet | Extract patterns from session archive transcripts |
| `session-checkpoint` | sonnet | Save/restore session context across compactions |
| `skill-extractor` | sonnet | Extract instincts from transcripts (Homunculus v2) |
| `sync-orchestrator` | haiku | Multi-repo config sync orchestration |
| `wrap-up-orchestrator` | haiku | End-of-session wrap-up (docs, commits, pushes) |

**How to create your own agent:**

```markdown
---
description: "What this agent does"
model: haiku
tools: [Read, Grep, Glob, Bash]
---

# Agent Name

You are a [specialist role]. Your job is to [objective].

## Process
1. First step
2. Second step

## Output
Describe the expected output format.
```

Save this as `~/.claude/agents/your-agent.md` and Claude Code's Task tool can spawn it.

---

### Learned Skills

**Location:** `~/.claude/skills/learned/` (one `.md` file per skill)

Learned skills are reusable debugging patterns extracted from real sessions. Each documents a non-obvious problem, its solution, and when the pattern applies. Claude loads these at session start and uses them to avoid repeating past mistakes.

This repo contains 23 unique skills organized into 6 categories (with copies in subdirectories for browsing):

| Category | Skills |
|----------|--------|
| **Claude Code** (8) | MCP config location, YAML frontmatter requirement, debug diagnostics, HEREDOC permission pollution, shallow fetch + force push, settings validation, interactive mode freeze, context compaction |
| **Security** (4) | Cookie auth over query strings, SSRF prevention with IP validation, path traversal guards, token secret safety |
| **Next.js** (4) | Client component metadata, MDX same-date sort order, MDX blog design system, Vercel WAF syntax |
| **Platform** (3) | PowerShell stdin hooks, Git Bash npm path mangling, Git Bash variable stripping |
| **Workflow** (2) | Blog post production pipeline, parallel agent decomposition |
| **API / Testing** (2) | Anthropic model ID format, Vitest class mock constructor |

Each skill follows this format:

```markdown
# Descriptive Pattern Name

**Extracted:** 2026-02-08
**Context:** Brief description of when this applies

## Problem
What went wrong and why it is non-obvious

## Solution
The fix or workaround

## When to Use
Trigger conditions for recognizing this situation
```

**How skills get created:** The primary path is through the Homunculus instinct system. Session observations become atomic instincts (with confidence scoring), and when 3+ instincts cluster in a domain, they graduate into learned skills. You can also run `/learn` mid-session or invoke the `skill-extractor` agent to extract instincts from transcripts.

See `skills/learned/INDEX.md` for the full index.

---

### Custom Skills

**Location:** `~/.claude/skills/*/SKILL.md`

Custom skills are user-invocable workflows triggered by slash commands. Each lives in its own subdirectory with a `SKILL.md` file containing YAML frontmatter and detailed instructions. Skills take priority over commands when both exist for the same name.

This repo includes 5 skills:

| Skill | What It Does |
|-------|-------------|
| `/wrap-up` | 12-step end-of-session agent: pull repos, review session, update CHANGELOG/README/MEMORY, extract skills, clean state, commit, push |
| `/blog-post` | Interactive blog writing agent: asks topic, gathers source material, writes formatted MDX post |
| `/multi-repo-status` | Git status dashboard across all project repos in parallel |
| `/skill-catalog` | Full inventory of all agents, skills, commands, and hooks with descriptions |
| `/sync` | Configuration sync across repos, mirrors local `~/.claude/` state to git backups |

Additional supporting files in `skills/`:
- `blog-mdx-reference.md`: MDX syntax reference for blog posts
- `blog-style-guide.md`: Blog writing standards and conventions

---

### Custom Commands

**Location:** `~/.claude/commands/` (one `.md` file per command)

Custom commands are slash commands that encode multi-step workflows into a single invocation. They are the predecessor to skills. When a skill and command share the same name, the skill takes priority.

This repo includes 2 commands:
- `blog-post.md`: Blog post writing (superseded by `/blog-post` skill)
- `ingest-sessions.md`: Session transcript ingestion for Homunculus learning

Each command file requires YAML frontmatter with a `description` field. Without it, Claude Code silently ignores the command.

```markdown
---
description: "What this command does in one line"
---

# /your-command - Title

Instructions for Claude to follow when this command is invoked.
```

---

### Hooks

**Location:** `~/.claude/hooks/` (or your project's `.claude/hooks/`)

Hooks are scripts that run automatically when Claude Code performs certain actions. They are like event listeners: when a specific event happens, your script fires.

| Hook Type | When It Fires | Example Use |
|-----------|--------------|-------------|
| **PreToolUse** | Before Claude uses a tool | Block edits to sensitive files |
| **PostToolUse** | After Claude uses a tool | Log the operation, trigger learning |
| **Stop** | When Claude finishes a response | Play notification sound |
| **SessionEnd** | When the session closes | Archive the transcript |

This repo includes 6 hook scripts:

| Script | Hook Type | What It Does |
|--------|-----------|-------------|
| `file-guard.sh` | PreToolUse | Checks if the target file is sensitive (.env, .pem, credentials). If so, exits non-zero to block the edit. |
| `log-activity.sh` | PostToolUse | Appends a timestamped log entry for each tool use (Bash, Edit, Write, NotebookEdit). Runs async so it does not block Claude. |
| `memory-nudge.sh` | PostToolUse | Analyzes tool output and reminds Claude to save significant findings to vector memory. |
| `observe-homunculus.sh` | PostToolUse | Captures behavioral observations and appends them to `observations.jsonl` for later instinct extraction. |
| `prompt-notify.sh` | Stop | Plays a system notification sound (macOS: `osascript`, Windows: `[console]::beep`) when Claude finishes responding. |
| `save-session.sh` | SessionEnd | Reads session metadata from stdin (JSON with `transcript_path` and `session_id`), copies the transcript to a dated archive directory. |

#### Hook Configuration

Hooks are configured in `.claude/settings.local.json`. This repo includes a template at `hooks/settings.local.json.template`:

```json
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(ls:*)",
      "WebSearch",
      "..."
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "HOOK_COMMAND_FILE_GUARD"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash|Edit|Write|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "HOOK_COMMAND_LOG_ACTIVITY",
            "async": true
          }
        ]
      },
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "HOOK_COMMAND_OBSERVE_HOMUNCULUS",
            "async": true
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "HOOK_COMMAND_PROMPT_NOTIFY"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "HOOK_COMMAND_SAVE_SESSION"
          }
        ]
      }
    ]
  }
}
```

**To set up hooks:**
1. Copy the template to your project's `.claude/settings.local.json`
2. Replace each `HOOK_COMMAND_*` placeholder with the actual command, for example:
   - **macOS:** `"bash /path/to/hooks/file-guard.sh"`
   - **Windows:** `"powershell -NoProfile -ExecutionPolicy Bypass -Command \". '/path/to/hooks/file-guard.ps1'\""`
3. Ensure hook scripts are executable: `chmod +x hooks/*.sh`

**Key configuration fields:**
- `matcher`: which tools trigger the hook (`"Edit|Write"` means Edit or Write, `"*"` means all tools)
- `async`: if `true`, the hook runs in the background without blocking Claude
- `type`: always `"command"` for shell-based hooks

---

### Homunculus: Continuous Learning

**Location:** `~/.claude/homunculus/` (or `homunculus/` in this repo)

The Homunculus system is a continuous learning loop that extracts behavioral patterns from Claude Code sessions and encodes them as atomic instincts.

#### How It Works

```
Session work
    |
    v
observe-homunculus.sh hook  -->  observations.jsonl (raw behavioral data)
    |
    v
skill-extractor agent  -->  instincts/personal/*.md (atomic instincts, 0.4 confidence)
    |
    v
When 3+ instincts cluster  -->  Graduated into learned skills (skills/learned/)
```

1. During every session, the `observe-homunculus.sh` PostToolUse hook captures what Claude does and appends observations to `observations.jsonl`.
2. The `skill-extractor` agent (or the `/wrap-up` skill) processes accumulated observations and session transcripts, extracting atomic instincts.
3. Each instinct starts at 0.4 confidence. Repeated evidence across sessions increases confidence.
4. When 3+ related instincts cluster in a domain, they can be promoted into full learned skills.

#### Directory Structure

```
homunculus/
  identity.json.template     # User identity profile
  instincts/
    personal/                 # 30 auto-extracted instincts
    inherited/.gitkeep        # Space for instincts shared by other users
  evolved/
    agents/.gitkeep           # Agents evolved from instinct clusters
    commands/.gitkeep         # Commands evolved from patterns
    skills/.gitkeep           # Skills evolved from patterns
```

#### Identity Template

The `identity.json.template` captures user preferences that influence instinct extraction:

```json
{
  "name": "YOUR_GITHUB_USERNAME",
  "technical_level": "intermediate-advanced",
  "primary_stack": ["Next.js", "React", "TypeScript", "Tailwind CSS", "PostgreSQL"],
  "preferences": {
    "immutability": true,
    "functional_style": true,
    "small_files": true,
    "commit_style": "conventional-commits",
    "no_em_dashes": true
  }
}
```

Copy this template, fill in your values, and save it as `identity.json`.

---

### Templates

**Location:** `templates/` in this repo

Templates are starter configuration files. Copy them to the target locations and fill in your values.

| Template | Copy To | What It Configures |
|----------|---------|-------------------|
| `claude.json.template` | `~/.claude.json` | MCP server definitions (5 servers pre-configured) |
| `settings.json.template` | `~/.claude/settings.json` | Model preference, plugins, permissions, update channel |
| `env.sh.template` | `~/.claude/scripts/env.sh` | Shared environment variables (repo paths, tool paths) |
| `gitignore.template` | `~/.claude/.gitignore` | Git ignore rules for backing up portable config |

**Example: setting up env.sh:**
```bash
cp templates/env.sh.template ~/.claude/scripts/env.sh
# Edit the file and set your paths:
# PROJECTS_DIR="/Users/you/Projects"
# REPO_CJCLAUDE="$PROJECTS_DIR/your-project"
```

---

### Backup Strategy

**File:** `~/.claude/.gitignore` (use `templates/gitignore.template` as a starting point)

The gitignore uses an **ignore-everything-then-whitelist** pattern:

```gitignore
# Ignore everything by default
*

# Track portable configuration
!.gitignore
!README.md
!rules/
!rules/**
!agents/
!agents/*.md
!skills/
!skills/**
!commands/
!commands/*.md
!scripts/
!scripts/*.sh
!hooks/
!hooks/**

# Never track (even if whitelisted above)
cache/
sessions/
history.jsonl
settings.json
projects/
node_modules/
.env
*.pem
*.key
```

**What gets backed up:** Rules, agents, skills, commands, scripts, hooks (your portable configuration).

**What stays local:** Session history, caches, settings with machine-specific paths, secrets, node_modules.

**To set up a config backup repo:**
```bash
cd ~/.claude
git init
cp /path/to/claude-code-config/templates/gitignore.template .gitignore
git add -A
git commit -m "Initial config backup"

# Push to GitHub
gh repo create my-claude-config --private --source=. --push
```

---

## Project-Level Configuration

These files live inside a specific project and only affect that project.

---

### Project Instructions: `CLAUDE.md`

**File:** `your-project/CLAUDE.md` (in the project root)

This is the first thing Claude reads when you open a project. It tells Claude what the project is, how to work on it, and what rules to follow. Think of it as the project's onboarding document.

**Minimal template:**

```markdown
# Project Context

[Describe your project in 1-2 sentences]

## Tech Stack
- Language: [e.g., TypeScript]
- Framework: [e.g., Next.js 15]
- Database: [e.g., PostgreSQL]

## Session Instructions
1. [Your rules for Claude to follow every session]
2. [e.g., "Always use TypeScript strict mode"]
3. [e.g., "Update CHANGELOG.md after significant changes"]

## Project Structure
[Key directories and their purposes]
```

**Best practices:**
- Keep it concise. Claude reads this every session, so every line costs context window space.
- Include tech stack and key constraints so Claude does not make wrong assumptions.
- Document hooks and automation that are already in place so Claude does not duplicate them.

---

### Project Settings

**File:** `your-project/.claude/settings.local.json`

This file configures permissions and hooks for a specific project. See the [Hooks](#hooks) section for the full template.

**Permissions** pre-approve specific actions so Claude does not ask every time:

```json
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(npm:*)",
      "WebSearch"
    ]
  }
}
```

**Permission format:**
- `"Bash(git:*)"`: allow any git command
- `"Bash(npm test:*)"`: allow `npm test` with any arguments
- `"WebFetch(domain:docs.claude.com)"`: allow fetching from a specific domain
- `"mcp__memory__search_nodes"`: allow a specific MCP tool

**Security note:** Be deliberate with wildcards. `Bash(*)` would allow Claude to run any command without asking. The permissions in this config are intentionally specific.

> **Tip:** You do not need to write permissions by hand. When Claude asks "Allow this command?" and you approve it, Claude Code automatically adds it to the permissions list. Over time, your permissions file fills up with commands you have approved.

---

## How to Set This Up From Scratch

### Prerequisites

1. **Node.js** (v18 or newer): https://nodejs.org/
2. **Git**: https://git-scm.com/
3. **Claude Code**: `npm install -g @anthropic-ai/claude-code`
4. **A Claude account** with API access or a Pro/Team subscription

### Step 1: Clone This Repo

```bash
cd ~/GitProjects  # or wherever you keep repos
git clone https://github.com/chris2ao/claude-code-config.git
```

### Step 2: Copy Rules

```bash
mkdir -p ~/.claude/rules
cp -r claude-code-config/rules/* ~/.claude/rules/
```

Rules are active immediately. No restart needed (they are loaded at session start).

### Step 3: Set Up MCP Servers

Start with the two core servers:

```bash
claude mcp add --scope user memory -- npx -y @modelcontextprotocol/server-memory
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest
```

Add more as needed (see [MCP Servers](#mcp-servers) section for all 7).

### Step 4: Copy Agents

```bash
cp -r claude-code-config/agents/ ~/.claude/agents/
```

### Step 5: Copy Skills

```bash
cp -r claude-code-config/skills/ ~/.claude/skills/
```

### Step 6: Install Hooks

```bash
cp -r claude-code-config/hooks/ ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

Then configure hooks in your project's `.claude/settings.local.json`. Use `hooks/settings.local.json.template` as a starting point, replacing `HOOK_COMMAND_*` placeholders with actual paths.

### Step 7: Set Up Templates

```bash
# Copy and customize the settings template
cp claude-code-config/templates/settings.json.template ~/.claude/settings.json
# Edit and set your preferred model

# Copy and customize the environment template
mkdir -p ~/.claude/scripts
cp claude-code-config/templates/env.sh.template ~/.claude/scripts/env.sh
# Edit and set your project paths
```

### Step 8: (Optional) Install the Plugin

Inside a Claude Code session:
```
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code
```

### Step 9: (Optional) Set Up Homunculus

```bash
cp -r claude-code-config/homunculus/ ~/.claude/homunculus/
cp ~/.claude/homunculus/identity.json.template ~/.claude/homunculus/identity.json
# Edit identity.json with your info
```

### Step 10: (Optional) Back Up Your Config

```bash
cd ~/.claude
git init
cp ~/GitProjects/claude-code-config/templates/gitignore.template .gitignore
git add -A
git commit -m "Initial config backup"
gh repo create my-claude-config --private --source=. --push
```

---

## Key Concepts Explained

### What Is a CLI?

CLI stands for Command Line Interface. It is a text-based way to interact with your computer by typing commands instead of clicking buttons. Claude Code runs in the CLI.

### What Is Git?

Git is a version control system that tracks changes to files over time. Every change is saved as a "commit" with a message describing what changed. You can go back to any previous version, see who changed what, and collaborate with others.

### What Is GitHub?

GitHub is a website that hosts Git repositories online. It adds collaboration features like pull requests (proposed changes for review), issues (bug reports and feature requests), and actions (automated workflows).

### What Is JSON?

JSON (JavaScript Object Notation) is a text format for storing structured data. It uses curly braces `{}` for objects, square brackets `[]` for lists, and `"key": "value"` pairs. Most Claude Code configuration files use JSON.

### What Is Markdown?

Markdown is a simple formatting language for text files (`.md`). It uses `#` for headings, `**` for bold, `-` for bullet points, and triple backticks for code blocks. All rule files, agent definitions, and this guide use Markdown.

### What Are Tokens?

In AI, a "token" is roughly a word or word-piece. Claude's context window is measured in tokens. When this config mentions context window management, it is referring to the limited amount of text Claude can "remember" within a single conversation.

### What Is npx?

`npx` is a tool that comes with Node.js. It downloads and runs a package temporarily without permanently installing it. All the `npx`-based MCP servers use `npx -y`, where `-y` means "yes, install without asking."

### What Are MCP Servers?

MCP (Model Context Protocol) servers are external programs that extend Claude Code's capabilities. They communicate via stdin/stdout and provide tools that Claude can call. Think of them as plugins that add new abilities (memory, documentation lookup, GitHub access).

---

## Troubleshooting

### MCP servers not loading

**Symptom:** `/mcp` shows "No MCP servers configured"

**Cause:** Servers are in the wrong config file.

**Fix:** Make sure servers are in `~/.claude.json` (NOT `~/.claude/mcp-servers.json`). Use `claude mcp add --scope user` to add them correctly.

### MCP server shows "failed"

**Symptom:** `/mcp` shows a server with "failed" status

**Cause:** Usually Node.js is not installed or not in PATH.

**Fix:**
1. Verify Node.js is installed: `node --version`
2. Try running the server manually: `npx -y @modelcontextprotocol/server-memory`
3. Restart Claude Code from a fresh terminal

### Vector memory server fails to start

**Symptom:** vector-memory server shows "failed" in `/mcp`

**Cause:** Python path is wrong, `mcp-memory-service` is not installed, or Ollama is not running.

**Fix:**
1. Verify Python 3.11+: `python3 --version`
2. Verify the package: `python3 -m mcp_memory_service.server --help`
3. Verify Ollama is running: `ollama list` (should show `nomic-embed-text`)
4. Check the `command` field in `~/.claude.json` points to the correct Python path

### Plugin commands not appearing

**Symptom:** Typing `/` does not show expected commands like `/plan` or `/verify`

**Cause:** Plugin command files may be missing YAML frontmatter.

**Fix:** Check that each command `.md` file starts with:
```yaml
---
description: What this command does
---
```

Plugin cache location: `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/commands/`

### Hooks not firing

**Symptom:** Activity log or session archive is not being created

**Fix checklist:**
1. Check `.claude/settings.local.json` has the hooks configured
2. Verify hook scripts exist at the paths referenced in the config
3. Verify scripts are executable: `ls -la hooks/*.sh` (should show `-rwxr-xr-x`)
4. On macOS, test manually: `echo '{"tool_name":"test"}' | bash hooks/log-activity.sh`
5. On Windows, use `-Command ". 'script.ps1'"` (dot-sourcing), not `-File script.ps1`

### Context window filling up

**Symptom:** Claude seems to forget earlier parts of the conversation or behaves erratically

**Fix:** Type `/compact` to summarize the conversation and free up space. Do this at natural stopping points (after finishing a task, before switching to something new). The `context-health` agent can help monitor usage.

### Permission denied errors

**Symptom:** Claude says "permission denied" when trying to run a command

**Fix:** Either approve the action when prompted, or pre-approve it in `.claude/settings.local.json` under `permissions.allow`. See the [Project Settings](#project-settings) section for the format.

### Hooks crash Claude Code

**Symptom:** Claude Code hangs or exits after a hook fires

**Fix:** Hooks should never crash. Add error handling at the top of every hook script:
- **Bash:** `set +e` (continue on errors)
- **PowerShell:** `$ErrorActionPreference = "SilentlyContinue"`

Also ensure async hooks have `"async": true` in the settings. A slow synchronous hook will block Claude from responding.

---

## Credits

- **[Claude Code](https://docs.claude.com/en/docs/claude-code)** by [Anthropic](https://www.anthropic.com/)
- **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** plugin by [Affaan Mustafa](https://github.com/affaan-m)
- **[Model Context Protocol](https://github.com/modelcontextprotocol)** community servers
- Configuration developed and documented by Chris with Claude
