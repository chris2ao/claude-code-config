# Claude Code Configuration

A production-ready configuration for [Claude Code](https://docs.claude.com/en/docs/claude-code) with 12 rules, 13 agents, 5 skills, 23 learned skills, 9 scripts, 6 hooks, 7 MCP servers, and 30 instincts. Built through months of daily use across multiple projects on macOS and Windows.

## What This Is

This repo contains a complete, portable Claude Code setup that turns a single AI assistant into a team of specialized agents with persistent memory, automated hooks, and hard-won debugging knowledge. Copy what you need, adapt it to your workflow, and skip the trial-and-error we already went through.

For a detailed walkthrough aimed at beginners, see [COMPLETE-GUIDE.md](./COMPLETE-GUIDE.md).

## Quick Start

```bash
# 1. Copy rules (works standalone, no dependencies)
cp -r rules/ ~/.claude/rules/

# 2. Add MCP servers (requires Node.js)
claude mcp add --scope user memory -- npx -y @modelcontextprotocol/server-memory
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest

# 3. Copy custom agents
cp -r agents/ ~/.claude/agents/

# 4. Install hooks (copy scripts, then configure)
cp -r hooks/ ~/.claude/hooks/
# Edit hooks/settings.local.json.template and copy to your project's .claude/settings.local.json

# 5. Copy skills
cp -r skills/ ~/.claude/skills/

# 6. (Optional) Install the everything-claude-code plugin for plugin agents
# Inside a Claude Code session:
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code
```

## Component Inventory

### Rules (12 files)

Rules in `rules/` are loaded automatically into every Claude Code session. They shape how Claude writes code, handles security, manages git, and routes work to agents.

| File | Purpose |
|------|---------|
| `agents.md` | Agent orchestration framework (plugin + custom agents) |
| `core/agentic-workflow.md` | Mandatory parallel task decomposition with model routing |
| `core/coding-style.md` | Immutability, file organization, error handling, no em dashes |
| `core/memory-management.md` | Five memory systems with clear boundaries and save triggers |
| `core/security.md` | Pre-commit security checklist, secret management protocol |
| `content/blog-content.md` | Blog content rules (no private repo links) |
| `development/git-workflow.md` | Conventional commits, PR workflow, feature implementation |
| `development/patterns.md` | Repository pattern, API response envelopes, skeleton projects |
| `development/testing.md` | TDD workflow, 80% minimum coverage |
| `operations/hooks.md` | Hook types, file protection, context preservation |
| `operations/macos-platform.md` | macOS/zsh specifics, Homebrew paths, osascript notifications |
| `operations/performance.md` | Model selection (Haiku/Sonnet/Opus), cost optimization |
| `operations/windows-platform.md` | PowerShell stdin, Git Bash path mangling, OneDrive locks |

### Agents (13 files)

Agents in `agents/` are specialized agent definitions spawned via Claude Code's Task tool. Each has a focused role and optimal model assignment.

| Agent | Model | Purpose |
|-------|-------|---------|
| `blog-post-orchestrator` | sonnet | Orchestrate blog post writing with research and MDX generation |
| `changelog-writer` | haiku | Auto-generate CHANGELOG entries from git diffs |
| `config-sync` | haiku | Detect config drift between local and git repo |
| `context-health` | haiku | Monitor context window usage, suggest compaction points |
| `deploy-verifier` | haiku | Post-deploy verification (build check, live site) |
| `home-sync` | haiku | Harvest and sync config to backup repo |
| `multi-repo-orchestrator` | haiku | Parallel git operations across all project repos |
| `pre-commit-checker` | haiku | Pre-commit security and quality gate |
| `session-analyzer` | sonnet | Extract actionable patterns from session transcripts |
| `session-checkpoint` | sonnet | Save and restore session context across compactions |
| `skill-extractor` | sonnet | Extract instincts from transcripts (Homunculus v2) |
| `sync-orchestrator` | haiku | Multi-repo config sync orchestration |
| `wrap-up-orchestrator` | haiku | End-of-session wrap-up with docs, commits, pushes |

### Skills (5 invocable + 23 learned)

**Invocable skills** (in `skills/*/SKILL.md`) are slash commands for complex workflows:

| Skill | What It Does |
|-------|-------------|
| `/wrap-up` | 12-step end-of-session agent: pulls repos, updates docs, extracts skills, commits, pushes |
| `/blog-post` | Interactive blog writing agent with research and MDX generation |
| `/multi-repo-status` | Git status dashboard across all project repos in parallel |
| `/skill-catalog` | Full inventory of all agents, skills, commands, and hooks |
| `/sync` | Configuration sync across repos, mirrors local state to git backups |

**Learned skills** (in `skills/learned/`) are debugging patterns extracted from real sessions. Each documents a non-obvious problem and its solution. 23 unique skills organized into 6 categories:

| Category | Count | Examples |
|----------|-------|---------|
| Claude Code | 8 | MCP config location, HEREDOC permission pollution, context compaction |
| Security | 4 | SSRF prevention, path traversal guards, cookie auth |
| Next.js | 4 | Client component metadata, MDX sort order, Vercel WAF syntax |
| Platform | 3 | PowerShell stdin hooks, Git Bash path mangling |
| Workflow | 2 | Blog post pipeline, parallel agent decomposition |
| API / Testing | 2 | Anthropic model ID format, Vitest class mock constructor |

See `skills/learned/INDEX.md` for the full list with descriptions.

### Scripts (9 files)

Automation scripts in `scripts/` for common operations:

| Script | Purpose |
|--------|---------|
| `env.sh` | Shared environment variables (repo paths, tool paths) |
| `wrap-up-survey.sh` | Multi-repo wrap-up data collection |
| `sync-survey.sh` | Config sync status survey |
| `config-diff.sh` | Compare local config against git repo |
| `context-health.sh` | Context window health check |
| `blog-inventory.sh` | Blog post inventory and metadata |
| `cleanup-session.sh` | Clean up session artifacts |
| `git-stats.sh` | Git statistics across repos |
| `validate-mdx.sh` | Validate MDX blog post files |

## MCP Servers (7 configured)

MCP (Model Context Protocol) servers extend Claude Code with capabilities it does not have built in.

| Server | Package | Purpose |
|--------|---------|---------|
| **memory** | `@modelcontextprotocol/server-memory` | Knowledge graph for entity relationships |
| **context7** | `@upstash/context7-mcp` | Live library documentation lookup |
| **sequential-thinking** | `@modelcontextprotocol/server-sequential-thinking` | Structured multi-step reasoning |
| **github** | `@modelcontextprotocol/server-github` | GitHub API (issues, PRs, code search) |
| **project-tools** | Custom (local Node.js) | Repo status, blog tools, session artifacts |
| **vector-memory** | `mcp-memory-service` (Python) | Hybrid vector + keyword search for long-term memory |
| **obsidian** | Obsidian MCP plugin | Read/write Obsidian vault files |

### Install Commands

```bash
# Core servers (recommended for all users)
claude mcp add --scope user memory -- npx -y @modelcontextprotocol/server-memory
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest

# Extended reasoning
claude mcp add --scope user sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking

# GitHub API access (requires personal access token)
claude mcp add-json --scope user github '{
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_TOKEN_HERE" }
}'

# Project tools (custom, requires local setup)
# See mcp-servers/README.md for configuration details
cd mcp-servers/project-tools && npm install

# Vector memory (requires Python 3.11+ and Ollama)
# pip install mcp-memory-service
# ollama pull nomic-embed-text
# See mcp-servers/README.md for full setup

# Obsidian (requires Obsidian MCP Tools community plugin)
# See mcp-servers/README.md for binary path and API key setup
```

See [mcp-servers/README.md](./mcp-servers/README.md) for detailed configuration, JSON snippets, and troubleshooting.

## Hooks (6 lifecycle hooks)

Hooks in `hooks/` are shell scripts that fire automatically at different points in the Claude Code lifecycle. Configure them in your project's `.claude/settings.local.json` using the template at `hooks/settings.local.json.template`.

| Hook | Event | Purpose |
|------|-------|---------|
| `file-guard.sh` | PreToolUse | Block Edit/Write on sensitive files (.env, .pem, credentials) |
| `log-activity.sh` | PostToolUse | Log every tool execution with timestamps to activity log |
| `memory-nudge.sh` | PostToolUse | Remind Claude to save important context to vector memory |
| `observe-homunculus.sh` | PostToolUse | Capture behavioral observations for the Homunculus learning system |
| `prompt-notify.sh` | Stop | Play notification sound when Claude finishes a response |
| `save-session.sh` | SessionEnd | Archive full conversation transcript on session close |

**Setup:**
1. Copy `hooks/` to `~/.claude/hooks/` (or your project's `.claude/hooks/`)
2. Make scripts executable: `chmod +x hooks/*.sh`
3. Copy `hooks/settings.local.json.template` to `.claude/settings.local.json`
4. Replace the `HOOK_COMMAND_*` placeholders with actual paths to your hook scripts

## Homunculus (Continuous Learning System)

The `homunculus/` directory contains the continuous learning system that extracts behavioral patterns from session transcripts and encodes them as instincts.

```
homunculus/
  identity.json.template    # User identity profile template
  instincts/
    personal/                # 30 learned instincts (auto-extracted)
    inherited/.gitkeep       # Instincts shared from other users
  evolved/
    agents/.gitkeep          # Agents evolved from instinct clusters
    commands/.gitkeep        # Commands evolved from patterns
    skills/.gitkeep          # Skills evolved from patterns
```

**How it works:**
1. The `observe-homunculus.sh` hook captures tool usage observations during sessions
2. The `skill-extractor` agent processes session transcripts and extracts atomic instincts
3. Instincts start at 0.4 confidence and increase with repeated evidence
4. When 3+ instincts cluster in a domain, they can be graduated into learned skills

Currently contains 30 instincts in `instincts/personal/`, covering patterns from MCP configuration to OpenClaw agent management.

## Templates

The `templates/` directory contains starter configuration files. Copy them and fill in your values:

| Template | Target Location | Purpose |
|----------|----------------|---------|
| `claude.json.template` | `~/.claude.json` | MCP server configuration |
| `settings.json.template` | `~/.claude/settings.json` | Claude Code settings (model, plugins, permissions) |
| `env.sh.template` | `~/.claude/scripts/env.sh` | Shared environment variables for scripts |
| `gitignore.template` | `~/.claude/.gitignore` | Git ignore rules for backing up your config |

## Cross-Platform Support

This configuration supports both **macOS** and **Windows**:

- **macOS**: Hooks use `.sh` scripts, tools available via Homebrew, no PATH manipulation needed. See `rules/operations/macos-platform.md`.
- **Windows**: Hooks use `.ps1` scripts with `[Console]::In.ReadToEnd()` for stdin, `cmd /c npx` for MCP servers, OneDrive lock workarounds. See `rules/operations/windows-platform.md`.

## Directory Structure

```
claude-code-config/
  rules/                         # 12 global rule files (4 subdirectories)
  agents/                        # 13 custom agent definitions
  skills/                        # 5 invocable skills + 23 learned skills
  commands/                      # 2 legacy commands (backward compat)
  scripts/                       # 9 automation scripts
  hooks/                         # 6 lifecycle hooks + settings template
  mcp-servers/                   # MCP server docs + custom project-tools server
  templates/                     # Configuration file templates
  homunculus/                    # Continuous learning system (30 instincts)
  COMPLETE-GUIDE.md              # Comprehensive beginner walkthrough
```

## Credits

- **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** by [Affaan Mustafa](https://github.com/affaan-m): The foundation for the agent orchestration framework and plugin agents. 13 specialized agents, 30+ slash commands, and a plugin system. MIT licensed.
- **[Claude Code](https://docs.claude.com/en/docs/claude-code)** by [Anthropic](https://www.anthropic.com/): The CLI tool this configuration extends.
- **[Model Context Protocol](https://github.com/modelcontextprotocol)** community: The MCP server ecosystem.
- Configuration developed and documented by Chris with Claude.
