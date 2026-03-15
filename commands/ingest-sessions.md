---
platform: portable
---

# Ingest Session Archives

Process session archive transcripts to extract valuable context and store it in vector memory and Homunculus instincts. This command handles the full pipeline: discovery, analysis, deduplication, and storage.

## Arguments

- `$ARGUMENTS` (optional): path to a specific session archive directory or "all" to scan all projects. Defaults to scanning all known project directories.

## Workflow

### Phase 1: Discover Archives

Dynamically find all session archive directories. Do NOT use hardcoded paths.

**Step 1: Detect platform and project root.**

```bash
# Detect platform and set project root
if [[ "$OSTYPE" == darwin* ]]; then
  PROJECT_ROOT="$HOME/GitProjects"
elif [[ -d "/c/ClaudeProjects" ]]; then
  PROJECT_ROOT="/c/ClaudeProjects"
else
  PROJECT_ROOT="$HOME/projects"
fi
echo "Platform: $OSTYPE | Project root: $PROJECT_ROOT"
```

**Step 2: Dynamically find all session_archive directories.**

Search the project root AND the global `~/.claude/` for any directory named `session_archive` containing `.jsonl` files. Also check the current working directory.

```bash
echo "=== Session Archive Locations ==="
# Dynamic discovery: find all session_archive dirs under project root and ~/.claude
for archive_dir in \
  $(find "$PROJECT_ROOT" -maxdepth 4 -type d -name "session_archive" 2>/dev/null) \
  "$HOME/.claude/session_archive" \
  "$(pwd)/.claude/session_archive" \
  ; do
  if [ -d "$archive_dir" ]; then
    count=$(ls "$archive_dir"/*.jsonl 2>/dev/null | wc -l)
    if [ "$count" -gt 0 ]; then
      echo "$archive_dir: $count files"
    fi
  fi
done
```

**Step 3: Check Homunculus observation log.**

```bash
wc -l ~/.claude/homunculus/observations.jsonl 2>/dev/null || echo "No observations.jsonl"
ls ~/.claude/homunculus/observations.archive/*.jsonl 2>/dev/null || echo "No archived observations"
```

Report the total number of archive locations, files, and observation lines found.

If `$ARGUMENTS` is a specific path, use only that path instead of scanning.

### Phase 1b: Deduplicate Archive Snapshots

Session archives often contain multiple incremental snapshots of the same session (same UUID, different timestamps). Before processing, deduplicate to keep only the **largest file per session UUID** (largest = most complete).

Archive filenames follow the pattern: `YYYY-MM-DD_HH-MM-SS_<UUID>.jsonl`

```bash
# Extract UUID from filename, keep only the largest file per UUID
# Output: one line per unique session with date, UUID, size, and path
ls -la <archive_dir>/*.jsonl | awk '{
  path=$NF; n=split(path,p,"/"); fn=p[n]
  uuid=substr(fn,21); sub(/\.jsonl$/,"",uuid)
  size=$5+0
  if (size > max[uuid]) { max[uuid]=size; best[uuid]=path; date[uuid]=substr(fn,1,10) }
} END { for (u in best) print date[u], u, max[u], best[u] }' | sort
```

Skip files smaller than 5KB (likely empty or trivially short sessions).

### Phase 2: Check What Has Already Been Ingested

Before processing, check vector memory for previously ingested sessions to avoid duplicates:

Use `memory_search` with query "session ingestion" and tags ["ingestion-log"] to find records of prior runs. Compare the ingestion log date against archive file dates. Only process sessions newer than the last ingestion date.

### Phase 3: Extract Insights (Parallel Agents)

Launch parallel Explore agents (haiku model) to read the deduplicated archives. Split files across 2-4 agents depending on volume. For files over 1MB, instruct agents to use `head -500` and `tail -200` to sample the beginning and end.

Each reader agent should extract:

1. **Decisions made**: architectural choices, library selections, pattern decisions (with reasoning)
2. **Bugs resolved**: error messages, root causes, fixes applied
3. **Workarounds discovered**: non-obvious solutions to platform or tooling issues
4. **Conventions established**: naming patterns, file structures, workflows adopted
5. **Gotchas encountered**: things that were harder than expected or failed unexpectedly

For each finding, the reader should return:
- **type**: decision | bug-fix | workaround | convention | gotcha
- **what**: concise description
- **why**: reasoning or root cause
- **tags**: relevant keywords (project name, technology, domain)
- **session_date**: from the archive filename
- **instinct_candidate**: true/false (is this a behavioral pattern worth making an instinct?)
- **instinct_trigger**: if candidate, "when [situation]"
- **instinct_action**: if candidate, what to do

### Phase 4: Deduplicate

After readers return:

1. **Cross-reader dedup**: merge duplicate findings from different readers
2. **Vector memory dedup**: search vector memory for each finding. If a similar memory already exists, skip it or update it with new evidence.
3. **Instinct dedup**: check existing instincts in `~/.claude/homunculus/instincts/personal/` and skip patterns already captured.

### Phase 5: Store to Vector Memory

For each unique finding, call `memory_store` with:
- Content: "What: {what}\nWhy: {why}"
- Tags: the extracted tags plus "ingested-from-archive"
- Metadata: session date, source file

After all stores complete, save an ingestion log entry:
- Content: "Session ingestion run: processed N archives, stored M memories, created K instincts"
- Tags: ["ingestion-log", "meta"]

### Phase 6: Create Instinct Drafts

For findings marked as instinct candidates:

1. Format as instinct markdown files with YAML frontmatter
2. Present to user for review (list each with trigger and action)
3. On approval, write to `~/.claude/homunculus/instincts/personal/{id}.md`

Use confidence scoring:
- 0.3-0.4: single evidence from one session
- 0.5-0.6: clear pattern with solid cause-effect
- 0.7-0.8: seen across multiple sessions
- 0.9: extensive cross-session evidence

### Phase 7: Report

Output a summary:

```
## Ingestion Report

- Archives scanned: N
- Total findings extracted: N
- Duplicates skipped: N (already in vector memory)
- New memories stored: N
- Instinct candidates found: N
- Instincts created: N (after user approval)
- Domains covered: [list]
```

## Important Notes

- Always deduplicate before storing. Duplicate memories degrade search quality.
- Include "ingested-from-archive" tag on all memories created by this command so they can be identified later.
- Present instinct drafts for user approval before writing files.
- If the vector-memory MCP is not available, report the error and offer to output findings as a markdown file instead.
- Session archives from hard kills may be incomplete. Process what is available without erroring on truncated files.
