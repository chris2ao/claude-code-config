---
platform: portable
description: "Refine existing skills/agents/commands/instincts based on evidence from recent session logs"
---

# /refine - Evidence-Based Component Refinement

Read recent session transcripts, propose edits to existing Claude Code components (skills, agents, commands, instincts), and apply the edits you approve. Complements `/evolve` (which promotes net-new patterns) and `/ingest-sessions` (which writes findings to vector memory).

## Arguments

`$ARGUMENTS` can be:
- `queue` — only process candidates queued by a prior `/ingest-sessions` run (fast path)
- `scan` — ignore the queue, scan sessions since `~/.claude/.last-refine-timestamp` for candidates
- `both` (default) — consume the queue AND scan for missed candidates
- `--max N` — cap total proposals surfaced (default 30)
- `--dry-run` — produce proposals and show the review table; never apply edits

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

## Phase 2: Spawn Refine Captain

Use the Task tool with:
- `subagent_type`: `general-purpose`
- `model`: `sonnet`
- `name`: `refine-captain`

Pass:
- The chosen `mode` (queue-only, full-scan, or both)
- `queue_path`: `~/.claude/state/refine-queue.jsonl`
- `since_timestamp`: mtime of `.last-refine-timestamp` (or epoch-0 if missing)
- `max_proposals`: from `--max` or default 30
- `dry_run`: boolean
- Instruction: "You are the Refine Captain. Follow the instructions in ~/.claude/agents/refine-captain.md exactly."

## Phase 3: Present Captain's Report

The captain returns a JSON report. Display to the user:
- Proposals presented / applied / rejected
- Components touched (list paths)
- Snapshot directory (for rollback reference)
- Audit log path

If components were edited, remind the user to run `/claude-config-sync` to propagate to the `claude-code-config` repo.

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
