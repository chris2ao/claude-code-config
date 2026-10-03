# Claude Code Configuration

A production-ready configuration for [Claude Code](https://docs.claude.com/en/docs/claude-code) with 15 rules, 22 agents, 18 invocable skills, 43 learned skills, 2 workflows, 40 scripts, 9 commands, 12 hooks, 7 MCP servers, and 65 instincts. Built through months of daily use across multiple projects on macOS and Windows.

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
```

## Workflows

Saved Workflow scripts (`workflows/*.js`) orchestrate multi-stage agent pipelines deterministically. Each `agent()` call returns schema-validated output, independent stages run concurrently, and runs resume from their run ID. A skill running in the main conversation gathers the inputs, calls the workflow, waits for its completion notification, then handles approval and commits.

| Workflow | Called by | Stages |
|----------|-----------|--------|
| `blog-pipeline` | `/blog-post` | Draft (writer, plus inline images), Assets (cover, diagrams), Review (editor, voice), Revise (max 2 cycles, rechecked), Finalize (drift check, cover patch, frontmatter, validate, content-security, build) |
| `team-pipeline` | `/ui-ux` | Team specs (uiux) are data. Plan, Build (parallel by file ownership), QA (viewports), Integrate (max 3 fix rounds), Review (gate loop) |

These replaced the captain and director agents (blog-captain, game-director, ui-ux-director) in 2026-09. With `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, a named orchestrator spawn becomes a teammate, and its subagents can't hand back their reports. A workflow `agentType` only resolves for agent files that have `name:` frontmatter.

## Component Inventory

### Rules (15 files)

Rules in `rules/` are loaded automatically into every Claude Code session. They shape how Claude writes code, handles security, manages git, and routes work to agents.

| File | Purpose |
|------|---------|
| `agents.md` | Agent orchestration framework (plugin + custom agents) |
| `core/agentic-workflow.md` | Mandatory parallel task decomposition with model routing |
| `core/coding-style.md` | Immutability, file organization, error handling, no em dashes |
| `core/memory-management.md` | Five memory systems with clear boundaries and save triggers |
| `core/security.md` | Pre-commit security checklist, secret management protocol |
| `development/git-workflow.md` | Conventional commits, PR workflow, feature implementation |
| `development/patterns.md` | Repository pattern, API response envelopes, skeleton projects |
| `development/testing.md` | TDD workflow, 80% minimum coverage |
| `operations/hooks.md` | Hook types, file protection, context preservation |
| `operations/performance.md` | Model selection (Haiku/Sonnet/Opus), cost optimization |
| `operations/windows-platform.md` | PowerShell stdin, Git Bash path mangling, OneDrive locks |
| `content/blog-content.md` | Blog writing rules (no private repo links) |
| `operations/context-preservation.md` | Session context preservation across compactions |
| `operations/macos-platform.md` | macOS shell, Homebrew, notifications, file system |

### Agents (22 files)

Agents in `agents/` are specialized agent definitions spawned via Claude Code's Task tool. Each has a focused role and optimal model assignment.

**Core Agents** (6):

| Agent | Model | Purpose |
|-------|-------|---------|
| `evolve-synthesizer` | sonnet | Synthesizes instinct clusters into evolved agent, skill, and command candidates |
| `notebooklm-assistant` | sonnet | Orchestrates NotebookLM workflows: notebooks, sources, content generation, research, downloads |
| `notebooklm-content` | sonnet | Creates branded infographics and slide decks from blog posts using Google NotebookLM |
| `refine-reader` | haiku | /refine evidence reader: extracts relevant transcript excerpts for component editing |
| `sync-orchestrator` | haiku | Bidirectional config sync with security scanning |
| `wrap-up-orchestrator` | haiku | Automated session wrap-up for multi-repo workflows |

**Blog Production Team** (7). No captain agent: the saved workflow `workflows/blog-pipeline.js`, called by `/blog-post`, orchestrates them.

| Agent | Model | Purpose |
|-------|-------|---------|
| `blog-diagram-author` | sonnet | Editorial SVG diagram components for a post, registered in all 3 registries |
| `blog-editor` | sonnet | Senior blog editor: hooks, pacing, accuracy, de-slop, structural checks |
| `blog-finalize` | haiku | Final gate: drift check, cover frontmatter (via script), validate, content-security, build |
| `blog-inline-images` | sonnet | Inline comparison and screenshot images from real assets |
| `blog-voice` | sonnet | Draft voice review (metrics, validate-mdx, content-security) and post-publish profile proposals |
| `blog-writer` | sonnet | Blog post writer: drafts and revises MDX posts for CryptoFlex LLC |
| `brand-graphics` | sonnet | Builds branded blog graphics (cover infographics, inline panels) as HTML rendered with headless Chrome |

**UI/UX Team** (5):

| Agent | Model | Purpose |
|-------|-------|---------|
| `ui-component-architect` | sonnet | UI/UX Component Architect: design tokens, composition patterns, responsive design, semantic HTML, Tailwind |
| `ui-performance-reviewer` | haiku | UI/UX Performance Reviewer: bundle size, Core Web Vitals, React/Next.js patterns, server vs client analysis |
| `ui-ux-lead` | sonnet | Brief, triage, integration, and synthesis stage of the `team-pipeline` workflow (uiux) |
| `ui-ux-reviewer` | sonnet | UI/UX Reviewer + QA: heuristics evaluation, TASTE scoring, anti-pattern detection, Playwright visual testing, final quality gate |
| `ui-visual-designer` | sonnet | UI/UX Visual Designer: aesthetic direction, color systems, typography, layout composition, anti-AI-slop |

**Home Network Team** (4). No captain agent: `/homenet-document` runs `network-architect`, which runs the three specialists.

| Agent | Model | Purpose |
|-------|-------|---------|
| `network-architect` | opus | Runs the /homenet-document pipeline: live UniFi MCP data, the three specialists, diagrams, and a redacted NotebookLM notebook |
| `network-research` | sonnet | Targeted deep-research threads on UniFi configuration best practices, with cited findings |
| `network-security-engineer` | sonnet | Scans a UniFi snapshot for risks and proposes only MCP-executable fixes, ranked by severity and usability impact |
| `network-tech-writer` | sonnet | Writes the HomeNetwork/ markdown documentation from a UniFi MCP snapshot |

### Superpowers Plugin Skills (14 skills + 1 agent)

The [superpowers plugin](https://github.com/anthropics/claude-plugins-official) provides a structured development workflow. Skills activate automatically based on context. Standard flow: brainstorming -> using-git-worktrees -> writing-plans -> subagent-driven-development -> test-driven-development -> requesting-code-review -> finishing-a-development-branch.

| Skill | Trigger | What It Does |
|-------|---------|-------------|
| `using-superpowers` | Auto (session start) | Gateway: explains how to find and invoke all other skills |
| `brainstorming` | Before creative work | Socratic design refinement, saves spec to `docs/superpowers/specs/` |
| `writing-plans` | After brainstorming | Breaks designs into 2-5 min tasks with file paths, code, and verification |
| `executing-plans` | Offline plan execution | Loads plan, executes tasks with verification checkpoints |
| `subagent-driven-development` | In-session plan execution | One subagent per task with two-stage review |
| `test-driven-development` | Before production code | RED-GREEN-REFACTOR cycle |
| `systematic-debugging` | Bug encountered | 4-phase root cause: investigate, analyze, hypothesize, implement |
| `verification-before-completion` | Before claiming done | Evidence-before-claims verification |
| `using-git-worktrees` | After design approval | Isolated workspace with .gitignore verification |
| `finishing-a-development-branch` | After implementation | Merge/PR/keep/discard options, worktree cleanup |
| `requesting-code-review` | After completing tasks | Dispatches code-reviewer agent |
| `receiving-code-review` | Receiving feedback | Technical evaluation before implementing changes |
| `dispatching-parallel-agents` | 2+ independent problems | Concurrent subagents for independent tasks |
| `writing-skills` | Creating new skills | TDD methodology for skill authoring |

Agent: `code-reviewer` reviews completed work against plans for quality, architecture, and docs.

### Skills (18 invocable + 43 learned)

**Invocable skills** (in `skills/*/SKILL.md`) are slash commands for complex workflows:

| Skill | What It Does |
|-------|-------------|
| `/blog-post` | Multi-agent blog post production pipeline with research and MDX generation |
| `/brand-graphics` | Cover infographics and inline branded graphics for cryptoflexllc.com blog posts |
| `/deep-research` | Multi-source deep research using Exa, Firecrawl, and WebSearch with citations |
| `/homenet-allow-mac` | Add a MAC address to a UniFi SSID's allowlist (preview by default, --apply to commit) |
| `/homenet-deny-mac` | Remove a MAC address from a UniFi SSID's allowlist (preview by default, --apply to commit) |
| `/homenet-device-profile` | Device-first LAN behavior profile combining UniFi client state and Pi-hole DNS data (read-only) |
| `/homenet-document` | Generate or refresh comprehensive UniFi network documentation with NotebookLM publication |
| `/homenet-filter` | Toggle mac_filter_enabled on a UniFi SSID (auto-snapshots before change, refuses empty-allowlist enables) |
| `/homenet-ppsk-add` | Add a Private Pre-Shared Key (PPSK) entry to a PPSK-enabled SSID (preview by default, --apply to commit) |
| `/homenet-ppsk-remove` | Remove a PPSK entry from an SSID (preview by default, --apply to commit, refuses to brick SSID) |
| `/homenet-review` | Reconcile each SSID's MAC allowlist against actually-seen clients (active + historical) |
| `/homenet-snapshot` | Snapshot all UniFi wlanconf (SSID) state to HomeNetwork/backups for rollback |
| `/memory-architecture` | Vector memory architecture, capture cadence, hooks, and retention for Claude sessions |
| `/notebooklm-content` | Create branded infographics and slide decks from blog posts using Google NotebookLM |
| `/openclaw-ops` | Configuration gotchas and operational patterns for OpenClaw multi-agent systems |
| `/storage-cleanup` | Scan Mac storage, identify cleanup opportunities, and move safe files to external drive |
| `/sync` | Configuration sync across repos, mirrors local state to git backups |
| `/ui-ux` | UI/UX design and quality system: aesthetic direction, component architecture, performance, and visual QA with a coordinated agent team |
| `/wrap-up` | End-of-session wrap-up: update docs, persist to memory systems, commit and push all repos |

**Learned skills** (in `skills/learned/`) are debugging patterns extracted from real sessions. Each documents a non-obvious problem and its solution. 43 unique skills organized into 6 categories:

| Category | Count | Examples |
|----------|-------|---------|
| Claude Code | 8 | MCP config location, HEREDOC permission pollution, context compaction |
| Security | 4 | SSRF prevention, path traversal guards, cookie auth |
| Next.js | 4 | Client component metadata, MDX sort order, Vercel WAF syntax |
| Platform | 3 | PowerShell stdin hooks, Git Bash path mangling |
| Workflow | 2 | Blog post pipeline, parallel agent decomposition |
| API / Testing | 2 | Anthropic model ID format, Vitest class mock constructor |

See `skills/learned/INDEX.md` for the full list with descriptions.

### Scripts (31 files)

Automation scripts in `scripts/` for common operations:

| Script | Purpose |
|--------|---------|
| `wrap-up-survey.sh` | Multi-repo wrap-up data collection |
| `sync-survey.sh` | Config sync status survey |
| `sync-status.sh` | Quick sync status check across repos |
| `config-diff.sh` | Compare local config against git repo |
| `context-health.sh` | Context window health check |
| `blog-inventory.sh` | Blog post inventory and metadata |
| `blog-voice-diff.sh` | Compare blog post voice against style guide |
| `cleanup-session.sh` | Clean up session artifacts |
| `git-stats.sh` | Git statistics across repos |
| `validate-mdx.sh` | Validate MDX blog post files |
| `env.sh` | Shared environment variables for repo paths and tool paths |
| `memory-maintenance.py` | Memory database maintenance and cleanup |
| `promote-evolved.sh` | Promote evolved agents, skills, and commands to live config |
| `exa-wrapper.sh` | Wrapper to launch the Exa MCP server with secrets loaded from environment |
| `firecrawl-wrapper.sh` | Wrapper to launch the Firecrawl MCP server with secrets loaded from environment |
| `memory-toggle.ps1` | Toggle vector memory MCP server on and off (Windows) |
| `obsidian-wrapper.sh` | Wrapper to launch the Obsidian MCP server with secrets loaded from environment (macOS) |
| `pihole-wrapper.sh` | Wrapper to launch the Pi-hole MCP server with secrets loaded from environment |
| `refine-snapshot.sh` | Preserve pre-edit copies of components before /refine applies changes |
| `unifi-wrapper.sh` | Wrapper to launch the UniFi MCP server with secrets loaded from environment (macOS) |
| `gmail-metrics-export.sh` | Export Gmail assistant run metrics and session archive to the cryptoflexllc /analytics dashboard |
| `memory-health-canary.sh` | Weekly vector memory health check: Ollama embeddings, SSE server, consolidation freshness |
| `memory-p0-cutover.sh` | Memory P0 reliability cutover: Ollama 768d embedding migration and verification |
| `memory-p2-apply.sh` | Memory P2 capability upgrades: consolidation schedule, quality scoring, entity links |

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

## Hooks (11 lifecycle hooks)

Hooks in `hooks/` are shell scripts that fire automatically at different points in the Claude Code lifecycle. Configure them in your project's `.claude/settings.local.json` using the template at `hooks/settings.local.json.template`.

| Hook | Event | Purpose |
|------|-------|---------|
| `file-guard.sh` | PreToolUse | Block Edit/Write on sensitive files (.env, .pem, credentials) |
| `log-activity.sh` | PostToolUse | Log every tool execution to ~/.claude/logs/activity/ (override with CLAUDE_ACTIVITY_LOG_DIR) |
| `memory-checkpoint.sh` | Stop | Structured end-of-session memory checklist across 5 categories |
| `memory-nudge.sh` | PostToolUse | Remind Claude to save context to vector memory after significant work |
| `observe-homunculus.sh` | PostToolUse | Capture behavioral observations as valid JSON with jq for the Homunculus learning system |
| `session-scratchpad.sh` | PostToolUse | Write session state to scratchpad for context recovery |
| `pre-compact.sh` | PreCompact | Preserve session context before compaction |
| `prompt-notify.sh` | Stop | Play notification sound when Claude finishes a response |
| `save-session.sh` | SessionEnd | Archive full conversation transcript on session close |
| `dispatch.sh` | Multiple | Central dispatcher that routes hook events to other hooks |

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
    personal/                # 64 learned instincts (auto-extracted)
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

Currently contains 65 instincts in `instincts/personal/`, covering patterns from MCP configuration to OpenClaw agent management.

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
  rules/                         # 15 global rule files (4 subdirectories)
  agents/                        # 22 custom agent definitions
  skills/                        # 18 invocable skills + 43 learned skills
  commands/                      # 9 commands
  scripts/                       # 31 automation scripts
  hooks/                         # 19 hook scripts (12 macOS/Linux + 7 Windows)
  mcp-servers/                   # MCP server docs + custom project-tools server
  templates/                     # Configuration file templates
  homunculus/                    # Continuous learning system (65 instincts)
  COMPLETE-GUIDE.md              # Comprehensive beginner walkthrough
```

## Credits

- **[everything-claude-code](https://github.com/affaan-m/everything-claude-code)** by [Affaan Mustafa](https://github.com/affaan-m): The foundation for the agent orchestration framework and plugin agents. 13 specialized agents, 30+ slash commands, and a plugin system. MIT licensed.
- **[Claude Code](https://docs.claude.com/en/docs/claude-code)** by [Anthropic](https://www.anthropic.com/): The CLI tool this configuration extends.
- **[Model Context Protocol](https://github.com/modelcontextprotocol)** community: The MCP server ecosystem.
- Configuration developed and documented by Chris with Claude.
