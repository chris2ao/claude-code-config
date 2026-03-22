# Component Reference

This document catalogs every file in the CJClaudin_Mac repository with its purpose, format, and usage notes.

## Root Level

### `install.sh`
**Purpose**: macOS installer for CJClaudin_Mac configuration
**Format**: Bash script
**Used by**: User (manual invocation)
**Notes**: Checks dependencies, backs up existing `~/.claude/`, copies payload files, sets permissions, writes templates, installs project-tools MCP server

### `uninstall.sh`
**Purpose**: Removes CJClaudin_Mac configuration and restores backups
**Format**: Bash script
**Used by**: User (manual invocation)
**Notes**: Removes `~/.claude/` contents installed by CJClaudin_Mac, optionally restores from most recent backup

### `check-deps.sh`
**Purpose**: Validates required dependencies (git, jq, node, npm)
**Format**: Bash script
**Used by**: `install.sh` (automatic)
**Notes**: Exits with non-zero code if dependencies are missing

## payload/agents/

Agents are spawned via the Task tool with `subagent_type="agent-name"`. All agent files follow the same format.

**Format**: Markdown with YAML frontmatter
```yaml
---
description: "What the agent does"
model: haiku|sonnet|opus
tools: [Read, Write, Bash, Grep, Glob]
---
```

### `blog-post-orchestrator.md`
**Purpose**: Coordinates multi-phase blog post generation
**Model**: haiku
**Tools**: Read, Grep, Glob, Task
**Used by**: `/blog-post` command
**Notes**: Does NOT write posts itself; spawns specialized agents for research, writing, validation

### `changelog-writer.md`
**Purpose**: Auto-generates CHANGELOG.md entries from git diffs
**Model**: haiku
**Tools**: Read, Grep, Glob, Bash
**Used by**: User (manual Task invocation)
**Notes**: Calls `git-stats.sh` for pre-computed metrics

### `config-sync.md`
**Purpose**: Syncs `~/.claude/` changes to the CJClaudin_Mac git repo
**Model**: haiku
**Tools**: Bash, Read, Write
**Used by**: User (manual Task invocation)
**Notes**: Detects changes in `~/.claude/` and stages them in the repo for commit

### `context-health.md`
**Purpose**: Monitors context window usage and recommends actions
**Model**: haiku
**Tools**: Bash (runs `context-health.sh`)
**Used by**: User (manual Task invocation) or automatic triggers
**Notes**: Warns when entering last 20% of context window

### `deploy-verifier.md`
**Purpose**: Post-deployment verification across services
**Model**: haiku
**Tools**: Bash, WebFetch
**Used by**: CI/CD pipelines, manual Task invocation
**Notes**: Verifies health endpoints, DNS propagation, certificate validity

### `home-sync.md`
**Purpose**: Syncs installed `~/.claude/` components back to CJClaudin_Mac repo
**Model**: haiku
**Tools**: Bash, Read, Write
**Used by**: User (manual Task invocation)
**Notes**: Copies from `~/.claude/` to `~/GitProjects/CJClaudin_Mac/payload/`

### `multi-repo-orchestrator.md`
**Purpose**: Parallel operations across multiple repositories
**Model**: haiku
**Tools**: Task, Bash, Read
**Used by**: User (manual Task invocation)
**Notes**: Spawns one agent per repository (5 repos), collects results in parallel

### `pre-commit-checker.md`
**Purpose**: Validates code before committing (security, tests, linting)
**Model**: inherit
**Tools**: Bash, Read, Grep
**Used by**: Manual Task invocation before commits
**Notes**: Checks for hardcoded secrets, runs tests, validates formatting

### `session-analyzer.md`
**Purpose**: Extracts patterns from session transcripts
**Model**: sonnet
**Tools**: Read, Grep, Glob
**Used by**: User (manual Task invocation)
**Notes**: Reads `~/.claude/transcripts/*.jsonl`, identifies trends, generates summaries

### `session-checkpoint.md`
**Purpose**: Saves session state before risky operations
**Model**: haiku
**Tools**: Bash, Write
**Used by**: Manual Task invocation before large refactors
**Notes**: Creates timestamped snapshot in `~/.claude/checkpoints/`

