# The Vector Memory System: Persistent Memory for Claude Code

## The Problem With Forgetting

Claude Code has no long-term memory. Every session starts blank. You explain your project structure, your preferences, your conventions, your past decisions, and then the session ends and it all disappears. The next session, you start over.

This is the single biggest friction point in working with an AI coding assistant. Context is everything. A developer who joins your team on day 30 is dramatically more useful than on day 1, not because their skills changed but because they accumulated context: which patterns the codebase follows, which approaches were tried and failed, which dependencies are fragile, which shortcuts actually work.

Claude Code, by default, resets to day 1 every single session.

The vector memory system solves this.

## What Claude Code Ships With

Out of the box, Claude Code has exactly one persistence mechanism: **MEMORY.md**.

### MEMORY.md (Auto Memory)

MEMORY.md is a per-project markdown file stored at `~/.claude/projects/<project-hash>/memory/MEMORY.md`. Claude Code automatically loads the first 200 lines at the start of every session. You can write to it, and whatever you write persists across sessions.

It works. For small things. But it has real limitations:

1. **200-line cap.** Only the first 200 lines are loaded into context. Beyond that, content is silently truncated. For any non-trivial project, 200 lines fills up fast.

2. **No search.** MEMORY.md is loaded wholesale. There is no way to query it, filter it, or retrieve specific information. Everything gets loaded every time, whether it is relevant or not.

3. **No semantic understanding.** If you wrote "we deploy to production on Fridays" and later ask "when do we ship?", MEMORY.md cannot connect those concepts. It is raw text injection, not knowledge retrieval.

4. **Single file, global scope.** Everything goes in one file. Bug fixes sit next to architecture decisions sit next to build commands. There is no categorization, no tagging, no filtering.

5. **Manual discipline required.** Nothing reminds you to save. Nothing captures context automatically. If you forget to update MEMORY.md at the end of a long session, that context is gone.

6. **No cross-project memory.** MEMORY.md is scoped to a single project directory. Knowledge from one project is invisible to sessions in another project. If you learned a critical debugging technique in Project A, Claude starts from scratch when you open Project B.

7. **No temporal awareness.** A note from three months ago has exactly the same weight as one from today. There is no concept of recency, relevance decay, or freshness.

For trivial projects, these limitations don't matter. For professional development across multiple repositories over weeks and months, they are crippling. You end up repeating yourself constantly, re-explaining decisions, re-debugging issues that were already solved.

## The Vector Memory System

The vector memory system is a multi-layered architecture that gives Claude Code genuine persistent memory with semantic search, automatic capture, behavioral learning, and cross-project recall. It is built from five independent subsystems, each solving a specific part of the memory problem.

Here is what happens in a session with the full system active:

1. Claude Code loads MEMORY.md as usual (200 lines of stable project facts).
2. When you describe a task, Claude queries vector memory for relevant prior context (bug fixes, decisions, workarounds from past sessions).
3. As Claude works, hooks automatically capture tool usage for behavioral analysis.
4. A nudge system reminds Claude to save important findings when significant code changes happen without memory stores.
5. When the session ends, the full transcript is archived for later analysis.
6. Periodically, an ingestion pipeline processes archives to extract patterns, store insights, and build behavioral instincts.

The result: Claude gets meaningfully better at your specific work over time.

## Architecture Overview

```
+------------------------------------------------------------------+
|                        SESSION RUNTIME                            |
|                                                                   |
|  MEMORY.md        Vector Memory         Knowledge Graph           |
|  (auto-loaded)    (queried on demand)   (queried on demand)       |
|  200 lines max    unlimited memories    entity relationships      |
|  per-project      global scope          global scope              |
|                                                                   |
+--------+-----------------+------------------+---------------------+
         |                 |                  |
         v                 v                  v
+------------------------------------------------------------------+
|                     AUTOMATIC CAPTURE                             |
|                                                                   |
|  observe-homunculus.sh    memory-nudge.sh    log-activity.sh      |
|  (captures tool usage)    (reminds to save)  (audit trail)        |
|                                                                   |
|  save-session.sh          file-guard.sh                           |
|  (archives transcripts)   (blocks secrets)                        |
|                                                                   |
+--------+-----------------+------------------+---------------------+
         |                 |                  |
         v                 v                  v
+------------------------------------------------------------------+
|                    OFFLINE PROCESSING                             |
|                                                                   |
|  /ingest-sessions         skill-extractor agent                   |
|  (archives -> memories)   (observations -> instincts)             |
|                                                                   |
|  session-analyzer agent   config-sync agent                       |
|  (pattern mining)         (cross-repo sync)                       |
|                                                                   |
+------------------------------------------------------------------+
```

