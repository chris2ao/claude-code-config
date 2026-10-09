#!/usr/bin/env bash
# Sweep known temp-file leaks from the per-user macOS temp dir.
#   1. onnxruntime CoreML compiled models (mcp_memory_service quality ranker
#      on the CoreML provider writes ~375 MB per server start, never removed)
#   2. Vitest 5 module dirs: 21-char nanoid dirs holding only client/ and/or ssr/
# Entries still open by a running process are always kept.
# Usage: tmpdir-leak-sweep.sh [--apply]   (default is a dry run)
set -euo pipefail

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

# Resolve symlinks (/var -> /private/var) so paths match lsof output.
T="$(cd -P "$(getconf DARWIN_USER_TEMP_DIR)" && pwd)"
EXTRA_DIRS=("/Volumes/MacExternal/CryptoFlix/cache/tmp")

open_entries() {
  # Top-level temp entries that any process holds open.
  # lsof exits 1 when some files are unreadable or nothing is open; not an error here.
  { lsof +D "$1" 2>/dev/null || true; } | awk 'NR>1 {print $NF}' \
    | sed -E "s#^($1/[^/]+).*#\1#" | sort -u
}

remove() {
  local path="$1" kb
  kb=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
  freed_kb=$((freed_kb + ${kb:-0})); count=$((count + 1))
  if [ "$APPLY" -eq 1 ]; then rm -rf "$path"; else echo "would remove: $path"; fi
}

sweep_dir() {
  local dir="$1" open entry contents
  [ -d "$dir" ] || return 0
  open="$(open_entries "$dir")"

  # onnxruntime leftovers older than 1 day
  while IFS= read -r entry; do
    grep -qxF "$entry" <<<"$open" || remove "$entry"
  done < <(find "$dir" -maxdepth 1 -name 'onnxruntime-*.model.mlmodel*' -mtime +0)

  # Vitest nanoid dirs older than 1 day whose only contents are client/ and/or ssr/
  while IFS= read -r entry; do
    grep -qxF "$entry" <<<"$open" && continue
    contents="$(ls -A "$entry" | tr '\n' ' ')"
    case "$contents" in
      "client "|"ssr "|"client ssr ") remove "$entry" ;;
    esac
  done < <(find "$dir" -maxdepth 1 -type d -mtime +0 | grep -E '/[A-Za-z0-9_-]{21}$' || true)
}

freed_kb=0; count=0
sweep_dir "$T"
for d in "${EXTRA_DIRS[@]}"; do sweep_dir "$d"; done

mode=$([ "$APPLY" -eq 1 ] && echo "removed" || echo "dry run")
printf '%s %s: %d entries, %.2f GiB\n' "$(date '+%F %T')" "$mode" "$count" \
  "$(echo "$freed_kb / 1048576" | bc -l)"