### `skill-extractor.md`
**Purpose**: Mines session transcripts for reusable patterns (Homunculus v2)
**Model**: sonnet
**Tools**: Read, Grep, Glob, Write
**Used by**: `/evolve` command (via wrap-up orchestrator)
**Notes**: Writes instincts to `~/.claude/homunculus/instincts/personal/`, assigns confidence scores

### `sync-orchestrator.md`
**Purpose**: Coordinates sync operations between `~/.claude/` and CJClaudin_Mac repo
**Model**: haiku
**Tools**: Task, Bash, Read
**Used by**: User (manual Task invocation)
**Notes**: Maps installed components to repo payload directories

### `wrap-up-orchestrator.md`
**Purpose**: Coordinates `/wrap-up` across multiple repositories in parallel
**Model**: haiku
**Tools**: Task, AskUserQuestion
**Used by**: `/wrap-up` command when 4+ repos detected
**Notes**: Surveys user, spawns parallel agents (up to 5 repos), reports summary

## payload/commands/

Commands are invoked via `/command-name`. They expand into prompts.

**Format**: Markdown with optional YAML frontmatter
```yaml
---
name: command-name
description: "What the command does"
hooks:
  - type: PreToolUse
    run: "./pre-command.sh"
---
```

### `blog-post.md`
**Purpose**: Starts the blog post generation pipeline
**Used by**: User (manual `/blog-post` invocation)
**Notes**: Triggers `blog-post-orchestrator` agent

## payload/homunculus/

The Homunculus continuous learning system.

### `identity.json.template`
**Purpose**: Template for tracking learning system identity
**Format**: JSON
```json
{
  "version": "2.0",
  "created": "YYYY-MM-DD",
  "sessions": 0,
  "instincts_learned": 0,
  "skills_evolved": 0
}
```
**Used by**: `install.sh` (writes to `~/.claude/homunculus/identity.json`)
**Notes**: Updated by skill-extractor agent and evolve command

### `evolved/agents/.gitkeep`
**Purpose**: Placeholder for evolved agents
**Notes**: Instincts that graduate to agents are written here

### `evolved/commands/.gitkeep`
**Purpose**: Placeholder for evolved commands
**Notes**: Instincts that graduate to commands are written here

### `evolved/skills/.gitkeep`
**Purpose**: Placeholder for evolved skills
**Notes**: Instincts that graduate to skills are written here

### `instincts/inherited/.gitkeep`
**Purpose**: Placeholder for shared instincts from other users
**Notes**: Future use (instinct sharing between Homunculus instances)

### `instincts/personal/catch-on-new-sql-queries.md`
**Purpose**: Instinct to validate new SQL queries for SQL injection
**Format**: Markdown with YAML frontmatter
```yaml
---
id: catch-on-new-sql-queries
trigger: "when adding new SQL queries"
confidence: 0.7
domain: "security"
source: "session-observation"
created: "YYYY-MM-DD"
---
```
**Used by**: Loaded into session, referenced during code review

### `instincts/personal/deep-link-admin-to-public.md`
**Purpose**: Instinct to link admin features to public-facing pages
**Format**: Same as above
**Domain**: frontend

### `instincts/personal/mirror-existing-component-patterns.md`
**Purpose**: Instinct to follow established component patterns in codebase
**Format**: Same as above
**Domain**: frontend

## payload/rules/

Rules are loaded automatically into every Claude Code session.

**Format**: Markdown (no frontmatter required)

### `agents.md`
**Purpose**: Defines agent orchestration strategy and routing table
**Used by**: System (loaded into every session)
**Notes**: Duplicates exist in `~/.claude/rules/` (global) and project root (per-project override)

### `core/agentic-workflow.md`
**Purpose**: Defines mandatory parallel decomposition and agent triggers
**Used by**: System (loaded into every session)
**Notes**: Enforces parallel Task execution for 2+ independent steps

