# /memory-audit - Vector Memory Audit

Scan vector memory for contradictions, stale superseded entries, and duplicate clusters. Present findings for review and optional cleanup.

## Workflow

### Step 1: Gather Memory Inventory

Search vector memory across key project tags to build an inventory:

```
Run these searches in parallel:
1. memory_search("CJClaudin_Mac", limit=50)
2. memory_search("claude-code configuration", limit=30)
3. memory_search("architecture decision", limit=30)
4. memory_search("bug fix resolution", limit=30)
5. memory_search("superseded", limit=50)
```

Collect all unique memories with their hashes, content, tags, and timestamps.

### Step 2: Detect Contradictions

Group memories by topic (using tag overlap and semantic similarity). For each group:

1. Compare factual claims between memories in the same group
2. Flag pairs where one memory states X and another states NOT-X or a different value for the same entity/config
3. Examples of contradictions:
   - "Port 8765" vs "Port 8766" for the same service
   - "Uses sqlite-vec" vs "Uses ChromaDB" for the same system
   - "Feature X is enabled" vs "Feature X is disabled"

### Step 3: Find Stale Superseded Entries

Search for memories tagged "superseded":
1. Check if the superseding memory (referenced by hash) still exists
2. If the superseded memory is older than 90 days, mark as deletion candidate
3. If the superseding memory was itself superseded, flag the chain

### Step 4: Identify Duplicate Clusters

Look for memories with:
1. Very similar content (same topic, same facts, different wording)
2. Same tags but stored at different times
3. Candidates for merging into a single, more complete memory

### Step 5: Present Report

Format findings as a structured report:

```markdown
## Memory Audit Report
*Date: [today] | Total memories scanned: [N]*

### Contradictions Found: [N]
| Memory A (hash) | Memory B (hash) | Conflict |
|----------------|----------------|----------|
| [summary] | [summary] | [what conflicts] |

### Stale Superseded Entries: [N]
| Hash | Content Preview | Superseded On | Age |
|------|----------------|---------------|-----|

### Duplicate Clusters: [N]
| Cluster | Memories | Recommendation |
|---------|----------|---------------|
| [topic] | [hashes] | Merge / Keep both |

### Recommended Actions
1. [Delete stale entry X]
2. [Merge duplicates Y and Z]
3. [Resolve contradiction between A and B]
```

### Step 6: Execute Cleanup (With Confirmation)

For each recommended action, ask the user before proceeding:
- **Delete**: Use `memory_delete` to remove stale entries
- **Merge**: Store a combined memory, then delete the originals
- **Resolve contradiction**: Ask which version is correct, supersede the wrong one

Never delete or modify memories without explicit user approval.
