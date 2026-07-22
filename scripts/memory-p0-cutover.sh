#!/usr/bin/env bash
# memory-p0-cutover.sh
# Applies the P0 MCP config changes and re-embeds the vector DB.
# RUN ONLY WITH NO CLAUDE CODE SESSIONS OPEN.
set -uo pipefail

DB="/Users/chris2ao/Library/Application Support/mcp-memory/sqlite_vec.db"
BKDIR="/Users/chris2ao/Library/Application Support/mcp-memory/backups"
KG_SRC="/Users/chris2ao/.npm/_npx/15b07286cbcc3329/node_modules/@modelcontextprotocol/server-memory/dist/memory.jsonl"
KG_DST="/Users/chris2ao/.claude/memory/knowledge-graph.jsonl"
LOG="/Users/chris2ao/.claude/logs/memory-p0-cutover.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }
die() { log "FATAL: $*"; osascript -e 'display notification "Cutover FAILED, see log" with title "Memory P0" sound name "Basso"' 2>/dev/null || true; exit 1; }

# R1: clear DB holders. Interactive sessions must be closed by the user.
# The remote-control bridge daemon and orphaned MCP servers (parent = launchd)
# are stopped here, because closing Claude windows never stops them.
BRIDGE_LABEL="com.anthropic.claude-remote-control"
BRIDGE_PLIST="/Users/chris2ao/Library/LaunchAgents/com.anthropic.claude-remote-control.plist"
BRIDGE_WAS_RUNNING=0
if launchctl print "gui/501/$BRIDGE_LABEL" >/dev/null 2>&1; then
    BRIDGE_WAS_RUNNING=1
    log "booting out launchd bridge job $BRIDGE_LABEL (keepalive respawns a plain kill)"
    launchctl bootout "gui/501/$BRIDGE_LABEL" 2>/dev/null || die "failed to bootout bridge launchd job"
    sleep 3
fi
# Also catch a bridge started manually outside launchd
bridge_pid=$(pgrep -f "claude remote-control" | head -1 || true)
if [ -n "$bridge_pid" ]; then
    BRIDGE_WAS_RUNNING=1
    log "stopping non-launchd bridge (pid $bridge_pid)"
    kill "$bridge_pid" 2>/dev/null || true
    sleep 3
fi
for pid in $(pgrep -f "mcp_memory_service.server" || true); do
    ppid=$(ps -p "$pid" -o ppid= | tr -d ' ')
    if [ "$ppid" = "1" ]; then
        log "killing orphaned mcp_memory_service pid $pid (parent is launchd)"
        kill "$pid" 2>/dev/null || true
    fi
done
sleep 2
if pgrep -f "mcp_memory_service.server" >/dev/null 2>&1; then
    die "vector-memory MCP server still running (a live Claude Code session owns it); quit all Claude Code sessions first"
fi
if lsof -t "$DB" >/dev/null 2>&1; then
    die "sqlite_vec.db still open by another process: $(lsof -t "$DB" | tr '\n' ' ')"
fi

# R2: fresh authoritative backup + full WAL checkpoint (server is down, must succeed)
mkdir -p "$BKDIR"
STAMP=$(date +%Y%m%d-%H%M%S)
sqlite3 "$DB" ".backup '$BKDIR/sqlite_vec-cutover-$STAMP.db'" || die "backup failed"
sqlite3 "$DB" "PRAGMA wal_checkpoint(TRUNCATE);" || die "wal checkpoint failed"
log "backup + checkpoint ok: sqlite_vec-cutover-$STAMP.db"

# R3: migrate KG file to durable path (freshest copy wins; preflight copy is the fallback)
if [ -f "$KG_SRC" ]; then
    cp "$KG_SRC" "$KG_DST" || die "KG copy failed"
fi
[ -s "$KG_DST" ] || die "durable KG file missing or empty at $KG_DST"
log "KG file at $KG_DST ($(wc -l < "$KG_DST") lines)"

# R4: repoint memory MCP server
claude mcp remove memory -s user || die "mcp remove memory failed"
claude mcp add-json memory '{"type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-memory"],"env":{"MEMORY_FILE_PATH":"/Users/chris2ao/.claude/memory/knowledge-graph.jsonl"}}' -s user \
    || die "mcp add-json memory failed"
log "memory server pinned to durable KG path"

# R5: vector-memory env with external Ollama embeddings
claude mcp remove vector-memory -s user || die "mcp remove vector-memory failed"
claude mcp add-json vector-memory '{"type":"stdio","command":"/opt/homebrew/bin/python3.11","args":["-m","mcp_memory_service.server"],"env":{"MCP_MEMORY_STORAGE_BACKEND":"sqlite_vec","MCP_OAUTH_ENABLED":"false","MCP_OAUTH_PRIVATE_KEY":"disabled","MCP_OAUTH_PUBLIC_KEY":"disabled","MCP_QUALITY_BOOST_ENABLED":"true","MCP_QUALITY_BOOST_WEIGHT":"0.25","MCP_RETENTION_STANDARD":"60","MCP_EXTERNAL_EMBEDDING_URL":"http://localhost:11434/v1/embeddings","MCP_EXTERNAL_EMBEDDING_MODEL":"nomic-embed-text"}}' -s user \
    || die "mcp add-json vector-memory failed"
log "vector-memory env updated for Ollama embeddings"

# R6: ollama up?
curl -sf http://localhost:11434/api/tags >/dev/null || die "Ollama not reachable on :11434"

# R7: re-embed 384 -> 768
/opt/homebrew/bin/python3.11 /Users/chris2ao/.claude/scripts/migrate-embeddings-768.py 2>&1 | tee -a "$LOG"
migrate_status=${PIPESTATUS[0]}
[ "$migrate_status" -eq 0 ] || die "re-embed failed (transaction rolled back, DB still 384d)"

# R8: verify dims from schema text
sqlite3 "$DB" "SELECT sql FROM sqlite_master WHERE name='memory_embeddings';" | grep -q "FLOAT\[768\]" \
    || die "post-migration schema check failed"

log "cutover complete"

# Restore the bridge launchd job that R1 stopped
if [ "$BRIDGE_WAS_RUNNING" = "1" ]; then
    if [ -f "$BRIDGE_PLIST" ]; then
        launchctl bootstrap gui/501 "$BRIDGE_PLIST" \
            && log "bridge launchd job restored" \
            || log "WARNING: bridge bootstrap failed; restore manually: launchctl bootstrap gui/501 $BRIDGE_PLIST"
    else
        log "WARNING: bridge plist not found at $BRIDGE_PLIST; relaunch manually: nohup ~/.claude/scripts/bridge-launcher.sh & disown"
    fi
fi

osascript -e 'display notification "Memory P0 cutover complete" with title "Memory P0"' 2>/dev/null || true
exit 0
