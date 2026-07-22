#!/usr/bin/env bash
# memory-p2-apply.sh
# Applies the P2 memory upgrades: SSE embedding fix, consolidation enable,
# quality env, DeBERTa quality backfill.
# RUN ONLY WITH NO CLAUDE CODE SESSIONS OPEN.
set -uo pipefail

DB="/Users/chris2ao/Library/Application Support/mcp-memory/sqlite_vec.db"
BKDIR="/Users/chris2ao/Library/Application Support/mcp-memory/backups"
LOG="/Users/chris2ao/.claude/logs/memory-p2-apply.log"
SSE_LABEL="com.cryptoflex.mcp-memory-sse"
SSE_PLIST="/Users/chris2ao/Library/LaunchAgents/com.cryptoflex.mcp-memory-sse.plist"
BRIDGE_LABEL="com.anthropic.claude-remote-control"
BRIDGE_PLIST="/Users/chris2ao/Library/LaunchAgents/com.anthropic.claude-remote-control.plist"
PY=/opt/homebrew/bin/python3.11
STAMP=$(date +%Y%m%d-%H%M%S)

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }
die() { log "FATAL: $*"; osascript -e 'display notification "P2 apply FAILED, see log" with title "Memory P2" sound name "Basso"' 2>/dev/null || true; exit 1; }

# R0: preflight - warmed model artifacts must exist (Phase 1 done)
$PY -c "import onnxruntime" 2>/dev/null || die "onnxruntime not installed (run Phase 1)"
[ -f "$HOME/.cache/mcp_memory/onnx_models/nvidia-quality-classifier-deberta/model.onnx" ] \
    || die "ONNX model not warmed (run Phase 1)"
curl -sf http://localhost:11434/api/tags >/dev/null || die "Ollama not reachable on :11434"

# R1: clear DB holders. SSE launchd job FIRST (KeepAlive respawns fight the
# orphan reaper otherwise, P0 lesson), then bridge, then orphans, then lsof gate.
SSE_WAS_RUNNING=0
if launchctl print "gui/501/$SSE_LABEL" >/dev/null 2>&1; then
    SSE_WAS_RUNNING=1
    log "booting out SSE job $SSE_LABEL"
    launchctl bootout "gui/501/$SSE_LABEL" 2>/dev/null || die "failed to bootout SSE job"
    sleep 3
fi
BRIDGE_WAS_RUNNING=0
if launchctl print "gui/501/$BRIDGE_LABEL" >/dev/null 2>&1; then
    BRIDGE_WAS_RUNNING=1
    log "booting out bridge job $BRIDGE_LABEL"
    launchctl bootout "gui/501/$BRIDGE_LABEL" 2>/dev/null || die "failed to bootout bridge job"
    sleep 3
fi
bridge_pid=$(pgrep -f "claude remote-control" | head -1 || true)
if [ -n "$bridge_pid" ]; then
    BRIDGE_WAS_RUNNING=1
    kill "$bridge_pid" 2>/dev/null || true
    sleep 3
fi
for pid in $(pgrep -f "mcp_memory_service.server" || true); do
    ppid=$(ps -p "$pid" -o ppid= | tr -d ' ')
    if [ "$ppid" = "1" ]; then
        log "killing orphaned mcp_memory_service pid $pid"
        kill "$pid" 2>/dev/null || true
    fi
done
sleep 2
pgrep -f "mcp_memory_service.server" >/dev/null 2>&1 \
    && die "vector-memory server still running; quit all Claude Code sessions first"
lsof -t "$DB" >/dev/null 2>&1 \
    && die "sqlite_vec.db still open by: $(lsof -t "$DB" | tr '\n' ' ')"

# R2: authoritative backup + WAL checkpoint
mkdir -p "$BKDIR"
sqlite3 "$DB" ".backup '$BKDIR/sqlite_vec-p2-$STAMP.db'" || die "backup failed"
sqlite3 "$DB" "PRAGMA wal_checkpoint(TRUNCATE);" || die "wal checkpoint failed"
log "backup ok: sqlite_vec-p2-$STAMP.db"