## Layer 1: Vector Memory MCP Server

The foundation of the system is the **mcp-memory-service**, an open-source MCP server by Heinrich Krupp (Apache 2.0 license, v10.25.1). It runs as a local Python process communicating with Claude Code over stdio.

### How It Works

The server embeds text into 384-dimensional vectors using the `all-MiniLM-L6-v2` sentence transformer model. These vectors are stored alongside the original text in a SQLite database with the sqlite-vec extension. When you search, your query is also embedded, and the database returns the closest vectors by cosine similarity.

This is the key difference from MEMORY.md: **semantic search**. When you search for "deployment issues," it finds memories about "server configuration problems" because the vector representations are similar, even though the words are different. MEMORY.md can only find literal text matches. Vector memory understands meaning.

### Configuration

In `~/.claude.json`:

```json
{
  "mcpServers": {
    "vector-memory": {
      "type": "stdio",
      "command": "/opt/homebrew/bin/python3.11",
      "args": ["-m", "mcp_memory_service.server"],
      "env": {
        "MCP_MEMORY_STORAGE_BACKEND": "sqlite_vec"
      }
    }
  }
}
```

The server launches automatically when Claude Code starts and stays running for the duration of the session. First-call initialization takes about 5 seconds (loading the embedding model); subsequent calls complete in under 400ms thanks to global caching.

### Storage

The database lives at `~/Library/Application Support/mcp-memory/sqlite_vec.db` on macOS. All data stays local. Nothing leaves your machine. No API keys, no cloud services, no per-query charges.

### Capabilities

The memory service is more than a key-value store. It is a full knowledge management system with search, quality analysis, and self-maintenance built in.

**Embedding and Search**
- 384-dimensional vectors via the `all-MiniLM-L6-v2` sentence transformer, running in-process with PyTorch (no external API, no Ollama dependency)
- Hybrid search combining semantic similarity (70% weight) and full-text keyword matching (30% weight) for both conceptual and precise retrieval
- Maximal Marginal Relevance (MMR) with lambda 0.7 to suppress redundant results when multiple memories cover the same topic
- Temporal decay with a 30-day half-life so recent memories rank higher than stale ones
- Quality-aware reranking using a separate cross-encoder model (`ms-marco-MiniLM-L-6-v2`) to boost high-relevance results

**Storage and Integrity**
- SQLite with the sqlite-vec extension for vector indexing, stored at `~/Library/Application Support/mcp-memory/sqlite_vec.db`
- No content size limits (large content is auto-split into overlapping chunks of 1000 characters with 200-character overlap)
- Hash-based and semantic deduplication to prevent both exact and conceptually redundant entries
- Automated daily backups with 7-day retention (10 backups max)
- Integrity checks every 30 minutes to detect database corruption early
- WAL mode for safe concurrent reads during writes

**Knowledge Graph**
- Dual-write mode: memories are stored as both flat records and graph nodes with typed edges
- Association discovery links related memories automatically based on similarity thresholds
- Graph exploration via `memory_graph` to visualize how memories connect

**Quality System**
- AI-powered quality scoring classifies memories into retention tiers: critical (365 days), reference (180 days), standard (30-90 days), temporary (7 days)
- Quality distribution analysis via `memory_quality` to identify low-value memories for cleanup
- Consolidation engine with DBSCAN clustering to merge related memories, compress summaries, and archive originals

**Multi-Backend Support**
- Local-only via sqlite-vec (default, zero dependencies beyond Python)
- Cloudflare backend (D1 + Vectorize + R2) for cloud-hosted memory
- Hybrid mode syncing local and cloud for multi-machine setups
- Transport options: stdio (default for Claude Code), SSE, and HTTP REST API
- mDNS service discovery for LAN access