### `core/coding-style.md`
**Purpose**: Coding standards (immutability, file organization, error handling)
**Used by**: System (loaded into every session)
**Notes**: Includes writing style rule (no em dashes)

### `core/security.md`
**Purpose**: Security guidelines (secret management, input validation, OWASP checks)
**Used by**: System (loaded into every session)
**Notes**: Referenced by `pre-commit-checker` agent

### `development/git-workflow.md`
**Purpose**: Git commit message format and PR workflow
**Used by**: System (loaded into every session)
**Notes**: Enforces Conventional Commits format

### `development/patterns.md`
**Purpose**: Common design patterns (Repository, API response format)
**Used by**: System (loaded into every session)
**Notes**: Encourages skeleton project approach

### `development/testing.md`
**Purpose**: Testing requirements (80% coverage, TDD workflow)
**Used by**: System (loaded into every session)
**Notes**: Enforces RED-GREEN-REFACTOR cycle

### `operations/hooks.md`
**Purpose**: Hook system documentation (types, file protection, auto-accept)
**Used by**: System (loaded into every session)
**Notes**: Explains PreToolUse, PostToolUse, Stop, SessionEnd hooks

### `operations/performance.md`
**Purpose**: Model selection strategy and cost optimization
**Used by**: System (loaded into every session)
**Notes**: Defines Haiku/Sonnet/Opus routing rules

### `operations/macos-platform.md`
**Purpose**: macOS-specific rules (Homebrew, zsh, osascript notifications)
**Used by**: System (loaded into every session)
**Notes**: Covers Apple Silicon paths (`/opt/homebrew/bin/`), MCP servers use `npx` directly, hooks use `chmod +x`

## payload/scripts/

Standalone executables called by agents, skills, and hooks.

**Format**: Bash scripts (`.sh`)

### `blog-inventory.sh`
**Purpose**: Lists all blog posts with metadata (title, date, tags)
**Used by**: `blog-post-orchestrator` agent
**Output**: JSON array of blog post metadata
**Notes**: Searches `~/GitProjects/cryptoflexllc/src/content/blog/` for MDX files

### `cleanup-session.sh`
**Purpose**: Removes temporary files, logs, and cached data
**Used by**: `/wrap-up` skill, SessionEnd hooks
**Notes**: Runs `rm -rf .next` (Next.js cache), prunes old transcripts

### `config-diff.sh`
**Purpose**: Shows differences between `~/.claude/` and CJClaudin_Mac repo
**Used by**: `config-sync` agent
**Output**: Git-style diff of changed files
**Notes**: Helps identify what needs syncing

### `context-health.sh`
**Purpose**: Counts transcripts, sizes, estimates tokens
**Used by**: `context-health` agent
**Output**: JSON with `transcript_count`, `total_size_bytes`, `estimated_tokens`, `warning_level`
**Notes**: Warning levels: safe, caution, critical

### `git-stats.sh`
**Purpose**: Computes git statistics (commits, file changes, authors)
**Used by**: `changelog-writer` agent
**Output**: JSON with commit counts and change summaries
**Notes**: Looks at last 7 days by default

### `sync-survey.sh`
**Purpose**: Interactive dialog for config sync operations
**Used by**: `sync-orchestrator` agent
**Output**: JSON with sync directions and selections

### `validate-mdx.sh`
**Purpose**: Validates MDX blog posts (frontmatter, syntax, image paths)
**Used by**: `blog-post-orchestrator` agent (validation phase)
**Exit code**: 0 on success, non-zero on validation errors
**Notes**: Requires Node.js and MDX parser

### `wrap-up-survey.sh`
**Purpose**: Interactive dialog for `/wrap-up` configuration
**Used by**: `/wrap-up` skill
**Output**: JSON with user selections (repos to wrap up, commit message style, etc.)
**Notes**: Uses `dialog` or `whiptail` for TUI

## payload/skills/

Skills are multi-file programs in subdirectories.

**Format**: Directory with `SKILL.md` and optional supporting files

