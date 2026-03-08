---
id: vector-memory-config
trigger: "when configuring vector memory systems"
confidence: 0.4
domain: "memory"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Vector Memory Hybrid Search Configuration

## Action
Set vectorWeight 0.7 for semantic dominance, textWeight 0.3 for keyword fallback, MMR lambda 0.7 for diversity, temporalDecay halfLifeDays 30.

## Pattern
1. Semantic search dominates (0.7) for conceptual matching
2. Keyword search (0.3) catches exact terms semantic might miss
3. MMR diversity (0.7) prevents returning near-duplicate results
4. Temporal decay (30-day half-life) prioritizes recent memories

## Evidence
- 2026-03-06: Configured for Ollama-based hybrid search with nomic-embed-text embeddings. Balanced retrieval quality across semantic and keyword dimensions.