**Document Ingestion**
- Batch import from PDF (via LlamaParse), Markdown, and plain text files
- Chunking with configurable size and overlap preserves context boundaries

### The 12 Tools

The MCP server exposes 12 tools to Claude:

| Tool | Purpose |
|------|---------|
| `memory_store` | Save a memory with optional tags and metadata |
| `memory_search` | Semantic, keyword, or hybrid search |
| `memory_list` | Browse memories with pagination and filters |
| `memory_delete` | Remove memories (with dry-run safety) |
| `memory_update` | Update metadata without recomputing embeddings |
| `memory_cleanup` | Find and remove duplicate memories |
| `memory_health` | Database health check and statistics |
| `memory_stats` | Cache performance metrics |
| `memory_ingest` | Batch ingest documents (PDF, Markdown, text) |
| `memory_quality` | Rate and analyze memory quality distribution |
| `memory_consolidate` | Merge related memories (dream-inspired consolidation) |
| `memory_graph` | Explore connections between memories |

### Search Modes

The search system supports three modes:

**Semantic search** (default): Converts your query to a vector and finds the closest matches by meaning. Finds "deployment failures" when searching for "release problems."

**Exact search**: Traditional keyword matching via full-text search. Finds literal terms when you need precision over recall.

**Hybrid search** (recommended): Combines both. 70% weight to semantic similarity, 30% to keyword matching. This is the sweet spot: semantic search catches conceptual matches while keyword search catches exact terms that semantic might miss.

The hybrid configuration also applies:
- **MMR diversity** (lambda 0.7): Maximal Marginal Relevance reduces redundant results. If three memories say the same thing, only the best one surfaces.
- **Temporal decay** (30-day half-life): Recent memories rank higher than old ones. A memory from last week scores about 80% of its original relevance; a memory from three months ago scores about 12.5%. Stale information naturally fades.

### Memory Data Model

Each memory contains:

```
content       → The actual text (what was learned)
content_hash  → SHA256 hash for deduplication
tags          → Categorical labels (supports namespaces: proj:, topic:, t:)
memory_type   → Ontology type (note, fact, decision, observation, etc.)
metadata      → Arbitrary key-value pairs
embedding     → 384-dimensional vector
created_at    → When stored
updated_at    → When last modified
```

Deduplication happens at two levels: exact hash matching (prevents identical content) and semantic similarity (prevents conceptually redundant memories). This keeps the database clean without manual curation.

### What This Solves

| MEMORY.md Limitation | Vector Memory Solution |
|----------------------|------------------------|
| 200-line cap | Unlimited memories, searched on demand |
| No search | Semantic + keyword + hybrid search |
| No semantic understanding | Vector embeddings capture meaning |
| Single file, no organization | Tags, types, metadata, namespaces |
| Manual discipline required | Hooks and nudges automate capture |
| No cross-project memory | Global scope, works across all projects |
| No temporal awareness | 30-day half-life decay |

## Layer 2: The Knowledge Graph MCP

The knowledge graph (a separate MCP server, `@modelcontextprotocol/server-memory`) stores explicit relationships between named entities. While vector memory stores individual facts and insights, the knowledge graph models connections: which services depend on which, how data flows between systems, what role each team member plays.

```json
{
  "mcpServers": {
    "memory": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

Tools: `create_entities`, `create_relations`, `search_nodes`, `open_nodes`, `add_observations`, `delete_entities`, `delete_relations`.

Use the knowledge graph when you need to model connections, not for general facts. For example: "Service A calls Service B's `/auth` endpoint using JWT tokens" is a relationship. "JWT tokens expire after 15 minutes" is a fact that belongs in vector memory.

## Layer 3: The Hook System (Automatic Capture)

Hooks are shell scripts that execute automatically in response to Claude Code events. They are the backbone of the automatic capture pipeline. Without them, the entire system would depend on Claude (or the user) manually saving every piece of context. That manual approach fails in practice because sessions end abruptly, context gets lost during compaction, and humans forget.

Six hooks run in the current system:

### 1. observe-homunculus.sh (PostToolUse, async)

This hook fires after every tool call (Edit, Write, Bash, Read, Grep, Glob) and captures the tool name, input, and output as a JSONL entry in `~/.claude/homunculus/observations.jsonl`.

```bash
# Simplified flow:
tool_name → filter (only Edit, Write, Bash, Read, Grep, Glob)
         → extract session_id, tool_input, tool_output
         → truncate to 5000 chars per field
         → append JSONL to observations.jsonl
         → archive if file exceeds 10MB
