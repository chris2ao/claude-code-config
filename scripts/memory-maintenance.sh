#!/usr/bin/env bash
# Weekly vector-memory maintenance: WAL checkpoint + rotating backup.
# The WAL was found at 62% of DB size on 2026-08-02 with no checkpointing, and the
# newest backup was 12 days old and manual. Both are handled here.
set -uo pipefail
D="$HOME/Library/Application Support/mcp-memory"
DB="$D/sqlite_vec.db"
BK="$D/backups"
KEEP=8
log(){ echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }

[ -f "$DB" ] || { log "FAIL: no db at $DB"; exit 1; }
mkdir -p "$BK"

wal_before=$(stat -f%z "$DB-wal" 2>/dev/null || echo 0)
sqlite3 "$DB" "PRAGMA wal_checkpoint(TRUNCATE);" >/dev/null 2>&1
wal_after=$(stat -f%z "$DB-wal" 2>/dev/null || echo 0)
log "wal checkpoint: $((wal_before/1024))KB -> $((wal_after/1024))KB"

TS=$(date +%Y%m%d-%H%M%S)
OUT="$BK/sqlite_vec-auto-$TS.db"
if sqlite3 "$DB" ".backup '$OUT'" 2>/dev/null; then
  if [ "$(sqlite3 "$OUT" 'PRAGMA integrity_check;' 2>/dev/null | head -1)" = "ok" ]; then
    log "backup ok: $(basename "$OUT") ($(( $(stat -f%z "$OUT") / 1024 ))KB)"
  else
    log "FAIL: backup failed integrity_check, removing"; rm -f "$OUT"; exit 1
  fi
else
  log "FAIL: sqlite backup command failed"; exit 1
fi

# Rotate: keep newest $KEEP auto-backups. Manual (p0/p2/cutover/pre-*) are never touched.
ls -t "$BK"/sqlite_vec-auto-*.db 2>/dev/null | tail -n +$((KEEP+1)) | while read -r old; do
  rm -f "$old" && log "rotated out: $(basename "$old")"
done
log "done"
