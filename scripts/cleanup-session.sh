#!/bin/bash
# cleanup-session.sh - Delete accumulated Claude Code session artifacts
# Called by /wrap-up Phase 3. Safe to run anytime.

PROJECTS_DIR="$HOME/.claude/projects"
TODOS_DIR="$HOME/.claude/todos"

# Count before cleanup
JSONL_COUNT=$(find "$PROJECTS_DIR" -name "*.jsonl" 2>/dev/null | wc -l)
TODO_COUNT=$(find "$TODOS_DIR" -name "*.json" 2>/dev/null | wc -l)

# Delete transcript files (keep memory/ directories and their contents)
find "$PROJECTS_DIR" -name "*.jsonl" -delete 2>/dev/null

# Delete session UUID subdirectories (but not memory/ dirs)
find "$PROJECTS_DIR" -mindepth 2 -maxdepth 2 -type d ! -name "memory" -exec rm -rf {} + 2>/dev/null

# Delete stale todo files
find "$TODOS_DIR" -name "*.json" -delete 2>/dev/null

echo "Cleaned: $JSONL_COUNT transcript(s), $TODO_COUNT todo(s)"