```

**Why this matters:** These observations are the raw material for the Homunculus continuous learning system. Every tool call is a data point about how Claude is being used, what patterns emerge, and what mistakes recur. Without automatic capture, this data would not exist.

**What it captures:** Timestamp, session ID, tool name, input arguments, output results. It deliberately limits capture to core development tools (Edit, Write, Bash, Read, Grep, Glob), skipping MCP calls and internal tools to keep signal-to-noise high.

**Safety:** Can be disabled by creating `~/.claude/homunculus/disabled`. Automatically archives to `~/.claude/homunculus/observations.archive/` when the file exceeds 10MB.

### 2. memory-nudge.sh (PostToolUse)

This hook solves the "I forgot to save" problem. It tracks how many source code edits happen in a session without a corresponding `memory_store` call. After 5 edits, it injects a reminder into Claude's context:

```
MEMORY REMINDER: You have made 12 source file edits this session
without storing a vector memory. If you have completed any significant
tasks, bug fixes, or architectural decisions, store them now using
mcp__vector-memory__memory_store before continuing.
```

The nudge escalates: first at 5 edits, then at 15, 25, 35, and so on. It resets to zero when `memory_store` is called.

**Smart filtering:** Only counts edits to source code under known paths (`src/`, `lib/`, `app/`, `components/`, `hooks/`, etc.). Ignores config files, documentation, markdown, dotfiles, and lock files. This prevents false positives from routine non-source file changes.

**Opt-out:** Set `CLAUDE_MEMORY_NUDGE=false` in your environment.

**Why this matters:** Without this, important context routinely gets lost. A developer might fix a subtle bug, implement a complex feature, and then close the session without saving any of that context. The nudge makes forgetting opt-in rather than the default.

### 3. save-session.sh (SessionEnd)

When a session ends cleanly, this hook copies the full conversation transcript to `~/.claude/session_archive/` with a timestamped filename. It also creates a lightweight summary file and appends an entry to `index.txt`.

```
~/.claude/session_archive/
  2026-03-08_14-30-22_abc123.jsonl        # Full transcript
  2026-03-08_14-30-22_abc123_summary.txt  # Message type breakdown
  index.txt                                # Quick lookup index
```

**Why this matters:** Session archives are the raw material for the ingestion pipeline. Without them, the only way to capture session knowledge is manually during the session. With archives, you can process days or weeks of sessions in batch, extracting insights that were missed in the moment.

**Limitation:** Only fires on clean session exits. Hard kills (Ctrl+C, terminal close) skip the SessionEnd hook. This is why the memory-nudge hook exists: to push for continuous saving rather than relying on end-of-session capture.

### 4. log-activity.sh (PostToolUse, async)

Creates an `activity_log.txt` in the project root documenting every tool call with timestamp, session ID, and details. Rotates when the file exceeds 1000 lines.

```
[2026-03-08 14:32:15] (session123) Edit | Edited: /src/lib/api.ts
[2026-03-08 14:32:18] (session123) Bash | Ran: npm run build
[2026-03-08 14:32:22] (session123) Read | Used tool: Read
```

**Why this matters:** Provides an audit trail. When something breaks, you can trace exactly what Claude changed and when. When reviewing a session's work, you can quickly see the sequence of operations without parsing raw JSONL transcripts.

### 5. file-guard.sh (PreToolUse)

Blocks Edit and Write operations targeting sensitive files: `.env`, `.env.*`, `*.pem`, `*.key`, `credentials.json`, `*.secret`. Returns exit code 2 with a clear error message.

**Why this matters:** Prevents accidental exposure of secrets. Even with careful prompting, an AI assistant could inadvertently write a hardcoded API key into a tracked file. This hook makes that structurally impossible.

### 6. prompt-notify.sh (Stop)

Plays a system notification sound when Claude finishes its turn. Platform-aware: uses `osascript` on macOS, PulseAudio or ALSA on Linux.

**Why this matters:** When running long operations (agents, builds, tests), you don't have to watch the terminal. The sound tells you Claude is done and waiting for input.

## Layer 4: The Homunculus (Continuous Learning)

The Homunculus is a continuous learning system that extracts behavioral patterns from raw observations and session transcripts, then encodes them as **instincts**: structured markdown files that influence future behavior.

### The Pipeline

```
Tool Usage (Edit, Write, Bash, Read, Grep, Glob)
    |
    v
