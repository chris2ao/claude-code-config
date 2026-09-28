---
platform: portable
description: "Refine existing skills/agents/commands/instincts based on evidence from recent session logs"
---

# /refine - Evidence-Based Component Refinement

Read recent session transcripts, propose edits to existing Claude Code components (skills, agents, commands, instincts), and apply the edits you approve. Complements `/evolve` (which promotes net-new patterns) and `/ingest-sessions` (which writes findings to vector memory).

## Arguments

`$ARGUMENTS` can be:
- `queue`: only process candidates queued by a prior `/ingest-sessions` run (fast path)
- `scan`: ignore the queue, scan sessions since `~/.claude/.last-refine-timestamp` for candidates
- `both` (default): consume the queue AND scan for missed candidates
- `--max N`: cap total proposals surfaced (default 30)
- `--dry-run`: produce proposals and show the review table; never apply edits

## Phase 1: Prep

```bash
QUEUE="$HOME/.claude/state/refine-queue.jsonl"
MARKER="$HOME/.claude/.last-refine-timestamp"
mkdir -p "$HOME/.claude/state/refine-snapshots" "$HOME/.claude/state/refine-history"
touch "$QUEUE"
```

Determine mode from arguments. Default: `both`.

Report pre-run state:
- Queue size: `wc -l "$QUEUE"`
- Last refine: `stat -f %Sm "$MARKER" 2>/dev/null || echo "never"`
- New sessions since marker: `find ~/.claude/session_archive -name '*.jsonl' -newer "$MARKER" 2>/dev/null | wc -l`

If queue empty AND no new sessions, exit early with "Nothing to refine."

## Phase 2: Gather and Fan Out (main conversation)

The main conversation runs the whole refine loop itself. The old refine-captain subagent could not do it, because `AskUserQuestion` is removed from subagents, so the captain's approval loop never worked as designed.

1. **Load the queue.** Read `refine-queue.jsonl`. Each line looks like `{"component_hint", "finding_summary", "session_id", "session_date", "excerpt"}`. Group the lines by `component_hint`.
2. **Inventory components.**
   - Enumerate `.md` files under `~/.claude/{agents,skills,commands}/` and `~/.claude/homunculus/instincts/personal/`.
   - Load `~/.claude/.refine-ignore`. Drop every path matching a `BLOCK:` pattern, and flag every path matching a `WARN:` pattern.
3. **Inventory transcripts.**
   ```bash
   find "$HOME/.claude/session_archive" -name "*.jsonl" -newer "$MARKER" 2>/dev/null
   ```
   In queue-only mode, keep only the transcripts that queue entries reference.
4. **Slice.** Split the work into 3-4 slices: components by directory or alphabetically, transcripts chronologically, and the queue entries that match each slice's components.
5. **Fan out readers.** In a single message, launch 3-4 Agent calls with `subagent_type: refine-reader`, with no `name`. Each gets its slice as `{transcripts, components, priority_queue, mode}`. Every reader returns a JSON array of proposals, in the schema from `~/.claude/agents/refine-reader.md`.
6. **Consolidate** in the main conversation:
   - Merge all the arrays.
   - Dedupe across readers: when two proposals target the same component with a similar summary, keep the higher-confidence one and merge their evidence.
   - Sort by confidence, then cap at `max_proposals` (from `--max`, default 30).

## Phase 3: Approve and Apply (main conversation)

1. **Present** a table:

   | # | Conf | Type | Component | Summary |
   |---|------|------|-----------|---------|
   | 1 | 0.82 | gotcha-addition | skills/foo/SKILL.md | Add warning about 401 retry loop |

   Accept any of:
   - comma-separated numbers (`1,3,5`)
   - `all`
   - `hi` (confidence >= 0.7 only)
   - `show N` (full evidence and a diff preview)
   - `reject N: <reason>`
   - `quit`

   Loop until the user applies or quits. With `--dry-run`, stop after showing the table.
2. **Apply** each approved proposal:
   1. `bash ~/.claude/scripts/refine-snapshot.sh <component_path>`, and record the snapshot dir.
   2. If the path is a WARN path, get a second confirmation for this specific edit.
   3. Apply the edit with the Edit tool:
      - `replace`: `old_text` becomes `new_text`
      - `insert-after`: `anchor` becomes `anchor + "\n\n" + new_text`
      - `append` or `prepend`: read the file and add the text at the end or start
   4. Re-read or grep to verify the edit landed. If it didn't, restore the file from the snapshot and log the proposal as a rejection.
3. **Audit log.** Append one line per proposal to `~/.claude/state/refine-history/<ISO_TIMESTAMP>.jsonl`:
   `{"proposal_id", "status": "applied|rejected-user|rejected-no-evidence|rejected-ignore", "component_path", "snapshot_dir", "rejection_reason", "applied_at"}`
4. **Drain the queue.** If the queue was consumed, copy it to `refine-history/<ISO_TIMESTAMP>.queue-drained.jsonl` and truncate `refine-queue.jsonl`.
5. **Report:**
   - proposals presented, applied, and rejected
   - the components touched
   - the snapshot dir
   - the audit log path
   If any files were edited, add: "run `/claude-config-sync` to propagate to the `claude-code-config` repo."

### Safety Rules (absolute)

- Never apply an edit without explicit user approval for that proposal or its batch.
- Never edit a `BLOCK:` path. `WARN:` paths need a second confirmation for each edit.
- If an edit fails verification, roll it back from the snapshot and log a rejection.
- Never commit or push. Edits stay in `~/.claude/`, and `/claude-config-sync` propagates them.
- Preserve YAML frontmatter. Never edit inside the `---` blocks.
- If a proposal's `anchor` is not unique in the file, downgrade it to `append` or reject it.

## Phase 4: Vector memory breadcrumb

Call `mcp__vector-memory__memory_store` with a short summary of the run (for future `/memory-audit` cross-reference):

- content: "/refine run: N proposals, M applied across K components. Mode: <mode>. Key themes: [list]"
- tags: `refine-log, meta, [YYYY-MM-DD]`
- type: `refine-log`

If the MCP call fails, log and continue.

## Phase 5: Touch marker

```bash
touch "$MARKER"
```

## Rollback

Every applied edit is snapshotted to `~/.claude/state/refine-snapshots/<timestamp>/`. To roll back:

```bash
# find the snapshot for the run
ls -la ~/.claude/state/refine-snapshots/ | tail -5
# copy files back
cp -r ~/.claude/state/refine-snapshots/<ts>/.claude/<path>/... ~/.claude/<path>/...
```

Audit logs at `~/.claude/state/refine-history/` show which proposals were applied/rejected for each run.

## Relationship to Other Commands

| Command | What it does | When it writes |
|---------|-------------|----------------|
| `/ingest-sessions` | Extracts findings from transcripts to vector memory; queues refine candidates | After each ingestion run |
| `/refine` | Proposes and applies edits to existing components based on queue + transcripts | On explicit run |
| `/evolve` | Clusters instincts into NEW agents/skills/commands | On explicit run |
| `/memory-audit` | Dedups and supersedes vector memory entries | On explicit run |

The flow: sessions → ingest (vector memory + refine queue) → refine (edits components) → evolve (new components from instinct clusters) → sync (propagate to repo).