### `blog-post/SKILL.md`
**Purpose**: Multi-phase blog post generation pipeline
**Phases**: Topic selection, research, writing, validation, publishing
**Used by**: User (manual `/blog-post` invocation)
**Notes**: Spawns `blog-post-orchestrator` agent

### `multi-repo-status/SKILL.md`
**Purpose**: Shows git status across all tracked repositories
**Used by**: User (manual `/multi-repo-status` invocation)
**Notes**: Reads `~/.claude/repos.json` for repo list

### `skill-catalog/SKILL.md`
**Purpose**: Lists all installed skills with descriptions
**Used by**: User (manual `/skill-catalog` invocation)
**Output**: Formatted list of skills in `~/.claude/skills/`

### `wrap-up/SKILL.md`
**Purpose**: 5-phase session cleanup (commit, push, archive, evolve, notify)
**Phases**:
1. Commit changes
2. Push to remote
3. Archive session transcript
4. Evolve instincts (skill-extractor agent)
5. Notify completion (system notification via osascript)
**Used by**: User (manual `/wrap-up` invocation)
**Notes**: If 4+ repos detected, delegates to `wrap-up-orchestrator` agent

## payload/skills/learned/

Graduated skills extracted from instincts. Organized by domain.

**Format**: Markdown with YAML frontmatter
```yaml
---
id: skill-name
trigger: "when [situation]"
confidence: 0.7-0.9
domain: "platform|security|claude-code|..."
source: "instinct-evolution"
created: "YYYY-MM-DD"
graduated: "YYYY-MM-DD"
---
```

### Claude Code Domain (`learned/claude-code/`)

#### `claude-code-debug-diagnostics.md`
**Purpose**: How to diagnose Claude Code hangs and freezes
**Trigger**: When Claude Code becomes unresponsive
**Pattern**: Check `~/.claude/logs/`, kill zombie processes, restart with `--verbose`

#### `command-yaml-frontmatter.md`
**Purpose**: Commands need YAML frontmatter to trigger hooks
**Trigger**: When hooks don't fire for a command
**Pattern**: Add frontmatter with `name:` and `hooks:` fields

#### `context-compaction-pre-flight.md`
**Purpose**: Preserve critical context before compaction
**Trigger**: When context window reaches 80%
**Pattern**: Write active tasks, decisions, file paths to MEMORY.md

#### `heredoc-permission-pollution.md`
**Purpose**: Avoid permission pollution from HEREDOC parentheses
**Trigger**: When auto-approved permissions include unexpected tools
**Pattern**: Use `$(cat <<'EOF'...)` format, avoid parentheses in commit body

#### `interactive-mode-freeze-recovery.md`
**Purpose**: Recover from interactive mode freezes
**Trigger**: When Claude Code prompts for input and freezes
**Pattern**: Ctrl+C, restart session, use `--no-interactive` flag

#### `mcp-config-location.md`
**Purpose**: MCP servers must be in `~/.claude.json`, not `~/.claude/mcp-servers.json`
**Trigger**: When MCP servers don't connect
**Pattern**: Move config to `~/.claude.json` under `mcpServers` key

#### `settings-validation-debugging.md`
**Purpose**: Validate `.claude/settings.local.json` syntax
**Trigger**: When project hooks don't load
**Pattern**: Run `python3 -m json.tool settings.local.json` to validate JSON

#### `shallow-fetch-force-push.md`
**Purpose**: Avoid force-push after shallow fetch (loses history)
**Trigger**: When force-pushing to a repo cloned with `--depth=1`
**Pattern**: Never use `--depth=1` on repos you'll push to

### Platform Domain (`learned/platform/`)

#### `git-bash-npm-path-mangling.md`
**Purpose**: Git Bash rewrites Windows paths, breaks npm (historical reference)
**Trigger**: When `npm` or `npx` commands fail with path errors on Windows
**Pattern**: Use `cmd /c npm` or invoke via PowerShell

#### `git-bash-powershell-variable-stripping.md`
**Purpose**: Git Bash strips `$` from inline PowerShell commands (historical reference)
**Trigger**: When PowerShell variables are missing in inline commands
**Pattern**: Write `.ps1` file, invoke via `powershell -Command ". 'script.ps1'"`

