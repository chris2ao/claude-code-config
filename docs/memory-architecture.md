# OpenClaw Memory Architecture

## Overview

OpenClaw uses a three-tier memory system that gives each agent persistent, searchable memory across sessions. Memory is stored as plain Markdown files on disk, indexed into SQLite for fast retrieval, and searched using a hybrid approach combining vector similarity (semantic meaning) with full-text search (keyword matching).

## Three Tiers of Memory

### 1. Session Memory (Ephemeral)

Conversation history for the current session. Cleared on restart or when issuing `/new`.

- Scope: Single session
- Lifetime: Until session ends
- Storage: In-memory only

### 2. Daily Logs (Short-Term)

Append-only daily notes stored as `memory/YYYY-MM-DD.md` in each agent's workspace. These capture session context and are automatically created by the `session-memory` hook when you run `/new` or `/reset`.

- Scope: Per-agent
- Lifetime: Persists on disk, decays in search ranking over 30 days
- Location: `~/.openclaw/workspace-{agent}/memory/YYYY-MM-DD.md`
- Created by: `session-memory` hook (bundled with OpenClaw)

### 3. Long-Term Memory (Curated)

A single `MEMORY.md` file per agent containing stable facts, decisions, preferences, and patterns. This is the agent's durable identity across sessions.

- Scope: Per-agent
- Lifetime: Permanent until manually edited
- Location: `~/.openclaw/workspace-{agent}/MEMORY.md`
- Maintained by: The agent itself (writes during sessions)

## Hybrid Search

Memory search combines two retrieval strategies for better results than either alone:

### Vector Search (Semantic)

Uses the `nomic-embed-text` embedding model running locally via Ollama to convert text into 768-dimensional vectors. When an agent searches memory, the query is also embedded, and the closest vectors (by cosine similarity) are returned. This finds relevant content even when the exact words don't match.

- Model: `nomic-embed-text` (274 MB, runs on Apple Silicon)
- Dimensions: 768
- Latency: ~78ms per query (warm), ~24ms per chunk in batch
- Cost: Free (fully local)
- Storage: sqlite-vec extension for SQLite

### Full-Text Search (Keyword)

Standard BM25 text search over the indexed content. Finds exact keyword matches and handles cases where semantic search might miss literal terms.

### How They Combine

The hybrid search configuration weights and merges both result sets:

```json
{
  "hybrid": {
    "vectorWeight": 0.7,
    "textWeight": 0.3,
    "candidateMultiplier": 4,
    "mmr": { "lambda": 0.7 },
    "temporalDecay": { "halfLifeDays": 30 }
  }
}
```

| Parameter | Value | Purpose |
|-----------|-------|---------|
| vectorWeight | 0.7 | 70% weight to semantic similarity |
| textWeight | 0.3 | 30% weight to keyword matching |
| candidateMultiplier | 4 | Retrieve 4x candidates before final ranking |
| mmr.lambda | 0.7 | Maximal Marginal Relevance to reduce redundant results |
| temporalDecay.halfLifeDays | 30 | Older memories lose half their score every 30 days |

## Architecture Diagram

```
Agent Session
    |
    v
[Query: "How did we configure security?"]
    |
    +---> nomic-embed-text (Ollama, local)
    |         |
    |         v
    |     [768-dim vector]
    |         |
    |         v
    |     sqlite-vec (vector similarity search)
    |         |
    |         +---> Top N semantic matches (weight: 0.7)
    |
    +---> SQLite FTS5 (keyword search)
              |
              +---> Top N keyword matches (weight: 0.3)
              |
              v
         [Reciprocal Rank Fusion]
              |
              v
         [MMR Diversity Filter]
              |
              v
         [Temporal Decay Reranking]
              |
              v
         Final ranked results
```

## Configuration

Memory search is configured in `~/.openclaw/openclaw.json` under `agents.defaults`:

```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "mode": "safeguard"
      },
      "memorySearch": {
        "provider": "ollama",
        "model": "nomic-embed-text",
        "query": {
          "hybrid": {
            "vectorWeight": 0.7,
            "textWeight": 0.3,
            "candidateMultiplier": 4,
            "mmr": { "lambda": 0.7 },
            "temporalDecay": { "halfLifeDays": 30 }
          }
        }
      }
    }
  }
}
```

### Supporting Hooks

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "session-memory": { "enabled": true }
      }
    }
  }
}
```

The `session-memory` hook triggers on `/new` and `/reset`, extracting the last ~15 messages and saving them as a daily log file with a descriptive filename.

## Per-Agent Memory Storage

Each agent has isolated memory:

```
~/.openclaw/workspace-{agent}/
  MEMORY.md                     # Long-term curated memory
  memory/
    2026-03-05.md               # Daily log
    2026-03-06.md               # Daily log

~/.openclaw/memory/
  {agentId}.sqlite              # Search index (FTS + vectors)
```

## Advantages

### Fully Local, Zero API Cost

The embedding model (nomic-embed-text) runs entirely on the M4 Mac Mini via Ollama. No data leaves the machine. No per-query API charges. The 274 MB model produces embeddings in under 100ms.

### Semantic Understanding

Vector search finds relevant memories even when the words don't match. Searching for "deployment issues" can surface a note about "server configuration problems" because the meanings are similar. This is a major improvement over keyword-only search.

### Temporal Decay

Recent memories naturally rank higher than old ones. The 30-day half-life means a memory from last week scores ~80% of its original relevance, while a memory from three months ago scores ~12.5%. This prevents stale information from crowding out current context.

### Redundancy Reduction

Maximal Marginal Relevance (MMR) ensures search results are diverse. If three chunks say the same thing, only the most relevant one surfaces. This saves context window space.

### Per-Agent Isolation

Each agent has its own memory files and search index. The security agent's audit notes don't pollute the writer's creative memory. Each agent builds domain expertise over time in its own workspace.

### Safeguard Compaction

When sessions get long and approach context limits, safeguard compaction summarizes earlier messages while preserving tool results and file operations. The session-memory hook ensures critical context is written to disk before compaction happens.

### Survives Restarts

All three tiers are designed for durability. Daily logs and MEMORY.md persist on disk. The SQLite index rebuilds automatically. An agent can pick up where it left off across sessions, days, or weeks.

## CLI Commands

```bash
# Check memory status for all agents
openclaw memory status

# Force reindex all memory files
openclaw memory index --force

# Search memory (from an agent session)
openclaw memory search --query "security audit results"

# Machine-readable status
openclaw memory status --json
```

## Best Practices

- **Keep MEMORY.md concise.** Store stable facts, decisions, and preferences. Not a diary.
- **Let daily logs capture session context.** They auto-decay via temporal weighting.
- **Run `/new` between major topics.** This triggers the session-memory hook and flushes context to disk.
- **Monitor long sessions.** Safeguard compaction can have issues around ~180k tokens. Issue `/new` proactively.
- **Reindex after config changes.** Run `openclaw memory index --force` after modifying memory settings.

## Dependencies

| Component | Version | Purpose |
|-----------|---------|---------|
| Ollama | Latest | Hosts the embedding model locally |
| nomic-embed-text | latest (274 MB) | Produces 768-dim text embeddings |
| sqlite-vec | Bundled with OpenClaw | Vector similarity search in SQLite |
| SQLite FTS5 | Bundled | Full-text keyword search |
