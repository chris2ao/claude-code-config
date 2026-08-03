#!/usr/bin/env bash
# memory-health-canary.sh
# Weekly read-only health checks for the memory systems.
# Always exits 0; failures notify via osascript and log CANARY FAIL lines.
set -uo pipefail

DB="/Users/chris2ao/Library/Application Support/mcp-memory/sqlite_vec.db"
STATE="/Users/chris2ao/.claude/memory/canary-state.json"
ARCHIVE_DIR="/Users/chris2ao/.claude/session_archive"
LOG="/Users/chris2ao/.claude/logs/memory-health-canary.log"
PY="/opt/homebrew/bin/python3.11"
EXPECTED_DIM=768
COUNT_TOLERANCE=5

failures=()
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }
check_fail() { failures+=("$1"); log "CANARY FAIL: $1"; }

# Load high-water marks (read the old state; a new state object is written at the end)
prev_mem_hwm=0; prev_graph_hwm=0
if [ -f "$STATE" ]; then
    prev_mem_hwm=$(jq -r '.memory_count_hwm // 0' "$STATE")
    prev_graph_hwm=$(jq -r '.graph_count_hwm // 0' "$STATE")
fi

# (KG check retired 2026-07-20 with the knowledge graph layer)

# 2. Vector DB freshness (mtime within 14 days)
if [ ! -f "$DB" ]; then
    check_fail "vector DB missing: $DB"
else
    db_age_days=$(( ( $(date +%s) - $(stat -f %m "$DB") ) / 86400 ))
    [ "$db_age_days" -gt 14 ] && check_fail "vector DB stale: last write ${db_age_days}d ago"
fi

# 3. Memory count vs high-water mark, and 4. embedding dims + row count,
# quality distribution, graph size
# (python + sqlite_vec because the plain sqlite3 CLI cannot open the vec0 table)
mem_count=0; graph_count=0
if [ -f "$DB" ]; then
    stats=$("$PY" - "$DB" <<'PYEOF' 2>/dev/null
import re, sqlite3, sys
import sqlite_vec
conn = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
conn.enable_load_extension(True); sqlite_vec.load(conn)
mem = conn.execute("SELECT count(*) FROM memories WHERE deleted_at IS NULL").fetchone()[0]
emb = conn.execute("SELECT count(*) FROM memory_embeddings").fetchone()[0]
sql = conn.execute("SELECT sql FROM sqlite_master WHERE name='memory_embeddings'").fetchone()[0]
dim = int(re.search(r"FLOAT\[(\d+)\]", sql).group(1))
rows = conn.execute("SELECT CAST(json_extract(metadata,'$.quality_score') AS REAL) "
                    "FROM memories WHERE deleted_at IS NULL "
                    "AND json_extract(metadata,'$.quality_score') IS NOT NULL").fetchall()
q = [r[0] for r in rows]
qmean = sum(q)/len(q) if q else 0.0
qsd = (sum((x-qmean)**2 for x in q)/len(q))**0.5 if q else 0.0
graph = conn.execute("SELECT count(*) FROM memory_graph").fetchone()[0]
ents = conn.execute("SELECT count(*) FROM memory_graph WHERE relationship_type='has_entity'").fetchone()[0]
print(f"{mem} {emb} {dim} {len(q)} {qsd:.4f} {graph} {ents}")
PYEOF
    )
    if [ -z "$stats" ]; then
        check_fail "could not read vector DB stats (python/sqlite_vec probe failed)"
    else
        mem_count=$(echo "$stats" | awk '{print $1}')
        emb_count=$(echo "$stats" | awk '{print $2}')
        emb_dim=$(echo "$stats" | awk '{print $3}')
        scored_count=$(echo "$stats" | awk '{print $4}')
        q_stdev=$(echo "$stats" | awk '{print $5}')
        graph_count=$(echo "$stats" | awk '{print $6}')
        [ "$mem_count" -lt $((prev_mem_hwm - COUNT_TOLERANCE)) ] && \
            check_fail "memory count dropped: $mem_count vs high-water $prev_mem_hwm (tolerance $COUNT_TOLERANCE)"
        [ "$emb_dim" -ne "$EXPECTED_DIM" ] && \
            check_fail "embedding dimension is $emb_dim, expected $EXPECTED_DIM"
        [ "$emb_count" -lt $((mem_count - COUNT_TOLERANCE)) ] && \
            check_fail "embedding rows ($emb_count) lag memories ($mem_count)"
        [ "$scored_count" -lt $((mem_count - 50)) ] && \
            check_fail "quality coverage low: $scored_count/$mem_count scored"
        if awk "BEGIN{exit !($q_stdev < 0.01)}"; then
            check_fail "quality scores flat (stdev $q_stdev), scorer likely broken"
        fi
        [ "$graph_count" -lt $((prev_graph_hwm - COUNT_TOLERANCE)) ] && \
            check_fail "memory_graph shrank: $graph_count vs high-water $prev_graph_hwm"
        # CJ-PATCH: entity-link tracking. Upstream 10.74.1 consolidation deletes every
        # has_entity row each run (target_hash holds an entity name, not a memory hash).
        # com.chris2ao.memory-entity-relink rebuilds them Sun 04:00; if that job stops
        # working this fires instead of hiding inside the total graph count.
        entity_count=$(echo "$stats" | awk '{print $7}')
        if [ "${entity_count:-0}" -lt 100 ]; then
            check_fail "entity links collapsed: $entity_count (expected ~1000+); check com.chris2ao.memory-entity-relink"
        fi
    fi