observe-homunculus.sh hook
    |
    v
observations.jsonl (raw JSONL, ~3000 lines, auto-archived at 10MB)
    |
    v
skill-extractor agent (Sonnet captain + Haiku readers)
    |
    v
Instinct Drafts (presented for user approval)
    |
    v
~/.claude/homunculus/instincts/personal/{id}.md (30 instincts currently)
```

### What Instincts Look Like

Each instinct is a markdown file with YAML frontmatter:

```markdown
---
id: bash-macos-arrays
trigger: "when using arrays in bash on macOS"
confidence: 0.4
domain: "platform"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Bash macOS Array Handling

## Action
Use `${arr[@]+"${arr[@]}"}` instead of `"${arr[@]}"` when `set -u`
is active. macOS ships bash 3.x which treats empty arrays as unbound.

## Pattern
1. Check if script uses `set -u` or `set -euo pipefail`
2. Replace bare array expansions with the `+` syntax
3. Test with both empty and non-empty arrays

## Evidence
- 2026-03-05: Script crashed with "unbound variable" on macOS
  despite working on Linux. Root cause: bash 3.x empty array behavior.
```

### Confidence Scoring

Instincts have confidence scores that reflect how well-established the pattern is:

| Score | Meaning | When Assigned |
|-------|---------|---------------|
| 0.3-0.4 | Observed once, might be coincidence | First extraction from single session |
| 0.5-0.6 | Clear pattern with solid cause-effect | Confirmed across evidence |
| 0.7-0.8 | Multiple independent evidence instances | Seen in different sessions |
| 0.9 | Extensively validated | Rarely assigned on first extraction |

Confidence increases when the same pattern is observed in multiple sessions or when the user explicitly confirms the behavior.

### The Skill Extractor Agent

The skill extractor is a **captain agent** that coordinates parallel reading of observations and archives. It uses the captain pattern because observation logs and session archives can exceed a single agent's context window.

**Workflow:**
1. **Inventory**: Read all existing instincts to build a deduplication reference
2. **Split**: Divide data sources across 2-4 parallel Explore agents (Haiku model)
3. **Extract**: Each reader searches for non-obvious fixes, platform quirks, integration gotchas, debugging techniques, and repeated corrections
4. **Deduplicate**: Cross-reader dedup, then against existing instincts and vector memory
5. **Score**: Assign confidence based on evidence strength
6. **Present**: Return drafts for user approval (the agent cannot write to instinct files due to sandbox restrictions)

### Current Instincts (30 total)

The system has extracted 30 instincts across domains:

- **Platform**: `bash-macos-arrays`, `headless-mac-pmset`, `obsidian-401-http`, `obsidian-cert-fallback`
- **Claude Code**: `memory-nudge-hook`, `two-tier-memory`, `python-mcp-memory`, `mcp-sdk-capabilities`
- **Integration**: `openclaw-doctor-revert`, `openclaw-memorysearch`, `openclaw-agents-nesting`, `telegram-polling-watchdog`
- **Development**: `parallel-scaffolding`, `mirror-existing-component-patterns`, `verify-data-contracts`, `nextjs-route-pages`
- **Operations**: `runaway-cpu-polling`, `deterministic-ids-polling`, `log-timestamp-anomalies`, `postToolUse-resilience`
- **Architecture**: `static-agent-metadata`, `alert-health-separation`, `alert-ux-ack`, `deep-link-admin-to-public`

### Evolution Path

When 3+ instincts cluster in the same domain, they can be promoted into higher-level constructs:
- **Learned skills** in `~/.claude/skills/learned/`
- **Custom commands** in `~/.claude/commands/`
- **Specialized agents** in `~/.claude/agents/`

This creates a natural progression: raw observations become instincts, instincts cluster into skills, skills formalize into reusable commands. The system gets smarter over time without manual curation.

## Layer 5: The Session Archive and Ingestion Pipeline

### Session Archives

Every clean session exit saves the full conversation transcript to `~/.claude/session_archive/` as a JSONL file. These archives contain everything: user messages, assistant responses, tool calls, tool results, errors, and timing data.

Archives serve three purposes:
1. **Audit trail**: Know exactly what happened in any past session
2. **Mining source**: The ingestion pipeline extracts insights you might have missed
3. **Training data**: Feed the skill extractor to discover behavioral patterns

### The /ingest-sessions Command

The `ingest-sessions` command is a seven-phase pipeline that processes archives into structured knowledge:

**Phase 1: Discover** - Scans all project directories and the Homunculus observation log for unprocessed archives.

**Phase 2: Deduplicate** - Queries vector memory for previously ingested sessions to avoid re-processing.

**Phase 3: Extract** - Launches 2-4 parallel Explore agents (Haiku) to read archives and extract five types of findings:
- Decisions made (architecture, library choices, pattern selections)
- Bugs resolved (error messages, root causes, fixes)
- Workarounds discovered (non-obvious solutions)
- Conventions established (naming, structure, workflow patterns)
- Gotchas encountered (unexpected difficulties)

**Phase 4: Deduplicate** - Cross-reader dedup, vector memory dedup, instinct dedup. Three layers of filtering to prevent redundant storage.

**Phase 5: Store** - Saves unique findings to vector memory with tags including `ingested-from-archive` for identification.

**Phase 6: Create Instincts** - Formats instinct candidates and presents them to the user for approval before writing.

**Phase 7: Report** - Summarizes the run: archives scanned, findings extracted, duplicates skipped, memories stored, instincts created.

**Why this matters:** Without ingestion, session knowledge only persists if you manually saved it during the session. With ingestion, you can run it weekly or after a series of complex sessions, and it will retroactively capture insights that were missed.

## The Memory Management Rules

The system is governed by a rules file (`~/.claude/rules/core/memory-management.md`) that defines exactly when and how each memory system should be used. This ensures Claude uses the right system for the right purpose and avoids duplication across systems.

### What Goes Where

| Information Type | System | Example |
|------------------|--------|---------|
| Build commands | MEMORY.md | `npm run dev` starts the server on port 3333 |
| Key file paths | MEMORY.md | Config is at `~/.openclaw/openclaw.json` |
| Bug resolution | Vector memory | "ECONNRESET on Telegram: root cause is ISP throttling, fix is retry with exponential backoff" |
| Architecture decision | Vector memory | "Chose sqlite-vec over pgvector because zero external dependencies" |
| Service dependency | Knowledge graph | "Service A calls Service B's /auth endpoint" |
| Tool usage pattern | Homunculus | Captured automatically by hooks |
| Full session transcript | Session archive | Captured automatically on session end |

### When to Save (Triggers)

Vector memory stores should happen after:
1. Completing a significant task (feature, bug fix, refactor)
2. Making an architectural decision (choosing a library, pattern, or approach)
3. Discovering a gotcha or workaround (something that took effort to figure out)
4. Resolving a bug (root cause, fix, and how it was found)
5. Encountering an error and fixing it (error message, cause, solution)

### Save During, Not After

The rules mandate saving continuously throughout the session rather than batching at the end. This is critical because:
- Hard kills skip the SessionEnd hook
- Context compaction can lose information
- Memory is freshest immediately after the event

The memory-nudge hook enforces this by alerting after 5+ source edits without a store.

## How It All Fits Together: A Complete Lifecycle

Here is a concrete example of the full system in action across multiple sessions.

### Session 1: Fix a Deployment Bug

1. **Session start**: MEMORY.md loads with project basics. Claude queries vector memory: "deployment" and finds a prior note about nginx config paths.

2. **Debugging**: Claude reads logs, traces the issue to a malformed environment variable. Hooks capture every Read, Grep, and Bash call to observations.jsonl.

3. **Fix applied**: Claude edits the config file. After 5 source edits, memory-nudge fires: "You have made 5 source file edits without storing a memory."

4. **Memory stored**: Claude calls `memory_store` with content "What: DEPLOY_URL must include protocol prefix (https://). Without it, nginx reverse proxy returns 502. Why: The config parser strips the URL to hostname only, and nginx needs the full URL for proxy_pass." Tags: `["deployment", "nginx", "bug-fix", "project-alpha"]`.

5. **Session end**: save-session.sh archives the full transcript. observe-homunculus.sh has already captured 47 tool calls to observations.jsonl.

### Session 2: Related Feature Work (Two Weeks Later)

1. **Session start**: MEMORY.md loads. Claude queries vector memory for the feature topic and finds the deployment bug fix from Session 1.

2. **Context applied**: Without re-debugging, Claude knows to include the protocol prefix when generating new deployment configs. The 30-day temporal decay still ranks this memory at about 65% relevance (two weeks old), which is more than enough to surface it.

3. **New memory stored**: The feature implementation reveals another gotcha, which is stored in vector memory.

### Offline: Ingestion Run

1. **/ingest-sessions** processes Session 1 and 2 transcripts.

2. **Extraction**: Parallel readers find the deployment bug fix (already in vector memory, skipped) and a new pattern: "always validate URL format before passing to nginx config" (not yet captured).

3. **Instinct created**: A new instinct `validate-url-format.md` with trigger "when generating deployment configuration" and confidence 0.4.

### Session 3: Different Project, Same Pattern

1. **Session start**: Different project, different MEMORY.md. But vector memory is global.

2. **Relevance**: When Claude encounters a similar deployment config task, `memory_search` finds the url-format instinct and the original bug fix, even though they were stored in the context of a different project.

3. **Pattern applied**: Claude validates the URL format proactively, avoiding the bug entirely.

This is the lifecycle: immediate capture, semantic retrieval, cross-project recall, automatic pattern extraction. Each session builds on the last.

## Why This Is Better Than Base Claude Code

### The Quantitative Case

| Capability | Base Claude Code | With Vector Memory System |
|------------|-----------------|---------------------------|
| Persistent storage | 200 lines, one file | Unlimited memories, structured database |
| Search | None (full text dump) | Semantic + keyword + hybrid |
| Cross-project memory | None | Global scope |
| Automatic capture | None | 5 hooks running continuously |
| Behavioral learning | None | 30 instincts and growing |
| Session archiving | None | Full transcript preservation |
| Memory reminders | None | Escalating nudge system |
| Secret protection | None | PreToolUse file guard |
| Temporal relevance | None | 30-day half-life decay |
| Deduplication | None | Hash-based + semantic |
| Batch analysis | None | 7-phase ingestion pipeline |
| Activity audit | None | Per-project activity log |

### The Qualitative Case

**Base Claude Code** treats every session as an isolated event. The developer is the sole carrier of context between sessions. Every explanation, every preference, every past decision must be re-communicated or Claude starts from zero.

**The vector memory system** makes Claude a genuine collaborator that accumulates knowledge. Past bug fixes inform current debugging. Architecture decisions persist with their reasoning. Platform quirks, discovered once, are never forgotten. The system gets more useful the longer you use it, rather than resetting daily.

The difference is most obvious in two scenarios:

1. **Long-running projects**: After a month of daily use, base Claude Code knows nothing about your project beyond 200 lines. The vector memory system has hundreds of tagged, searchable memories, dozens of behavioral instincts, and a complete archive of every session.

2. **Cross-project work**: Base Claude Code has zero knowledge transfer between projects. The vector memory system's global scope means a debugging technique learned in Project A is available in Project B. An instinct extracted from React work helps in the Next.js project.

## Installation

### Prerequisites

- Python 3.11+ (via Homebrew or system package manager)
- Claude Code CLI installed and working

### Step 1: Install the MCP Memory Service

```bash
pip install mcp-memory-service
```

This installs the server, the sqlite-vec extension, and the sentence-transformers embedding model.

### Step 2: Configure the MCP Server

Add to `~/.claude.json` under `mcpServers`:

```json
{
  "mcpServers": {
    "vector-memory": {
      "type": "stdio",
      "command": "python3",
      "args": ["-m", "mcp_memory_service.server"],
      "env": {
        "MCP_MEMORY_STORAGE_BACKEND": "sqlite_vec"
      }
    }
  }
}
```

Adjust the `command` path to your Python installation if needed (e.g., `/opt/homebrew/bin/python3.11`).

### Step 3: Add Memory Rules

Create `~/.claude/rules/core/memory-management.md` with rules defining when Claude should store to vector memory:

```markdown
# Memory Management

