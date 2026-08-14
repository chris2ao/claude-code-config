#!/bin/bash
# session-recall.sh — SessionStart hook
# Emits a one-time directive to query vector memory before starting work.
#
# Why this exists: as of 2026-08-13, 60% of never-retrieved memories were
# written in the preceding six weeks. Writes were healthy (3.1/day) but
# read-back was not happening, so hard-won context was being re-derived.
# rules/core/memory-management.md already said to recall at session start;
# this hook makes it a harness action instead of a hope.
#
# Fires on: startup, clear, compact. Skips resume (context already present).
#
# Opt-out: set CLAUDE_SESSION_RECALL=false in your environment

if [ "${CLAUDE_SESSION_RECALL}" = "false" ]; then
    exit 0
fi

input=$(cat)

source_type=$(echo "$input" | grep -o '"source":"[^"]*"' | head -n1 | cut -d'"' -f4)
cwd=$(echo "$input" | grep -o '"cwd":"[^"]*"' | head -n1 | cut -d'"' -f4)

# Resume restores prior context; a recall directive there is pure noise.
case "$source_type" in
    resume) exit 0 ;;
esac

project=""
if [ -n "$cwd" ]; then
    project=$(basename "$cwd")
fi

if [ -n "$project" ]; then
    scope="Include \"$project\" as a search term or tag filter."
else
    scope="Include the project name as a search term or tag filter."
fi

cat <<RECALL
MEMORY RECALL: Before acting on the user's first substantive request this session, run mcp__vector-memory__memory_search on the keywords of that request. $scope Pass quality_boost: 0.25 so scored memories outrank unscored noise.

Skip only if the request is trivial (a one-line question, a status check) or clearly unrelated to any prior work. If the search returns nothing relevant, proceed without comment rather than reporting the empty result.

Prior context beats re-derivation: gotchas, decisions, and failed approaches are already stored and cost real time to rediscover.
RECALL

exit 0