fi

# 5. Newest session archive within 7 days
newest=$(ls -t "$ARCHIVE_DIR"/*.jsonl 2>/dev/null | head -1)
if [ -z "$newest" ]; then
    check_fail "no session archives found in $ARCHIVE_DIR"
else
    arch_age_days=$(( ( $(date +%s) - $(stat -f %m "$newest") ) / 86400 ))
    [ "$arch_age_days" -gt 7 ] && check_fail "newest session archive is ${arch_age_days}d old"
fi

# 6. WAL size under 25MB
WAL="$DB-wal"
if [ -f "$WAL" ]; then
    wal_mb=$(( $(stat -f %z "$WAL") / 1048576 ))
    [ "$wal_mb" -ge 25 ] && check_fail "WAL is ${wal_mb}MB (limit 25MB); run memory-maintenance.sh"
fi

# 7. Ollama reachable (hard dependency of vector-memory since the 768d migration)
curl -sf --max-time 5 http://localhost:11434/api/tags >/dev/null \
    || check_fail "Ollama not reachable on :11434 (vector-memory will fail to start)"

# 8. SSE memory server for the Windows workstation
nc -z 127.0.0.1 8765 2>/dev/null || check_fail "SSE server not listening on :8765"
launchctl print gui/501/com.cryptoflex.mcp-memory-sse >/dev/null 2>&1 \
    || check_fail "SSE launchd job not loaded"

# 9. Weekly consolidation ran (armed 8+ days after the P2 apply marker).
# Signal is DB truth: consolidation stamps last_consolidated_at into memory
# metadata. Log grepping does not work here: the server's client detection
# defaults to claude_desktop under launchd and suppresses all INFO lines.
P2_MARKER="/Users/chris2ao/.claude/memory/p2-applied-date"
if [ -f "$P2_MARKER" ]; then
    marker_age=$(( ( $(date +%s) - $(date -j -f %Y-%m-%d "$(cat "$P2_MARKER")" +%s 2>/dev/null || date +%s) ) / 86400 ))
    if [ "$marker_age" -ge 8 ]; then
        last_consol=$(sqlite3 "$DB" \
            "SELECT CAST(COALESCE(MAX(CAST(json_extract(metadata,'\$.last_consolidated_at') AS REAL)),0) AS INTEGER) FROM memories;" 2>/dev/null || echo 0)
        consol_age=$(( ( $(date +%s) - last_consol ) / 86400 ))
        if [ "$last_consol" -eq 0 ] || [ "$consol_age" -gt 9 ]; then
            check_fail "no consolidation run in the last 9 days (last_consolidated_at stale or absent)"
        fi
    fi
fi

# Persist new high-water marks (write a fresh state object, never edit in place)
new_mem_hwm=$prev_mem_hwm; [ "$mem_count" -gt "$prev_mem_hwm" ] && new_mem_hwm=$mem_count
new_graph_hwm=$prev_graph_hwm; [ "$graph_count" -gt "$prev_graph_hwm" ] && new_graph_hwm=$graph_count
jq -n --argjson mem "$new_mem_hwm" --argjson graph "$new_graph_hwm" \
    '{memory_count_hwm: $mem, graph_count_hwm: $graph, last_run: now | todate}' > "$STATE"

if [ "${#failures[@]}" -gt 0 ]; then
    summary="Memory canary: ${#failures[@]} check(s) failed. See memory-health-canary.log"
    osascript -e "display notification \"$summary\" with title \"Memory Health Canary\" sound name \"Basso\"" 2>/dev/null || true
else
    log "CANARY OK: mem_count=$mem_count"
fi
exit 0