## When to Save to Vector Memory

Save after ANY of these events:
1. Completing a significant task (feature, bug fix, refactor)
2. Making an architectural decision
3. Discovering a gotcha or workaround
4. Resolving a bug (root cause + fix)
5. Encountering and fixing an error

Include in every memory: What (concise description), Why (reasoning), Tags (3-5 keywords including project name).

Save continuously during the session, not at the end.
```

### Step 4: Install the Memory Nudge Hook

Create `~/.claude/hooks/memory-nudge.sh` (see the full hook source in this document's Layer 3 section). Configure it in your Claude Code settings:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "command": "~/.claude/hooks/memory-nudge.sh",
        "timeout": 3000
      }
    ]
  }
}
```

### Step 5: Install the Session Archive Hook

Create `~/.claude/hooks/save-session.sh` and configure:

```json
{
  "hooks": {
    "Stop": [
      {
        "command": "~/.claude/hooks/save-session.sh"
      }
    ]
  }
}
```

### Step 6 (Optional): Install the Homunculus Observer

For behavioral learning, create `~/.claude/hooks/observe-homunculus.sh` and the directory structure:

```bash
mkdir -p ~/.claude/homunculus/instincts/personal
mkdir -p ~/.claude/homunculus/instincts/inherited
mkdir -p ~/.claude/homunculus/observations.archive
mkdir -p ~/.claude/homunculus/evolved/{agents,commands,skills}
```

