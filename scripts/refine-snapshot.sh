#!/usr/bin/env bash
# refine-snapshot.sh
# Snapshot files that are about to be modified by /refine, to ~/.claude/state/refine-snapshots/<timestamp>/
# Usage: refine-snapshot.sh <file1> [file2 ...]
# Prints the snapshot directory to stdout on success.

set -euo pipefail

SNAPSHOT_ROOT="$HOME/.claude/state/refine-snapshots"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
DEST="$SNAPSHOT_ROOT/$TS"

if [ "$#" -eq 0 ]; then
  echo "usage: refine-snapshot.sh <file1> [file2 ...]" >&2
  exit 2
fi

mkdir -p "$DEST"

for f in "$@"; do
  if [ ! -f "$f" ]; then
    echo "warn: not a file, skipping: $f" >&2
    continue
  fi
  # Preserve relative path under snapshot dir so multiple snapshots keep shape
  rel="${f#$HOME/}"
  target="$DEST/$rel"
  mkdir -p "$(dirname "$target")"
  cp -p "$f" "$target"
done

echo "$DEST"