# R3: record current stdio config for rollback, then repoint
jq '.mcpServers["vector-memory"]' ~/.claude.json >> "$LOG" 2>/dev/null || true
claude mcp remove vector-memory -s user || die "mcp remove vector-memory failed"
claude mcp add-json vector-memory '{"type":"stdio","command":"/opt/homebrew/bin/python3.11","args":["-m","mcp_memory_service.server"],"env":{"MCP_MEMORY_STORAGE_BACKEND":"sqlite_vec","MCP_OAUTH_ENABLED":"false","MCP_OAUTH_PRIVATE_KEY":"disabled","MCP_OAUTH_PUBLIC_KEY":"disabled","MCP_QUALITY_BOOST_ENABLED":"true","MCP_QUALITY_BOOST_WEIGHT":"0.25","MCP_RETENTION_STANDARD":"60","MCP_EXTERNAL_EMBEDDING_URL":"http://localhost:11434/v1/embeddings","MCP_EXTERNAL_EMBEDDING_MODEL":"nomic-embed-text","MCP_QUALITY_LOCAL_MODEL":"nvidia-quality-classifier-deberta","MCP_CONSOLIDATION_ENABLED":"true","MCP_FORGETTING_ENABLED":"false","MCP_MEMORY_SQLITE_PRAGMAS":"busy_timeout=15000","HARVEST_LLM_PROVIDERS":"ollama","HARVEST_LLM_OLLAMA_BASE_URL":"http://localhost:11434/v1","HARVEST_LLM_OLLAMA_MODEL":"distill-disabled"}}' -s user \
    || die "mcp add-json vector-memory failed"
log "stdio vector-memory env updated"

# R4: SSE plist swap (new plist pre-staged, linted before install)
NEW_PLIST="/Users/chris2ao/.claude/scripts/com.cryptoflex.mcp-memory-sse.plist.p2"
[ -f "$NEW_PLIST" ] || die "staged plist missing: $NEW_PLIST"
plutil -lint "$NEW_PLIST" >/dev/null || die "staged plist fails lint"
cp "$SSE_PLIST" "$SSE_PLIST.bak-$STAMP" || die "plist backup failed"
cp "$NEW_PLIST" "$SSE_PLIST" || die "plist install failed"
log "SSE plist replaced (backup: $SSE_PLIST.bak-$STAMP)"

# R5: quality backfill - dry run, then apply (PIPESTATUS, P0 lesson)
$PY /Users/chris2ao/.claude/scripts/quality-rescore-backfill.py 2>&1 | tee -a "$LOG"
[ "${PIPESTATUS[0]}" -eq 0 ] || die "backfill dry-run failed"
$PY /Users/chris2ao/.claude/scripts/quality-rescore-backfill.py --apply 2>&1 | tee -a "$LOG"
[ "${PIPESTATUS[0]}" -eq 0 ] || die "backfill apply failed (rolled back)"

# R6: restore services
launchctl bootstrap gui/501 "$SSE_PLIST" || die "SSE bootstrap failed"
# The server can take 30s+ to bind while models load; a fixed 5s wait caused a
# false FATAL on 2026-07-21. Poll up to 120s instead.
sse_up=0
for _ in $(seq 1 40); do
    if nc -z 127.0.0.1 8765 2>/dev/null; then sse_up=1; break; fi
    sleep 3
done
[ "$sse_up" -eq 1 ] || die "SSE server not listening on :8765 after 120s"
# Note: scheduler startup logs at INFO, which the server suppresses under
# launchd (client detection defaults to claude_desktop). The canary verifies
# consolidation via last_consolidated_at in the DB instead.
if [ "$BRIDGE_WAS_RUNNING" = "1" ] && [ -f "$BRIDGE_PLIST" ]; then
    launchctl bootstrap gui/501 "$BRIDGE_PLIST" \
        && log "bridge restored" \
        || log "WARNING: bridge bootstrap failed; restore manually"
fi

# R7: marker for the canary's consolidation-recency check
date +%Y-%m-%d > /Users/chris2ao/.claude/memory/p2-applied-date

log "P2 apply complete"
osascript -e 'display notification "Memory P2 apply complete" with title "Memory P2"' 2>/dev/null || true
exit 0