#### `powershell-stdin-hooks.md`
**Purpose**: PowerShell hooks must use `[Console]::In.ReadToEnd()` not `$input` (historical reference)
**Trigger**: When PowerShell hooks receive empty stdin
**Pattern**: Replace `$input` with `[Console]::In.ReadToEnd() | ConvertFrom-Json`

### Security Domain (`learned/security/`)

#### `cookie-auth-over-query-strings.md`
**Purpose**: Use cookies for auth tokens, not query strings (prevent leaks in logs)
**Trigger**: When implementing authentication
**Pattern**: Set HttpOnly cookies, never pass tokens in URLs

#### `slug-path-traversal-guard.md`
**Purpose**: Validate slugs to prevent path traversal attacks
**Trigger**: When accepting user-provided slugs
**Pattern**: Reject slugs containing `..`, `/`, or `\`

#### `ssrf-prevention-ip-validation.md`
**Purpose**: Block SSRF attacks by validating IP addresses
**Trigger**: When fetching user-provided URLs
**Pattern**: Reject private IPs (10.x, 192.168.x, 127.x, 169.254.x)

#### `token-secret-safety.md`
**Purpose**: Never log or display full tokens/secrets
**Trigger**: When handling API keys or tokens
**Pattern**: Log `token.substring(0,8) + '...'`, never full value

### Next.js Domain (`learned/nextjs/`)

#### `mdx-blog-design-system.md`
**Purpose**: Use established MDX component patterns for blog posts
**Trigger**: When adding new MDX components
**Pattern**: Follow existing `<InfoBox>`, `<CodeBlock>`, `<Image>` patterns

#### `mdx-same-date-sort-order.md`
**Purpose**: Use lexicographic slug sorting when blog posts have same date
**Trigger**: When multiple posts published on same date
**Pattern**: Sort by `date DESC, slug ASC`

#### `nextjs-client-component-metadata.md`
**Purpose**: Metadata export only works in Server Components
**Trigger**: When `export const metadata` causes errors
**Pattern**: Move metadata to parent layout or use `generateMetadata()` function

#### `vercel-json-waf-syntax.md`
**Purpose**: Vercel WAF rules use different regex syntax than Apache
**Trigger**: When migrating `.htaccess` rules to `vercel.json`
**Pattern**: Use Vercel's path matcher syntax, not regex

### Other Skills

#### `anthropic-model-id-format.md`
**Purpose**: Correct format for Anthropic model IDs
**Domain**: claude-code
**Pattern**: `claude-opus-4-6`, `claude-sonnet-4-5-YYYYMMDD`

#### `blog-post-production-pipeline.md`
**Purpose**: End-to-end blog post publishing workflow
**Domain**: frontend
**Pattern**: Research, write, validate MDX, commit, push, deploy

#### `parallel-agent-decomposition.md`
**Purpose**: Decompose tasks into parallel agents
**Domain**: claude-code
**Pattern**: Identify independent steps, spawn Task agents in single message

#### `vitest-class-mock-constructor.md`
**Purpose**: Mock class constructors in Vitest
**Domain**: testing
**Pattern**: Use `vi.fn().mockImplementation()` not `vi.fn()`

### Supporting Files

#### `INDEX.md`
**Purpose**: Categorized index of all learned skills
**Notes**: Auto-generated by skill-extractor agent

#### `blog-mdx-reference.md`
**Purpose**: MDX syntax and component reference for blog posts
**Used by**: blog-post-orchestrator agent

#### `blog-style-guide.md`
**Purpose**: Writing style guidelines for cryptoflexllc.com blog
**Used by**: blog-post-orchestrator agent

## hooks/

Hook implementations for macOS (Bash).

### `settings.local.json.template`
**Purpose**: Template for per-project hook configuration
**Format**: JSON
```json
{
  "hooks": {
    "PreToolUse": "hooks/file-guard.sh",
    "PostToolUse": "hooks/observe-homunculus.sh",
    "Stop": "hooks/prompt-notify.sh",
    "SessionEnd": "hooks/save-session.sh"
  }
}
```
**Used by**: `install.sh` (user chooses to install per-project hooks)
**Notes**: Copied to project `.claude/settings.local.json`

### Unix Hooks (`hooks/unix/`)

All hooks are Bash scripts that receive JSON via stdin.

#### `file-guard.sh`
**Purpose**: PreToolUse hook that blocks Edit/Write on sensitive files
**Protected files**: `.env`, `*.key`, `*.pem`, `credentials.json`
**Exit code**: Non-zero to block operation

#### `log-activity.sh`
**Purpose**: PostToolUse hook that logs all tool usage
**Output**: Appends to `~/.claude/activity.log`
**Format**: `YYYY-MM-DD HH:MM:SS | ToolName | parameters`

#### `observe-homunculus.sh`
**Purpose**: PostToolUse hook for Homunculus learning system
**Output**: Writes to `~/.claude/homunculus/observations/YYYYMMDD-HHMMSS.jsonl`
**Format**: One JSON object per line (JSONL)

#### `prompt-notify.sh`
**Purpose**: Stop hook that sends system notification
**Notification**: "Claude Code session ended"
**Platform**: Uses `osascript` (macOS native)

#### `save-session.sh`
**Purpose**: SessionEnd hook that archives transcript
**Output**: Copies session transcript to `~/.claude/transcripts/`
**Format**: `YYYYMMDD-HHMMSS-[project-name].jsonl`

## mcp-servers/

Custom MCP servers bundled with this repo.

### `project-tools/package.json`
**Purpose**: Node.js package manifest for the project-tools MCP server
**Dependencies**: `@modelcontextprotocol/sdk` ^1.0.0
**Type**: ES Module

### `project-tools/index.js`
**Purpose**: Custom MCP server providing 5 tools for project management
**Format**: ES Module using `@modelcontextprotocol/sdk`
**Tools**:

| Tool | Description | Cache TTL |
|------|-------------|-----------|
| `repo_status` | Git status across all project repos | 30s |
| `blog_posts` | Blog post inventory with frontmatter metadata | Infinity (file watcher) |
| `style_guide` | Cached blog style guide and MDX reference | 5 min |
| `validate_blog_post` | Validate MDX post against style rules | None |
| `session_artifacts` | Count transcripts, todos, activity logs | 60s |

**Repos tracked**: CJClaude_1, cryptoflexllc, cryptoflex-ops, claude-code-config, CJClaudin_Mac
**Environment variables**:
- `PROJECT_ROOT`: Base directory for repos (default: `/Users/chris2ao/GitProjects`)
- `CLAUDE_CONFIG`: Claude config directory (default: `$HOME/.claude`)

## templates/

Templates for configuration files written during installation.

### `claude.json.template`
**Purpose**: Template for `~/.claude.json` (MCP server configuration)
**Variables**: `{{CJCLAUDIN_MAC_PATH}}`, `{{PROJECTS_DIR}}`, `{{CLAUDE_HOME}}`
**Notes**: Configures 5 MCP servers: memory, context7, sequential-thinking, github, project-tools

### `env.sh.template`
**Purpose**: Template for environment variable configuration
**Variables**: `YOUR_PROJECTS_DIR`
**Notes**: Homebrew tools are automatically on PATH; no manual PATH augmentation needed

### `settings.json.template`
**Purpose**: Template for `~/.claude/settings.json`
**Variables**: `{{GITHUB_USERNAME}}`, `{{PREFERRED_MODEL}}`

### `gitignore.template`
**Purpose**: `.gitignore` for `~/.claude/` directory
**Notes**: Ignores transcripts, logs, observations, and other generated files

## docs/

Documentation files (this directory).

### `ARCHITECTURE.md`
**Purpose**: System architecture and component interaction
**Audience**: Developers, advanced users

### `COMPONENT-REFERENCE.md` (this file)
**Purpose**: Complete catalog of all files in the repo
**Audience**: Developers, maintainers

### `TROUBLESHOOTING.md`
**Purpose**: Common issues and solutions for macOS
**Audience**: Users, support
