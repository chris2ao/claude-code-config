# Ingest Session Archives

Process session archive transcripts to extract valuable context and store it in vector memory and Homunculus instincts. This command handles the full pipeline: discovery, analysis, deduplication, and storage.

## Arguments

- `$ARGUMENTS` (optional): path to a specific session archive directory or "all" to scan all projects. Defaults to scanning all known project directories.

## Workflow

### Phase 1: Discover Archives

Scan for session archives across all projects:

```bash
# Check all known project locations (macOS paths)
for dir in \
  "$HOME/GitProjects/*/." \
  "$HOME/GitProjects/*/.claude/session_archive" \
  "$HOME/.claude/session_archive" \
  ; do
  if [ -d "$dir" ]; then
    echo "$dir"
    ls "$dir"/*.jsonl 2>/dev/null | wc -l
  fi
done
```

Also check the Homunculus observation log:

```bash
wc -l ~/.claude/homunculus/observations.jsonl 2>/dev/null
ls ~/.claude/homunculus/observations.archive/*.jsonl 2>/dev/null
```

Report the total number of archive files and observation lines found.

### Phase 2: Check What Has Already Been Ingested

Before processing, check vector memory for previously ingested sessions to avoid duplicates:

Use `memory_search` with query "session ingestion" and tags ["ingestion-log"] to find records of prior runs. Track session IDs that have already been processed.

### Phase 3: Extract Insights (Parallel Agents)

Launch parallel Explore agents (haiku model) to read the archives. Split files across 2-4 agents depending on volume.

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