### Step 7: Verify

Start a new Claude Code session and check:

```
# In Claude Code, ask:
"Check if vector memory is working by storing a test memory
and searching for it."
```

Claude should be able to call `memory_store` and `memory_search` without errors. The first call takes about 5 seconds while the embedding model loads. Subsequent calls complete in under a second.

## Performance Characteristics

| Operation | Latency | Notes |
|-----------|---------|-------|
| First tool call (cold start) | ~5 seconds | Loading embedding model |
| memory_store | 33-142ms | Embedding + SQLite write |
| memory_search | 570-700ms | Embedding + vector similarity + ranking |
| memory_list | 5-13ms | Simple database query |
| Cached subsequent calls | <400ms | Global cache eliminates model reload |

All operations run locally. No network calls, no API charges, no rate limits.

## Frequently Asked Questions

**Q: Does this replace MEMORY.md?**
No. MEMORY.md is still useful for stable, session-start facts (build commands, project structure, key file paths). Vector memory handles everything else: searchable, tagged, temporal, cross-project knowledge.

**Q: How much disk space does it use?**
The database is typically 1-5 MB for hundreds of memories. The embedding model is about 90 MB (downloaded once). Session archives are the largest component: a few GB after months of heavy use.

**Q: Can I export my memories?**
Yes. The `memory_list` tool returns all memories with pagination. The `memory_ingest` tool can import from markdown, text, PDF, and JSON. The server also exposes MCP resources for browsing (`memory://stats`, `memory://recent/10`, etc.).

**Q: What happens if the MCP server crashes?**
Claude Code continues working normally, just without vector memory access. MEMORY.md is unaffected. When the server recovers (next session start), all memories are intact in the SQLite database.

**Q: Is my data private?**
Completely. Everything runs locally: the embedding model, the database, the search. No data is sent to any external service. The database is a file on your disk that you fully control.

**Q: Can I use this with multiple machines?**
The SQLite database can be synced via any file sync tool (iCloud, Dropbox, rsync). The mcp-memory-service also supports a Cloudflare backend and a hybrid mode (local + cloud sync) for multi-machine setups.

**Q: How is this different from just putting everything in a big CLAUDE.md?**
Three critical differences: (1) CLAUDE.md has a practical size limit before it degrades Claude's attention, vector memory scales to thousands of entries searched on demand. (2) Vector memory does semantic search, CLAUDE.md is raw text injection. (3) Vector memory has automatic capture, tagging, temporal decay, and deduplication. CLAUDE.md requires manual maintenance of every line.
