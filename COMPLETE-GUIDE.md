# The Complete Guide to Configuring Claude Code Like a Pro

A line-by-line walkthrough of a real-world Claude Code configuration. Whether you've never touched a command line before or you're an experienced developer looking to level up your AI-assisted workflow, this guide explains every file, every setting, and every decision.

---

## Table of Contents

1. [What Is Claude Code?](#what-is-claude-code)
2. [The Big Picture: How Configuration Works](#the-big-picture-how-configuration-works)
3. [User-Level Configuration (Applies to ALL Projects)](#user-level-configuration)
   - [Settings: `~/.claude/settings.json`](#settings-file)
   - [MCP Servers: `~/.claude.json`](#mcp-servers)
   - [Rules: `~/.claude/rules/**/*.md`](#rules)
   - [Custom Agents: `~/.claude/agents/`](#custom-agents)
   - [Learned Skills: `~/.claude/skills/learned/`](#learned-skills)
   - [Custom Skills: `~/.claude/skills/*/SKILL.md`](#custom-skills)
   - [Custom Commands: `~/.claude/commands/`](#custom-commands)
   - [Backup: `~/.claude/.gitignore`](#backup-strategy)
4. [Project-Level Configuration (One Project Only)](#project-level-configuration)
   - [Project Instructions: `CLAUDE.md`](#project-instructions-claudemd)
   - [Project Settings: `.claude/settings.local.json`](#project-settings)
   - [Hooks: `.claude/hooks/*.ps1`](#hooks)
5. [How to Set This Up From Scratch](#how-to-set-this-up-from-scratch)
6. [Key Concepts Explained](#key-concepts-explained)
7. [Troubleshooting](#troubleshooting)

---

## What Is Claude Code?

Claude Code is a command-line tool (CLI) made by Anthropic that lets you have conversations with Claude AI directly in your terminal. Unlike the web chat at claude.ai, Claude Code can:

- **Read and edit files** on your computer
- **Run terminal commands** (like building software or running tests)
- **Search your codebase** to understand existing code
- **Create commits and pull requests** on GitHub
- **Use external tools** through plugins and MCP servers

Think of it as having an AI assistant sitting inside your terminal who can not only talk to you, but also directly interact with your files and tools.

**How to install it:**
```bash
npm install -g @anthropic-ai/claude-code
```

**How to start it:**
```bash
cd your-project-folder
claude
```

That's it. You're now in a conversation with Claude inside your project.

---

## The Big Picture: How Configuration Works

Claude Code reads configuration from **two levels**. Understanding this is the single most important concept in this guide:

```
USER-LEVEL (~/.claude/)              PROJECT-LEVEL (your-project/.claude/)
Applies to ALL your projects         Applies to ONE project only
Lives in your home directory         Lives inside the project folder
Not shared with collaborators        Can be shared via git
```

Here's what lives where:

| File | Level | Purpose |
|------|-------|---------|
| `~/.claude/settings.json` | User | Plugins, update preferences |
| `~/.claude.json` | User | MCP servers (external tools) |
| `~/.claude/rules/*.md` | User | Coding standards Claude follows everywhere |
| `~/.claude/skills/learned/` | User | Patterns Claude has learned from past sessions |
| `your-project/CLAUDE.md` | Project | Instructions specific to this project |
| `your-project/.claude/settings.local.json` | Project | Permissions, hooks, project-specific config |
| `your-project/.claude/hooks/*.ps1` | Project | Automation scripts that run on events |

**Why two levels?** Because some things are personal preferences (your coding style, your GitHub token, your plugins) and should follow you everywhere. Other things are project-specific (this project uses React, this project needs special hooks) and should stay with the project.

When you open a project with Claude Code, it loads **both** levels automatically. You don't need to do anything — it just merges them together.

---

## User-Level Configuration

These files live in your home directory under `~/.claude/` and apply to every project you open with Claude Code.

> **Where is `~`?**
> - **Windows:** `C:\Users\YourName\` (or wherever your user profile is)
> - **Mac:** `/Users/YourName/`
> - **Linux:** `/home/YourName/`

---

### Settings File

**File:** `~/.claude/settings.json`

This is Claude Code's main settings file. Here's the configuration with every line explained:

```json
{
  "autoUpdatesChannel": "latest",
  "extraKnownMarketplaces": {
    "everything-claude-code": {
      "source": { "source": "github", "repo": "affaan-m/everything-claude-code" }
    }
  },
  "enabledPlugins": {
    "everything-claude-code@everything-claude-code": true
  }
}
```

Let's break down each part:

#### `"autoUpdatesChannel": "latest"`

**What it does:** Tells Claude Code which update channel to follow. `"latest"` means you always get the newest stable version automatically.

**Other options:**
- `"stable"` — only get thoroughly tested updates (safer but slower)
- `"none"` — disable auto-updates entirely

**When to change it:** If Claude Code updates break something, switch to `"stable"`. Otherwise, `"latest"` is fine.

#### `"extraKnownMarketplaces"` block

```json
"extraKnownMarketplaces": {
  "everything-claude-code": {
    "source": { "source": "github", "repo": "affaan-m/everything-claude-code" }
  }
}
```

**What it does:** Registers a **plugin marketplace** — a GitHub repository that contains plugins you can install. Think of it like adding a new app store to your phone.

**Line by line:**
- `"everything-claude-code"` — The name we're giving this marketplace (you choose the name)
- `"source": "github"` — The marketplace is hosted on GitHub
- `"repo": "affaan-m/everything-claude-code"` — The GitHub repository URL (github.com/affaan-m/everything-claude-code)

**What is everything-claude-code?** It's the most popular community plugin for Claude Code, created by Affaan Mustafa. It provides:
- **13 specialized agents** (AI assistants focused on specific tasks like code review, security analysis, planning)
- **30+ slash commands** (shortcuts like `/plan`, `/verify`, `/tdd`)
- **30+ skills** (predefined knowledge about coding patterns, frameworks, and best practices)

**How to install it yourself:**
```bash
# Option 1: Edit settings.json directly (as shown above)
# Option 2: Use Claude Code's built-in commands:
/plugin marketplace add affaan-m/everything-claude-code
/plugin install everything-claude-code@everything-claude-code
```

#### `"enabledPlugins"` block

```json
"enabledPlugins": {
  "everything-claude-code@everything-claude-code": true
}
```

**What it does:** Activates a specific plugin from an installed marketplace.

**The format is:** `"pluginName@marketplaceName": true`
- `everything-claude-code` (before the @) — The plugin name
- `everything-claude-code` (after the @) — The marketplace it comes from
- `true` — Plugin is enabled. Set to `false` to disable without uninstalling.

**After enabling:** Restart Claude Code (close and reopen). The plugin's agents, commands, and skills become available immediately.

---

### MCP Servers

**File:** `~/.claude.json` (note: this is in your home directory, NOT inside `~/.claude/`)

MCP stands for **Model Context Protocol**. MCP servers are external programs that give Claude Code new abilities it doesn't have built in. Think of them as superpowers you can bolt on.

> **Important:** There's a common confusion — `~/.claude/mcp-servers.json` is for **Claude Desktop** (the desktop app), NOT Claude Code (the CLI). Claude Code reads MCP config from `~/.claude.json`. If you put your servers in the wrong file, they won't load.

We recommend 2 MCP servers that provide capabilities not already built into Claude Code. Here's a minimal configuration:

```json
{
  "mcpServers": {
    "memory": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {}
    },
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "env": {}
    }
  }
}
```

> **Security note:** The `~/.claude.json` file can contain secrets (like GitHub tokens). Never commit this file to a public repository. This is why our backup `.gitignore` excludes it.

Let's break down each server:

#### Common fields explained

Every MCP server has the same basic structure:

```json
"server-name": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@package/name"],
  "env": {}
}
```

- **`"type": "stdio"`** — How Claude Code communicates with the server. `stdio` means "standard input/output" — they talk through text pipes. This is the most common type.
- **`"command": "npx"`** — The program to run. `npx` is a Node.js tool that downloads and runs packages on the fly. You need [Node.js](https://nodejs.org/) installed for this.
- **`"args": ["-y", "@package/name"]`** — Arguments passed to the command. `-y` means "yes, auto-install without asking." The package name is the actual MCP server software.
- **`"env": {}`** — Environment variables passed to the server. Used for secrets like API tokens.

#### Server 1: Memory

```json
"memory": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-memory"],
  "env": {}
}
```

**What it does:** Gives Claude a persistent memory that survives across sessions. Without this, Claude forgets everything when you close the terminal. With it, Claude can store and recall facts, relationships, and context.

**How Claude uses it:**
- Stores **entities** (things like "this project uses React" or "the user prefers dark mode")
- Creates **relations** between entities ("React" → "is used by" → "Project X")
- Searches and retrieves stored knowledge in future sessions

**Example in conversation:**
```
You: "Remember that our production database is on AWS us-east-1"
Claude: (stores this as an entity in the memory server)

... next week, new session ...

You: "Where is our production database?"
Claude: (searches memory server) "Your production database is on AWS us-east-1"
```

**Tools it adds:**
| Tool | What It Does |
|------|-------------|
| `create_entities` | Store new facts |
| `create_relations` | Link facts together |
| `add_observations` | Add details to existing facts |
| `search_nodes` | Search all stored knowledge |
| `open_nodes` | Retrieve a specific fact by name |
| `delete_entities` | Remove a fact |
| `delete_observations` | Remove a specific detail |
| `delete_relations` | Remove a link between facts |

**How to add it:**
```bash
claude mcp add --scope user memory -- npx -y @modelcontextprotocol/server-memory
```

#### Server 2: Context7

```json
"context7": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@upstash/context7-mcp@latest"],
  "env": {}
}
```

**What it does:** Fetches **live, up-to-date documentation** for any programming library or framework. Claude's training data has a cutoff date — it doesn't know about features released after that date. Context7 solves this by looking up the current docs on demand.

**Example in conversation:**
```
You: "How do I use the new React Server Components API?"
Claude: (calls context7 to fetch the latest React docs)
Claude: "According to the current React documentation..." (gives you accurate, up-to-date info)
```

**Tools it adds:**
| Tool | What It Does |
|------|-------------|
| `resolve-library-id` | Find a library in context7's database |
| `get-library-docs` | Fetch the current documentation for a library |

**How to add it:**
```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest
```

#### Other Servers (Optional)

We initially used 3 additional servers but later dropped them because they duplicate built-in Claude Code features:

| Server | Why We Dropped It |
|--------|------------------|
| **sequential-thinking** | Claude Code's built-in extended thinking (up to 31,999 tokens) provides the same step-by-step reasoning. An external MCP server for this is redundant. |
| **filesystem** | Claude Code's built-in Read, Write, Edit, Glob, and Grep tools already handle file operations. The MCP server adds move/copy but rarely justifies the overhead. |
| **github** | The `gh` CLI via Bash covers most GitHub operations. The MCP server is convenient but not essential. Consider it if you do heavy GitHub API work (code search, bulk operations). |

If you want to add the GitHub server anyway:
```bash
claude mcp add-json --scope user github '{"command":"npx","args":["-y","@modelcontextprotocol/server-github"],"env":{"GITHUB_PERSONAL_ACCESS_TOKEN":"your-token-here"}}'
```

> **Note:** We use `add-json` instead of `add` because the `--env` flag can be finicky with long token values. The JSON format is more reliable.

#### Verifying your MCP servers

After adding servers, restart Claude Code and check they're running:

```bash
# In Claude Code, type:
/mcp

# Or from the terminal:
claude mcp list
```

You should see all servers listed as "connected." If any show "failed," see the [Troubleshooting](#troubleshooting) section.

---

### Rules

**Location:** `~/.claude/rules/` (organized in subdirectories)

Rules are the most powerful part of this configuration. They are **persistent instructions** that Claude follows in every session, in every project. Think of them as your coding standards document, except instead of hoping developers read it, the AI actually follows it.

Each rule is a simple Markdown file. Claude reads all files in `~/.claude/rules/` (including subdirectories) at the start of every session. We organize rules into three subdirectories:

```
rules/
  agents.md              — Agent orchestration
  core/                  — Fundamental coding principles
    agentic-workflow.md   — Parallel task decomposition
    coding-style.md       — Code quality standards
    security.md           — Security checklist
  development/           — Development workflow
    git-workflow.md       — Commits, PRs, TDD
    patterns.md           — Design patterns
    testing.md            — Test requirements
  operations/            — Operational concerns
    hooks.md              — Hook system
    performance.md        — Model routing
    windows-platform.md   — Windows quirks
```

#### Rule 1: `coding-style.md` — How Code Should Look

This rule enforces consistent, high-quality code across all your projects.

```markdown
# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones.
```

**What this means in plain English:** When you need to change data, don't modify the original — make a copy with the changes. This prevents bugs where one part of your program changes data that another part was still using.

**Real-world analogy:** Instead of erasing and rewriting a shared whiteboard (someone might be reading it!), make a photocopy, write your changes on the copy, and replace the original.

```markdown
## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Functions under 50 lines, nesting under 4 levels
- Organize by feature/domain, not by type
```

**What this means:** Each file should do one thing well. If a file grows past 400 lines, it's time to split it. Organize files by what they do (user authentication, payment processing) not by what they are (all controllers together, all models together).

```markdown
## Error Handling

ALWAYS handle errors comprehensively:
- Handle errors explicitly at every level
- Provide user-friendly error messages in UI-facing code
- Log detailed error context on the server side
- Never silently swallow errors
```

**What this means:** When something goes wrong, don't ignore it. Show the user a helpful message ("We couldn't save your file — check your internet connection") and log the technical details for debugging.

```markdown
## Input Validation

ALWAYS validate at system boundaries:
- Validate all user input before processing
- Use schema-based validation where available
- Fail fast with clear error messages
- Never trust external data
```

**What this means:** Any data coming from outside your program (user typing in a form, data from another website's API, contents of a file) could be wrong, incomplete, or malicious. Always check it before using it.

**Writing Style section (new):** The rule also includes a Writing Style section that prohibits em dashes in all written content (blog posts, docs, changelogs, comments). This applies to all prose output, not just code. Sentences should use commas, periods, colons, or parentheses instead.

> **Note:** We intentionally removed the "Code Quality Checklist" that was in the original everything-claude-code version. It restated the rules above and added context window cost without changing Claude's behavior.

---

#### Rule 2: `git-workflow.md` — How to Manage Code Changes

```markdown
# Git Workflow

## Commit Message Format

<type>: <description>

<optional body>

Types: feat, fix, refactor, docs, test, chore, perf, ci
```

**What is Git?** Git is a version control system — it tracks every change to your code so you can undo mistakes, see who changed what, and collaborate with others. A **commit** is a saved snapshot of your changes.

**What is a commit message?** A short description of what you changed and why. This rule enforces **conventional commits** — a standard format that makes history easy to read:

| Type | Meaning | Example |
|------|---------|---------|
| `feat` | New feature | `feat: add login button` |
| `fix` | Bug fix | `fix: prevent crash on empty input` |
| `refactor` | Code restructuring (no behavior change) | `refactor: simplify payment logic` |
| `docs` | Documentation only | `docs: update API reference` |
| `test` | Adding or fixing tests | `test: add unit tests for cart` |
| `chore` | Maintenance tasks | `chore: update dependencies` |
| `perf` | Performance improvement | `perf: cache database queries` |
| `ci` | Build/deploy pipeline changes | `ci: add automated testing` |

```markdown
## Feature Implementation Workflow

1. Plan First — Analyze requirements, identify dependencies, break into phases
2. TDD — Write tests first (RED), implement (GREEN), refactor (IMPROVE), verify 80%+ coverage
3. Review — Review code immediately after writing; address CRITICAL and HIGH issues
4. Commit — Detailed messages following conventional commits format
```

**What this means:** For any significant feature, Claude will follow a structured workflow: plan what to build, write tests to define what "working" means, implement the code, review it for quality, then commit. This prevents the common mistake of diving in without thinking.

> **Note:** The original everything-claude-code version referenced specific agents (planner, tdd-guide, code-reviewer) in each step. We removed those references so the workflow stands alone — it works whether or not you have the plugin installed.

---

#### Rule 3: `testing.md` — How to Test Code

```markdown
# Testing Requirements

## Minimum Test Coverage: 80%

Test Types (ALL required):
1. Unit Tests - Individual functions, utilities, components
2. Integration Tests - API endpoints, database operations
3. E2E Tests - Critical user flows
```

**What is test coverage?** The percentage of your code that is exercised by automated tests. 80% means 80 out of every 100 lines of code are tested. Higher coverage means fewer hidden bugs.

**The three test types:**

| Type | What It Tests | Analogy |
|------|--------------|---------|
| **Unit** | Individual functions in isolation | Testing each ingredient in a recipe tastes right |
| **Integration** | Multiple components working together | Testing that the ingredients combine correctly |
| **E2E (End-to-End)** | The full user experience | Testing the finished dish from a diner's perspective |

```markdown
## Test-Driven Development

MANDATORY workflow:
1. Write test first (RED) - it should FAIL
2. Write minimal implementation (GREEN) - it should PASS
3. Refactor (IMPROVE)
4. Verify coverage (80%+)
```

**What is TDD?** Test-Driven Development means writing the test *before* the code. It sounds backwards, but it's one of the most effective practices in software:

1. **RED:** Write a test describing what you want. It fails (red) because you haven't built it yet.
2. **GREEN:** Write the simplest possible code to make the test pass (green).
3. **REFACTOR:** Clean up the code, confident that if you break something, the test will catch it.

**Why TDD?** It forces you to think about what "done" means before you start coding. It also gives you a safety net — if you change something later and a test fails, you know exactly what broke.

---

#### Rule 4: `security.md` — How to Keep Code Safe

```markdown
# Security Guidelines

## Mandatory Security Checks

Before ANY commit:
- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (sanitized HTML)
- [ ] CSRF protection enabled
- [ ] Authentication/authorization verified
- [ ] Rate limiting on all endpoints
- [ ] Error messages don't leak sensitive data
```

**What these mean, one by one:**

| Check | What It Prevents | Real-World Analogy |
|-------|-----------------|-------------------|
| **No hardcoded secrets** | Your password being visible in your code (which anyone with access can see) | Don't write your PIN on your debit card |
| **Input validation** | Bad data causing crashes or unexpected behavior | Check someone's ID before letting them in |
| **SQL injection** | Attackers running database commands through your forms | Don't let strangers write on your shopping list |
| **XSS prevention** | Attackers injecting malicious scripts into your website | Don't let strangers put signs up in your store |
| **CSRF protection** | Attackers tricking users into performing actions they didn't intend | Verify the person at your door is who they say |
| **Auth verification** | Unauthorized users accessing restricted features | Check badges before entering restricted areas |
| **Rate limiting** | Attackers overwhelming your server with thousands of requests | Limit how many times someone can ring your doorbell |
| **Error messages** | Technical details leaking to attackers | Don't tell a burglar which window is unlocked |

```markdown
## Secret Management

- NEVER hardcode secrets in source code
- ALWAYS use environment variables or a secret manager
```

**What are environment variables?** Instead of putting your password directly in your code (dangerous!), you store it outside the code in a protected system variable. Your code reads the variable at runtime. This way, the password never appears in your source files.

```markdown
## Security Response Protocol

If security issue found:
1. STOP immediately
2. Fix CRITICAL issues before continuing
3. Rotate any exposed secrets
4. Review entire codebase for similar issues
```

**What "rotate secrets" means:** If a password or token was accidentally exposed (committed to git, shown in a log), you can't just delete it — someone may have already seen it. You need to generate a **new** password/token and deactivate the old one.

---

#### Rule 5: `performance.md` — How to Work Efficiently

```markdown
# Performance Optimization

## Model Selection Strategy

Haiku 4.5 (90% of Sonnet capability, 3x cost savings):
- Lightweight agents, background tasks, pair programming

Sonnet 4.5 (Best coding model):
- Main development work, complex coding tasks

Opus 4.6 (Deepest reasoning):
- Architectural decisions, security analysis, research
```

**What are models?** Claude comes in different sizes, like T-shirt sizes:

| Model | Strengths | Cost | When to Use |
|-------|-----------|------|-------------|
| **Haiku** | Fast, cheap, good enough for routine tasks | $ | Background tasks, simple code generation |
| **Sonnet** | Great balance of speed, quality, and cost | $$ | Day-to-day coding work |
| **Opus 4.6** | Deepest reasoning, best for complex problems | $$$ | Architecture decisions, security analysis, hard bugs |

Claude Code uses a mix of these models. The rule tells Claude to use the cheapest model that's good enough for each task — like using a sedan for grocery runs and saving the SUV for road trips.

```markdown
## Context Window Management

Avoid last 20% of context window for large-scale refactoring, multi-file
features, and complex debugging. Single-file edits, utilities, docs, and
simple bug fixes are fine at any context level.
```

**What is the context window?** Claude can only "remember" a certain amount of text in a conversation. The context window is like Claude's short-term memory. When it fills up, older parts of the conversation are compressed or forgotten.

**Why avoid the last 20%?** When the context window is almost full, Claude may lose track of important details. For complex tasks that need lots of context, it's better to compact (summarize) the conversation first.

**How to compact:**
```
/compact
```

This tells Claude to summarize the conversation so far, freeing up space for new work.

> **Note:** The original everything-claude-code version included an "Extended Thinking + Plan Mode" section with UI keybindings (`Alt+T`, `Ctrl+O`). We removed it because it documented UI features rather than giving Claude behavioral instructions — it added context window cost without changing how Claude works.

---

#### Rule 6: `patterns.md` — Reusable Design Patterns

```markdown
# Common Patterns

## Skeleton Projects

When implementing new functionality:
1. Search for battle-tested skeleton projects
2. Evaluate options for security, extensibility, and relevance
3. Clone best match as foundation
4. Iterate within proven structure
```

**What this means:** Don't build everything from scratch. When starting something new, first look for existing templates or starter projects that solve a similar problem. It's faster and you benefit from someone else's experience.

```markdown
## Repository Pattern

Encapsulate data access behind a consistent interface:
- Define standard operations: findAll, findById, create, update, delete
- Concrete implementations handle storage details
- Business logic depends on the abstract interface
- Enables easy swapping of data sources
```

**What this means in plain English:** Instead of your code directly talking to a database, put a "middleman" layer in between. The middleman always offers the same operations (find, create, update, delete). If you later switch from one database to another, you only change the middleman — not every piece of code that uses data.

```markdown
## API Response Format

Use a consistent envelope for all API responses:
- Include a success/status indicator
- Include the data payload (nullable on error)
- Include an error message field (nullable on success)
- Include metadata for paginated responses
```

**What this means:** Every API response should look the same structurally:
```json
{
  "success": true,
  "data": { "name": "Chris", "email": "..." },
  "error": null,
  "metadata": { "total": 42, "page": 1 }
}
```

This consistency makes it easy for anyone consuming your API to know what to expect.

---

#### Rule 7: `hooks.md` — Automation Guidelines

```markdown
# Hooks System

## Hook Types

- PreToolUse: Before tool execution (validation, parameter modification, file protection)
- PostToolUse: After tool execution (auto-format, checks, logging)
- Stop: When session ends (final verification, notifications)
- SessionEnd: When session closes (archiving, cleanup)
```

**What are hooks?** Hooks are scripts that run automatically when Claude Code does something. They're like tripwires, when a specific event happens, your script fires.

| Hook Type | When It Fires | Example Use |
|-----------|--------------|-------------|
| **PreToolUse** | *Before* Claude uses a tool | Block Claude from deleting important files |
| **PostToolUse** | *After* Claude uses a tool | Auto-format code after every edit |
| **SessionEnd** | When you close Claude Code | Save the conversation transcript |
| **Stop** | When Claude finishes a response | Check for leftover debug statements |

```markdown
## Auto-Accept Permissions

- Enable for trusted, well-defined plans
- Disable for exploratory work
- Never use dangerously-skip-permissions flag
- Configure allowedTools in ~/.claude.json instead
```

**What are permissions?** By default, Claude Code asks your permission before doing anything potentially risky (running commands, editing files). You can pre-approve specific actions so it doesn't ask every time. But be careful — auto-accepting everything is like giving someone your house keys.

> **Note:** The original everything-claude-code version included a "TodoWrite Best Practices" section in this rule. We removed it because it wasn't related to hooks and didn't change Claude's behavior enough to justify the context window cost.

---

#### Rule 8: `agents.md` — Specialized AI Assistants

> **Note:** This rule requires the [everything-claude-code](https://github.com/affaan-m/everything-claude-code) plugin. Without it, the agent references won't do anything. The other 7 rules work standalone.

```markdown
# Agent Orchestration

> Requires: everything-claude-code plugin.

## Available Agents

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| planner | Implementation planning | Complex features, refactoring |
| architect | System design | Architectural decisions |
| tdd-guide | Test-driven development | New features, bug fixes |
| code-reviewer | Code review | After writing code |
| security-reviewer | Security analysis | Before commits |
| build-error-resolver | Fix build errors | When build fails |
| e2e-runner | E2E testing | Critical user flows |
| refactor-cleaner | Dead code cleanup | Code maintenance |
| doc-updater | Documentation | Updating docs |
```

**What are agents?** Agents are specialized Claude instances with focused expertise. Instead of one general-purpose AI, you have a team of specialists:

- The **planner** thinks through what needs to be built before anyone writes code
- The **tdd-guide** ensures tests are written first
- The **code-reviewer** checks code quality after it's written
- The **security-reviewer** looks for vulnerabilities
- The **build-error-resolver** fixes compilation errors

**How to invoke them:**
```
/plan              — Activates the planner agent
/tdd               — Activates the TDD guide agent
/code-review       — Activates the code reviewer agent
/security          — Activates the security reviewer agent
/build-fix         — Activates the build error resolver
```

```markdown
## Immediate Agent Usage

No user prompt needed:
1. Complex feature requests - Use planner agent
2. Code just written/modified - Use code-reviewer agent
3. Bug fix or new feature - Use tdd-guide agent
4. Architectural decision - Use architect agent
```

**What "proactive" means:** Claude doesn't wait for you to ask. If you request a complex feature, Claude automatically activates the planner. If it just wrote code, it automatically runs the code reviewer. This is like having a team where everyone knows when to step in.

```markdown
## Custom Agents (~/.claude/agents/)

| Agent | Purpose | Model |
|-------|---------|-------|
| changelog-writer | Auto-generate CHANGELOG entries | haiku |
| multi-repo-orchestrator | Parallel cross-repo operations | haiku |
| session-analyzer | Extract patterns from archives | sonnet |
| deploy-verifier | Post-deploy verification | haiku |
| config-sync | Sync config to git repo | haiku |
| context-health | Monitor context window | haiku |
| skill-extractor | Extract skills from transcripts | sonnet |
```

**What are custom agents?** Beyond the plugin's agents, you can define your own. Custom agents are markdown files in `~/.claude/agents/` with YAML frontmatter specifying the model and available tools. Claude Code's Task tool spawns them as specialized subprocesses with their own context windows.

```markdown
## Mandatory Parallel Execution

See rules/core/agentic-workflow.md for full decomposition rules.
ALWAYS use parallel Task execution for independent operations.
```

**What this means:** When Claude needs to do multiple independent things (e.g., review security AND check performance AND verify types), it runs them all simultaneously instead of one at a time. This is faster. The `agentic-workflow.md` rule (new in the restructured config) provides detailed patterns for parallel execution, automatic agent triggers, and cost optimization.

---

### Learned Skills

**Location:** `~/.claude/skills/learned/` (one `.md` file per skill)

Learned skills are reusable patterns extracted from real debugging sessions using the `/learn` command. Each skill documents a non-obvious problem, its solution, and when the pattern applies. Claude loads these at session start and uses them to avoid repeating past mistakes.

**How skills get created:** During or after a session where you solve a tricky problem, run `/learn`. Claude analyzes the session, identifies non-trivial patterns worth preserving, and creates skill files with a consistent structure:

```markdown
# Descriptive Pattern Name

**Extracted:** 2026-02-08
**Context:** Brief description of when this applies

## Problem
What went wrong and why it's non-obvious

## Solution
The fix or workaround

## When to Use
Trigger conditions — how to recognize this situation
```

**Current skills (18 total, organized in 6 categories via INDEX.md):**

| # | Skill File | What It Catches |
|---|-----------|----------------|
| 1 | `powershell-stdin-hooks.md` | PowerShell's `$input` silently returns nothing when hooks are invoked via `-File`. You need `[Console]::In.ReadToEnd()` + dot-sourcing. |
| 2 | `mcp-config-location.md` | `~/.claude/mcp-servers.json` is for Claude Desktop, not Claude Code. Claude Code reads `~/.claude.json`. |
| 3 | `command-yaml-frontmatter.md` | Custom slash commands are silently ignored without YAML frontmatter (`---\ndescription: ...\n---`). |
| 4 | `git-bash-npm-path-mangling.md` | Git Bash rewrites Windows paths, breaking npm module resolution with `MODULE_NOT_FOUND`. |
| 5 | `nextjs-client-component-metadata.md` | Can't export `metadata` from a `"use client"` component in Next.js 15+. Fix: wrapper `layout.tsx`. |
| 6 | `mdx-same-date-sort-order.md` | Blog posts with identical date strings sort non-deterministically. Fix: use ISO timestamps. |
| 7 | `slug-path-traversal-guard.md` | URL slug parameters in `path.join()` allow path traversal attacks. Fix: reject slugs with `/`, `\`, or `..`. |
| 8 | `git-bash-powershell-variable-stripping.md` | Git Bash strips `$` from inline PowerShell commands. Fix: write a temp `.ps1` file. |
| 9 | `claude-code-debug-diagnostics.md` | `claude doctor` requires an interactive TTY. Fix: `claude --debug --debug-file <path> --print "say OK"`. |
| 10 | `token-secret-safety.md` | Reading config files with plaintext API keys exposes them in transcripts. Fix: redact to first 10-15 chars. |
| 11 | `heredoc-permission-pollution.md` | HEREDOC commit bodies with parentheses get captured as garbage permission entries. Fix: clean settings after. |
| 12 | `cookie-auth-over-query-strings.md` | `?secret=X` leaks in URLs, browser history, Referer headers, logs. Fix: httpOnly cookies with HMAC tokens. |
| 13 | `ssrf-prevention-ip-validation.md` | Validate IPs against private ranges (127.x, 10.x, 172.16-31.x, 192.168.x) before external API calls. |
| 14 | `shallow-fetch-force-push.md` | `git fetch --depth=1` + `git push --force` fails. Fix: full fetch (no `--depth`) before force push. |
| 15 | `mdx-blog-design-system.md` | MDX callout components (`<Tip>`, `<Warning>`, `<Security>`) and product badges (`<Vercel>`, `<Nextjs>`). |
| 16 | `vercel-json-waf-syntax.md` | vercel.json uses `routes` with `mitigate: { action: "deny" }`, not `rules`. |
| 17 | `anthropic-model-id-format.md` | Haiku requires exact date suffix (`-20251001`), not `-latest` alias. |
| 18 | `vitest-class-mock-constructor.md` | Arrow functions can't be called with `new`. Use `class` expressions in `vi.mock` factory functions. |

**Why this matters:** Every skill represents hours of debugging compressed into a few lines. When Claude encounters a similar situation in a future session, it recognizes the pattern and applies the fix immediately instead of going through the same trial-and-error process.

---

### Custom Agents

**Location:** `~/.claude/agents/` (one `.md` file per agent)

Custom agents are specialized agent definitions that Claude Code's Task tool can spawn as subprocesses. Each agent has its own context window and focused instructions, making them ideal for specific tasks.

Each agent file has YAML frontmatter specifying:
- `description` — What the agent does
- `model` — Which Claude model to use (haiku, sonnet, opus)
- `tools` — Which tools the agent can access

**Current agents (7 total):**

| Agent | Model | Purpose |
|-------|-------|---------|
| **changelog-writer** | haiku | Generates CHANGELOG.md entries from git diffs and session context |
| **multi-repo-orchestrator** | haiku | Runs parallel git operations across all project repos |
| **session-analyzer** | sonnet | Reads session archive transcripts and extracts actionable patterns |
| **deploy-verifier** | haiku | Verifies builds and live site after deployment |
| **config-sync** | haiku | Compares local `~/.claude/` config against the git repo for drift |
| **context-health** | haiku | Monitors context window usage and suggests compaction points |
| **skill-extractor** | sonnet | Identifies reusable patterns in sessions worth preserving as skills |

**How to create your own agent:**

1. Create a `.md` file in `~/.claude/agents/`
2. Add YAML frontmatter with `description`, `model`, and `tools`
3. Write instructions as if briefing a specialist on their role

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

---

### Custom Skills

**Location:** `~/.claude/skills/*/SKILL.md`

Custom skills are user-invocable workflows (similar to slash commands) that provide complex multi-step automation. Each skill lives in its own subdirectory with a `SKILL.md` file containing YAML frontmatter and detailed instructions.

Skills take priority over commands when both exist for the same name.

**Current skills (4 total):**

| Skill | What It Does |
|-------|-------------|
| **`/wrap-up`** | 12-step end-of-session agent: pulls repos, reviews session, updates CHANGELOG/README/MEMORY, extracts skills, cleans state, commits, pushes. |
| **`/blog-post`** | Interactive blog writing agent. Asks what to write about, gathers source material, writes a formatted MDX post. Delegates to Sonnet for cost-efficient content generation. |
| **`/multi-repo-status`** | Quick dashboard showing git status across all 4 project repos in parallel. |
| **`/skill-catalog`** | Full inventory of all agents, skills, commands, and hooks with descriptions. |

---

### Custom Commands

**Location:** `~/.claude/commands/` (one `.md` file per command)

Custom commands are user-level slash commands that encode complex multi-step workflows into a single invocation. They work from any project.

Each command file is a markdown document with YAML frontmatter and detailed instructions. When you type the command (e.g., `/wrap-up`), Claude reads the file and follows the instructions with full access to the conversation history and all its tools.

**Current commands (2 total):**

| Command | File | What It Does |
|---------|------|-------------|
| **`/wrap-up`** | `wrap-up.md` | 12-step end-of-session agent. Pulls all repos, reviews the session, updates CHANGELOG/README/MEMORY, extracts learned skills, cleans global state and permissions, commits with Hulk Hogan persona, and pushes after confirmation. |
| **`/blog-post`** | `blog-post.md` | Interactive blog writing agent for cryptoflexllc.com. Asks what to write about, gathers source material from git logs and session history, writes a fully formatted MDX post. Delegates to Sonnet 4.5 for cost-efficient content generation. |

**How to create your own:**

1. Create a `.md` file in `~/.claude/commands/` (user-level) or `.claude/commands/` (project-level)
2. Add YAML frontmatter with a `description` field — **this is required** or Claude Code silently ignores the file
3. Write instructions as if briefing a capable assistant on a complex task
4. Restart Claude Code — commands are discovered at session start, not mid-session

```markdown
---
description: "What this command does in one line"
---

# /your-command - Title

You are a [role]. Your job is to [objective].

## Steps
1. First thing to do
2. Second thing to do

## Important Notes
- Safety rails and constraints
```

**Key insight:** You're not writing code — you're writing instructions for an agent. The quality of the output depends entirely on the quality of your instructions. Be specific about formats, include examples, and add safety rails for things that could go wrong.

---

### Backup Strategy

**File:** `~/.claude/.gitignore`

This file controls what gets backed up to GitHub and what stays local. It uses an **ignore-everything-then-whitelist** pattern:

```gitignore
# Ignore everything by default
*

# ===== TRACK THESE =====
!.gitignore
!README.md
!COMPLETE-GUIDE.md

# Rules (organized in subdirectories: core/, development/, operations/)
!rules/
!rules/**

# Custom agents
!agents/
!agents/*.md

# Skills (custom SKILL.md + learned patterns)
!skills/
!skills/**

# Custom commands
!commands/
!commands/*.md

# ===== NEVER TRACK (even if whitelisted above) =====
cache/
plugins/cache/
sessions/
history.jsonl
settings.json
projects/
file-history/
shell-snapshots/
todos/
tasks/
plans/
downloads/
debug/
ide/
session-env/
```

**How this works:**

1. `*` — Start by ignoring EVERYTHING
2. `!rules/` and `!rules/*.md` — Exception: track rule files (the `!` means "don't ignore this")
3. `!skills/` and `!skills/**` — Exception: track learned skills
4. Everything in the "NEVER TRACK" section — Explicitly ignored even if a whitelist rule would match

**What gets backed up and why:**

| Tracked | Why Back It Up |
|---------|---------------|
| Rule files (`rules/**/*.md`) | Your coding standards, organized in subdirectories |
| Agent files (`agents/*.md`) | Custom agent definitions |
| Learned skills (`skills/learned/`) | Patterns Claude learned from your sessions |
| Custom skills (`skills/*/SKILL.md`) | Workflow automation |
| Custom commands (`commands/*.md`) | Slash command definitions |
| `.gitignore` | So the ignore rules themselves are versioned |
| `README.md` | Documents what's in the repo |
| `COMPLETE-GUIDE.md` | Comprehensive setup walkthrough |

**What stays local and why:**

| Excluded | Why Exclude It |
|----------|---------------|
| `settings.json` | Contains machine-specific paths |
| `sessions/`, `history.jsonl` | Conversation history — huge files, private |
| `plugins/cache/` | Downloaded plugins — can be re-fetched |
| `projects/` | Per-project memory files |
| `cache/`, `file-history/`, etc. | Temporary working data |

---

## Project-Level Configuration

These files live inside a specific project and only affect that project.

---

### Project Instructions: `CLAUDE.md`

**File:** `your-project/CLAUDE.md` (in the project root)

This is the most important file in any Claude Code project. It's the first thing Claude reads when you open the project. Think of it as the project's "employee handbook" — it tells Claude what this project is, how to work on it, and what rules to follow.

Here's a real example:

```markdown
# Project Context

This is a Claude Code learning project. The goal is to explore Claude Code's
capabilities while keeping a comprehensive record of what was tried, what
worked, what failed, and why.
```

**The opening paragraph** gives Claude essential context. Without this, Claude doesn't know if it's working on a medical app, a game, or a learning project. The context shapes every decision Claude makes.

```markdown
## Project Structure

.claude/
  hooks/
    save-session.ps1      # Archives transcripts on session end
    log-activity.ps1      # Logs tool usage in real time
  session_archive/        # Archived transcripts (git-ignored)
  settings.local.json     # Permissions + hooks config

CLAUDE.md          # This file
CHANGELOG.md       # Human-readable history of changes
README.md          # Journey document: what we learned
activity_log.txt   # Running log of all tool operations (git-ignored)
```

**The project structure** tells Claude where everything is. Without this, Claude has to search the entire project to find things, which wastes time and context window.

```markdown
## Session Instructions

Follow these instructions every session:

1. Record what you do. Update CHANGELOG.md with dated entries.
2. Explain your reasoning. Include comments explaining why, not just what.
3. Document failures too. Failed approaches are valuable learning material.
4. Keep README.md as a journey document.
5. Commit with descriptive messages when asked.
6. Don't delete history. Document abandoned approaches instead.
```

**Session instructions** are like standing orders. Every time Claude starts a conversation in this project, it follows these rules. You can put anything here — "always use TypeScript," "never modify the database schema without asking," "update the changelog after every change."

```markdown
## Hooks System

- SessionEnd hook: save-session.ps1 copies the full conversation transcript
- PostToolUse hook: log-activity.ps1 logs every operation to activity_log.txt

These run automatically — no manual action needed.
```

**Documenting hooks** in CLAUDE.md is good practice because it helps Claude understand what automation is already in place. Claude won't try to manually do something that a hook already handles.

```markdown
## Tech Notes

- Platform: Windows (PowerShell for hook scripts)
- No external dependencies required
- Raw transcripts are git-ignored; human-readable docs are tracked
```

**Tech notes** prevent Claude from making wrong assumptions (like trying to use bash scripts on a Windows machine).

**How to create your own CLAUDE.md:** Create a file called `CLAUDE.md` in your project root. Include:
1. What the project is (one paragraph)
2. The file/folder structure
3. Any rules Claude should follow
4. Technical constraints (language, framework, platform)

---

### Project Settings

**File:** `your-project/.claude/settings.local.json`

This file has two main sections: **permissions** and **hooks**.

#### Permissions Section

```json
{
  "permissions": {
    "allow": [
      "Bash(dir)",
      "WebSearch",
      "WebFetch(domain:docs.claude.com)",
      "WebFetch(domain:github.com)",
      "Bash(powershell:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git push:*)"
    ]
  }
}
```

**What this does:** Pre-approves specific actions so Claude doesn't ask permission every time. Without these, Claude would prompt you for approval on every single command.

**How to read the permission format:**

| Permission | What It Allows |
|-----------|---------------|
| `"Bash(dir)"` | Run the `dir` command (list files on Windows) |
| `"WebSearch"` | Search the web |
| `"WebFetch(domain:docs.claude.com)"` | Fetch web pages from docs.claude.com only |
| `"WebFetch(domain:github.com)"` | Fetch web pages from github.com only |
| `"Bash(powershell:*)"` | Run any PowerShell command (the `*` means "anything") |
| `"Bash(git add:*)"` | Run any `git add` command |
| `"Bash(git commit:*)"` | Run any `git commit` command |
| `"Bash(git push:*)"` | Run `git push` |

**The wildcard `*`:** Means "match anything." `Bash(git add:*)` allows `git add README.md`, `git add .`, `git add --all`, etc.

**Security note:** Be careful with wildcards. `Bash(*)` would allow Claude to run ANY command without asking — including deleting files. The permissions in this config are deliberately specific.

> **Tip:** You don't need to write these by hand. When Claude asks "Allow this command?" and you approve it, Claude Code automatically adds it to the permissions list. Over time, your permissions file fills up with commands you've approved.

#### Hooks Section

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \". '.claude/hooks/save-session.ps1'\""
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
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \". '.claude/hooks/log-activity.ps1'\"",
            "async": true
          }
        ]
      }
    ]
  }
}
```

Let's decode this piece by piece:

**SessionEnd hook:**
```json
"SessionEnd": [{
  "hooks": [{
    "type": "command",
    "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \". '.claude/hooks/save-session.ps1'\""
  }]
}]
```

- `"SessionEnd"` — This hook fires when you close Claude Code or type `/exit`
- `"type": "command"` — It runs a shell command
- `"command"` — The actual command to run. Let's break it down:
  - `powershell` — Use PowerShell (Windows's scripting language)
  - `-NoProfile` — Don't load the user's PowerShell profile (faster startup)
  - `-ExecutionPolicy Bypass` — Allow the script to run (Windows security policy)
  - `-Command ". '.claude/hooks/save-session.ps1'"` — Run the script using dot-sourcing (a PowerShell technique that allows reading stdin)

**PostToolUse hook:**
```json
"PostToolUse": [{
  "matcher": "Bash|Edit|Write|NotebookEdit",
  "hooks": [{
    "type": "command",
    "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \". '.claude/hooks/log-activity.ps1'\"",
    "async": true
  }]
}]
```

- `"PostToolUse"` — This hook fires after Claude uses a tool
- `"matcher": "Bash|Edit|Write|NotebookEdit"` — Only fire for these specific tools (the `|` means "or"). It won't fire for Read, Grep, or Glob operations.
- `"async": true` — **This is important.** The hook runs in the background and doesn't block Claude from continuing. Without this, Claude would freeze every time it edits a file, waiting for the logging script to finish.

---

### Hooks

The hook scripts are PowerShell files that do the actual work when hooks fire.

#### `save-session.ps1` — Session Archiver

This script runs when you end a Claude Code session. It saves a copy of your entire conversation.

```powershell
$ErrorActionPreference = "SilentlyContinue"
```

**What this does:** Tells PowerShell to silently continue if any errors occur. Hooks should NEVER crash Claude Code — a logging failure shouldn't break your workflow.

```powershell
try {
    $inputJson = [Console]::In.ReadToEnd()
} catch {
    $inputJson = $input | Out-String
}
if (-not $inputJson -or $inputJson.Trim() -eq "") { exit 0 }
```

**What this does:** Reads the JSON data that Claude Code sends to the hook via stdin (standard input). Claude Code passes information like the session ID and where the transcript file is stored.

**Why `[Console]::In.ReadToEnd()` instead of `$input`?** This is a Windows/PowerShell gotcha. The normal `$input` variable doesn't work when PowerShell is invoked with `-Command`. You have to use the `[Console]::In` method instead. This took trial and error to discover!

```powershell
$data = $inputJson | ConvertFrom-Json
$transcriptPath = $data.transcript_path
$sessionId      = $data.session_id
```

**What this does:** Parses the JSON data and extracts:
- `transcript_path` — Where Claude Code stored the raw conversation file
- `session_id` — A unique ID for this session

```powershell
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$archiveDir  = Join-Path $projectRoot ".claude\session_archive"
```

**What this does:** Figures out where the project root is. Since this script lives in `.claude/hooks/`, it goes up 2 directory levels to find the project root, then sets the archive directory.

```powershell
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$archiveName = "${timestamp}_${sessionId}"
Copy-Item -Path $transcriptPath -Destination $destPath -Force
```

**What this does:** Creates a timestamped filename (like `2026-02-07_14-30-00_abc123.jsonl`) and copies the transcript there.

The script also creates a **human-readable summary** and updates an **index file** for easy searching.

#### `log-activity.ps1` — Activity Logger

This script runs after every tool use (edits, writes, commands). It creates a running log of everything Claude does.

The structure is similar to `save-session.ps1` — read JSON from stdin, parse it, write a log line:

```powershell
$detail = ""
switch ($toolName) {
    "Edit"  { $detail = "Edited: $file" }
    "Write" { $detail = "Wrote: $file" }
    "Bash"  { $detail = "Ran: $cmd" }
    "NotebookEdit" { $detail = "Edited notebook: $nb" }
    default { $detail = "Used tool: $toolName" }
}

$logLine = "[$timestamp] ($sessionId) $toolName | $detail"
$logLine | Out-File -Append -FilePath $logPath -Encoding utf8
```

**What the output looks like:**
```
[2026-02-07 12:30:15] (abc123) Bash | Ran: git status
[2026-02-07 12:30:22] (abc123) Edit | Edited: D:\project\README.md
[2026-02-07 12:31:05] (abc123) Write | Wrote: D:\project\new_file.txt
```

This gives you a complete audit trail of everything Claude did in your project.

---

## How to Set This Up From Scratch

Here's a step-by-step guide to replicate this entire configuration on a fresh machine.

### Prerequisites

1. **Node.js** (v18 or newer) — download from [nodejs.org](https://nodejs.org/)
2. **Git** — download from [git-scm.com](https://git-scm.com/)
3. **Claude Code** — install with `npm install -g @anthropic-ai/claude-code`
4. **A Claude account** with API access or a Pro/Team subscription

### Step 1: Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude     # First run — will prompt you to log in
```

### Step 2: Install the Everything-Claude-Code Plugin

Create or edit `~/.claude/settings.json`:

```json
{
  "autoUpdatesChannel": "latest",
  "extraKnownMarketplaces": {
    "everything-claude-code": {
      "source": { "source": "github", "repo": "affaan-m/everything-claude-code" }
    }
  },
  "enabledPlugins": {
    "everything-claude-code@everything-claude-code": true
  }
}
```

### Step 3: Create Your Rules

Create the directory structure `~/.claude/rules/` with subdirectories and add the rule files. You can copy them from this repository or write your own.

```bash
mkdir -p ~/.claude/rules/core ~/.claude/rules/development ~/.claude/rules/operations
```

The rules from this config (10 files in 3 subdirectories + root):
- `agents.md` — Agent orchestration (plugin + custom)
- `core/agentic-workflow.md` — Parallel task decomposition
- `core/coding-style.md` — Code quality + writing style
- `core/security.md` — Security checklist
- `development/git-workflow.md` — Commits, PRs, TDD workflow
- `development/patterns.md` — Design patterns
- `development/testing.md` — TDD and coverage
- `operations/hooks.md` — Hook types and file protection
- `operations/performance.md` — Model routing and cost optimization
- `operations/windows-platform.md` — Windows-specific workarounds

### Step 4: Set Up MCP Servers

We recommend 2 servers that provide capabilities Claude Code doesn't have built in:

```bash
# Memory — persistent knowledge across sessions (no built-in equivalent)
claude mcp add --scope user memory -- npx -y @modelcontextprotocol/server-memory

# Context7 — live documentation lookup (beats relying on training data)
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest
```

Optional — add the GitHub server if you do heavy GitHub API work:
```bash
claude mcp add-json --scope user github '{"command":"npx","args":["-y","@modelcontextprotocol/server-github"],"env":{"GITHUB_PERSONAL_ACCESS_TOKEN":"YOUR_TOKEN_HERE"}}'
```

> **Why only 2?** We initially installed 5 servers but dropped filesystem (duplicates built-in Read/Write/Edit/Glob/Grep), sequential-thinking (duplicates built-in extended thinking), and github (largely covered by the `gh` CLI). See the [MCP Servers](#mcp-servers) section for details.

### Step 5: Create a Project with CLAUDE.md

In your project directory, create a `CLAUDE.md` file:

```markdown
# Project Context

[Describe your project in 1-2 sentences]

## Session Instructions

1. [Your rules for Claude to follow every session]
2. [e.g., "Always use TypeScript"]
3. [e.g., "Update CHANGELOG.md after changes"]
```

### Step 6: (Optional) Set Up Hooks

Create `.claude/hooks/` in your project and add hook scripts. Then configure them in `.claude/settings.local.json`.

### Step 7: (Optional) Back Up Your Config

```bash
cd ~/.claude
git init

# Create .gitignore (ignore everything, whitelist what matters)
# See the Backup Strategy section above for the full .gitignore

git add -A
git commit -m "Initial config backup"

# Push to GitHub (requires gh CLI: npm install -g gh)
gh auth login
gh repo create my-claude-config --private --source=. --push
```

---

## Key Concepts Explained

### What Is a CLI?

CLI stands for Command Line Interface — a text-based way to interact with your computer. Instead of clicking buttons in a graphical window, you type commands. Claude Code runs in the CLI.

### What Is Git?

Git is a version control system that tracks changes to files over time. Every change is saved as a "commit" with a message describing what changed. You can go back to any previous version, see who changed what, and collaborate with others without overwriting each other's work.

### What Is GitHub?

GitHub is a website that hosts Git repositories (collections of files tracked by Git) online. It adds collaboration features like pull requests (proposed changes for review), issues (bug reports and feature requests), and actions (automated workflows).

### What Is JSON?

JSON (JavaScript Object Notation) is a text format for storing structured data. It uses curly braces `{}` for objects, square brackets `[]` for lists, and `"key": "value"` pairs:

```json
{
  "name": "Chris",
  "tools": ["Claude Code", "VS Code", "Git"],
  "experience": {
    "level": "learning",
    "focus": "AI-assisted development"
  }
}
```

Most Claude Code configuration files use JSON.

### What Is Markdown?

Markdown is a simple formatting language for text. It's what `.md` files use:

```markdown
# This is a heading
## This is a smaller heading
**This is bold**
*This is italic*
- This is a bullet point
1. This is a numbered list
`this is inline code`
```

All the rule files and CLAUDE.md use Markdown because it's easy to read both as raw text and when rendered.

### What Are Tokens?

In AI, a "token" is roughly a word or word-piece. Claude's context window is measured in tokens. When this config mentions "31,999 tokens for thinking," it means Claude can use roughly 24,000 words of internal reasoning before answering.

### What Is npx?

`npx` is a tool that comes with Node.js. It downloads and runs a program temporarily without permanently installing it. All our MCP servers use `npx -y` — the `-y` flag means "yes, install without asking."

---

## Troubleshooting

### MCP servers not loading

**Symptom:** `/mcp` shows "No MCP servers configured"

**Cause:** Servers might be in the wrong config file.

**Fix:** Make sure servers are in `~/.claude.json` (NOT `~/.claude/mcp-servers.json`). Use `claude mcp add --scope user` to add them correctly.

### MCP server shows "failed"

**Symptom:** `/mcp` shows a server with "failed" status

**Cause:** Usually Node.js isn't installed or isn't in PATH.

**Fix:**
1. Verify Node.js is installed: `node --version`
2. Try running the server manually: `npx -y @modelcontextprotocol/server-memory`
3. Restart Claude Code from a fresh terminal

### Plugin commands not appearing

**Symptom:** Typing `/` doesn't show expected commands like `/plan` or `/verify`

**Cause:** Plugin command files may be missing YAML frontmatter (a known bug in some plugin versions).

**Fix:** Check that each command `.md` file in the plugin cache starts with:
```yaml
---
description: What this command does
---
```

Plugin cache location: `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/commands/`

### Hooks not firing

**Symptom:** Activity log or session archive isn't being created

**Fix checklist:**
1. Check `.claude/settings.local.json` has the hooks configured
2. Verify the hook scripts exist at the paths referenced
3. On Windows: make sure the command uses `-Command ". 'script.ps1'"` (dot-sourcing), not `-File script.ps1`
4. Test the script manually: `echo '{"tool_name":"test"}' | powershell -NoProfile -Command ". '.claude/hooks/log-activity.ps1'"`

### Context window filling up

**Symptom:** Claude seems to forget earlier parts of the conversation

**Fix:** Type `/compact` to summarize the conversation and free up space. Do this at natural stopping points — after finishing a task, before switching to something new.

### Permission denied errors

**Symptom:** Claude says "permission denied" when trying to run a command

**Fix:** Either approve the action when prompted, or pre-approve it in `.claude/settings.local.json` under `permissions.allow`. See the [Permissions Section](#permissions-section) for the format.

---

## Credits

- **Claude Code** by [Anthropic](https://www.anthropic.com/)
- **everything-claude-code** plugin by [Affaan Mustafa](https://github.com/affaan-m/everything-claude-code)
- **MCP servers** by the [Model Context Protocol](https://github.com/modelcontextprotocol) community
- Configuration documented and explained by Chris with Claude
