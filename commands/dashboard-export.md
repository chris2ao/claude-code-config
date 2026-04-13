# /dashboard-export - Export Environment Data for SNES Dashboard

Exports the full Claude Code environment (Knowledge Graph, vector memory, instincts, hooks, metrics, sessions) to JSON files in the cryptoflexllc repo, then commits and pushes to trigger a Vercel rebuild.

## Arguments

- `--dry-run` (optional): Export JSON files but do not commit or push.
- `--no-push` (optional): Export and commit but do not push.

## Workflow

### Step 1: Verify Target Repo

```bash
CRYPTO_REPO="$HOME/GitProjects/cryptoflexllc"
DATA_DIR="$CRYPTO_REPO/src/data/dashboard"
if [ ! -d "$DATA_DIR" ]; then
  echo "ERROR: Dashboard data directory not found at $DATA_DIR"
  echo "Create it first: mkdir -p $DATA_DIR"
  exit 1
fi
echo "Target: $DATA_DIR"
```

### Step 2: Export Knowledge Graph

Use `mcp__memory__read_graph` to get all entities and relations.

Process the output:
1. Extract entities: for each entity, create an object with `name`, `type` (entityType), and `observations` (array of strings)
2. Extract relations: for each relation, create an object with `from`, `to`, `type` (relationType)
3. **Path scrubbing**: Replace all occurrences of the home directory path (e.g., `/Users/chris2ao/`) with `~/` in observations
4. **Sensitive data filter**: Remove any observation that contains "API_KEY=", "TOKEN=", "PASSWORD=", or "SECRET=" followed by an actual value (keep the variable name, strip the value)

Write to:
- `$DATA_DIR/kg-entities.json`
- `$DATA_DIR/kg-relations.json`

### Step 3: Export Vector Memory Summary

Use `mcp__vector-memory__memory_stats` (if available) or `mcp__vector-memory__memory_search` with a broad query to get counts.

Create a summary object:
```json
{
  "totalCount": <number>,
  "recentTags": [<top 10 most common tags>],
  "byType": { "note": N, "decision": N, "gotcha": N, ... }
}
```

Write to: `$DATA_DIR/vector-memories.json`

### Step 4: Export Instincts

Parse all markdown files in `~/.claude/homunculus/instincts/personal/`:

```bash
for f in ~/.claude/homunculus/instincts/personal/*.md; do
  # Extract YAML frontmatter fields: id, trigger, confidence, domain, created
done
```

Create an array of instinct objects with: `id`, `trigger`, `confidence`, `domain`, `created`.

Write to: `$DATA_DIR/instincts.json`

### Step 5: Export Hooks Configuration

Read `~/.claude/settings.json` and extract the `hooks` section. Transform into a structured format grouped by hook type (PreToolUse, PostToolUse, Stop, SessionEnd, UserPromptSubmit), with each hook showing: matcher, script name, description, timeout.

**Path scrubbing**: Replace home directory paths with `~/`.

Write to: `$DATA_DIR/hooks.json`

### Step 6: Export Observations Summary

Process `~/.claude/homunculus/observations.jsonl`:
- Count total lines
- Count by tool type (top 15)
- Get latest timestamp

```bash
python3 -c "
import json, collections
counts = collections.Counter()
total = 0
latest = ''
with open('$HOME/.claude/homunculus/observations.jsonl') as f:
    for line in f:
        total += 1
        try:
            obj = json.loads(line)
            counts[obj.get('tool','unknown')] += 1
            ts = obj.get('timestamp','')
            if ts > latest: latest = ts
        except: pass
print(json.dumps({'totalCount':total, 'byTool':dict(counts.most_common(15)), 'latestTimestamp':latest}))
"
```

Write to: `$DATA_DIR/observations-summary.json`

### Step 7: Export Gmail Metrics

Read `~/.cache/gmail-assistant/run-metrics.jsonl` (if it exists). Parse each line as JSON. Include all fields.

Write to: `$DATA_DIR/metrics.json`

### Step 8: Export Session Archive Metadata

List files in `~/.claude/session_archive/*.jsonl`. For each file, extract: session ID (from filename), date, time, file size.

Write to: `$DATA_DIR/sessions.json`

### Step 9: Export MEMORY.md Index

Read MEMORY.md files from `~/.claude/projects/*/memory/MEMORY.md`. For each, extract: project name (from directory path), line count, key topic headings.

Write to: `$DATA_DIR/memory-index.json`

### Step 10: Write Metadata

```json
{
  "lastUpdated": "<ISO timestamp>",
  "exportVersion": <incremented>,
  "entityCount": <from step 2>,
  "relationCount": <from step 2>,
  "instinctCount": <from step 4>,
  "observationCount": <from step 6>,
  "memoryCount": <from step 3>
}
```

Write to: `$DATA_DIR/metadata.json`

### Step 11: Commit and Push (unless --dry-run)

```bash
cd "$CRYPTO_REPO"
git add src/data/dashboard/
git diff --cached --stat

# Only commit if there are changes
if git diff --cached --quiet; then
  echo "No changes to dashboard data. Skipping commit."
else
  git commit -m "chore: update dashboard data export

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
  
  # Push unless --no-push
  git push
  echo "Dashboard data exported and pushed. Vercel will rebuild in ~60s."
fi
```

### Step 12: Report

```
## Dashboard Export Complete

- Entities: N
- Relations: N
- Instincts: N
- Observations: N
- Memories: ~N
- Metrics entries: N
- Sessions: N
- Data written to: src/data/dashboard/ (10 files)
- Committed: yes/no
- Pushed: yes/no
```
