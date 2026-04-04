---
platform: portable
description: "Cluster instincts into evolved agents, skills, and commands"
---

# /evolve - Homunculus Evolution

Analyzes Homunculus instincts, clusters them semantically, and generates evolved Claude Code components (agents, skills, commands).

## Arguments

`$ARGUMENTS` can be:
- `full` - Analyze all instincts regardless of when they were created
- `incremental` - Only analyze instincts created since the last evolution run
- (empty) - Defaults to `incremental` if `~/.claude/homunculus/.last-evolve-timestamp` exists, otherwise `full`

## Phase 1: Gather Instincts

Determine the mode:

```bash
EVOLVE_MARKER="$HOME/.claude/homunculus/.last-evolve-timestamp"
if [ -f "$EVOLVE_MARKER" ]; then
    echo "MODE: incremental (marker exists)"
    echo "MARKER_DATE: $(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$EVOLVE_MARKER")"
else
    echo "MODE: full (no marker)"
fi
```

Count instinct files:

```bash
TOTAL=$(ls "$HOME/.claude/homunculus/instincts/personal"/*.md 2>/dev/null | wc -l | tr -d ' ')
echo "TOTAL_INSTINCTS: $TOTAL"
```

For incremental mode, count only new instincts:

```bash
EVOLVE_MARKER="$HOME/.claude/homunculus/.last-evolve-timestamp"
if [ -f "$EVOLVE_MARKER" ]; then
    NEW=$(find "$HOME/.claude/homunculus/instincts/personal" -name "*.md" -newer "$EVOLVE_MARKER" 2>/dev/null | wc -l | tr -d ' ')
    echo "NEW_INSTINCTS: $NEW"
fi
```

If incremental mode finds 0 new instincts:
- Report: "No new instincts since last evolution run (marker: [date]). Use `/evolve full` to re-analyze all instincts."
- Exit without touching the timestamp.

If total instincts is 0:
- Report: "No instincts found. Run `/ingest-sessions` to extract instincts from session archives."
- Exit.

## Phase 2: Inventory Existing Evolved Components

Check what already exists in the evolved directory (for dedup):

```bash
find "$HOME/.claude/homunculus/evolved" -name "*.md" ! -name ".gitkeep" 2>/dev/null
```

## Phase 3: Read Identity

```bash
cat "$HOME/.claude/homunculus/identity.json" 2>/dev/null
```

## Phase 4: Spawn Synthesizer Agent

Launch a Task agent:
- **subagent_type:** general-purpose
- **model:** sonnet
- **name:** evolve-synthesizer

Pass to the agent:
1. Instruction: "Follow the instructions in `~/.claude/agents/evolve-synthesizer.md`"
2. Mode: full or incremental
3. Total instinct count
4. List of existing evolved components (from Phase 2)
5. Identity JSON (from Phase 3)
6. If incremental: list of new instinct filenames to focus on (but still read all instincts for clustering context)

Wait for the agent to return structured JSON output.

## Phase 5: Present Candidates

For each candidate in the agent's response:

1. Display a summary:
   ```
   ## Candidate: {name} ({type})
   - Confidence: {avg_confidence}
   - Source instincts: {source_instincts joined with ", "}
   - Rationale: {rationale}
   ```
2. Show the first 20 lines of the generated content as a preview
3. Use AskUserQuestion to ask: "Accept this candidate?"
   - Options: "Accept" (write to evolved/), "Skip" (do not write), "View full" (show complete content, then re-ask)

## Phase 6: Write Accepted Candidates

For each accepted candidate, write the file to the appropriate directory:

- **Agents**: Write to `~/.claude/homunculus/evolved/agents/{name}.md`
- **Skills**: Create directory `~/.claude/homunculus/evolved/skills/{name}/` and write `SKILL.md` inside
- **Commands**: Write to `~/.claude/homunculus/evolved/commands/{name}.md`

Use the Write tool (not the agent) to create the files.

## Phase 7: Touch Timestamp

```bash
touch "$HOME/.claude/homunculus/.last-evolve-timestamp"
```

Touch the marker even if the user rejected all candidates (the analysis was completed).
Do NOT touch the marker if the synthesizer agent failed.

## Phase 8: Summary Report

Display:

```
## Evolution Report
- Mode: {full|incremental}
- Instincts analyzed: {total}
- Clusters identified: {clusters_found}
- Candidates generated: {candidates_generated}
- Accepted: {accepted_count}
- Skipped (overlap): {skipped_overlaps}
- Unclustered instincts: {unclustered count}

### Accepted Components
{For each accepted: type, name, path}

### Next Steps
- Review accepted components in ~/.claude/homunculus/evolved/
- Promote with: bash ~/.claude/scripts/promote-evolved.sh <path>
```

## Error Handling

- If the synthesizer agent fails, report the error and do NOT touch the timestamp marker.
- If AskUserQuestion fails or the user cancels, write any already-accepted candidates and touch the timestamp.
- If a file write fails, warn the user and continue with remaining candidates.
