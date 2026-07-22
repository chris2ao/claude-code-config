#!/usr/bin/env bash
# Export gmail-agent run metrics + Claude session-archive metadata to the
# cryptoflexllc repo, commit, and push to trigger a Vercel rebuild. Feeds the
# "Claude Automation" section on cryptoflexllc.com/analytics.
#
# Invoked best-effort at the end of scripts/launch_agent.sh, right after the
# agent run completes. This script must NEVER affect the agent's exit status:
# it always exits 0 and logs failures to ~/.claude/logs/gmail-metrics-export.log.
#
# Mirrors the manual /gmail-metrics-export command so both stay in sync.
set -uo pipefail

CRYPTO_REPO="$HOME/GitProjects/cryptoflexllc"
DATA_DIR="$CRYPTO_REPO/src/data"
METRICS_FILE="$HOME/.cache/gmail-agent/run-metrics.jsonl"
LOG="$HOME/.claude/logs/gmail-metrics-export.log"
PY="/usr/bin/python3"
GIT="/usr/bin/git"

mkdir -p "$(dirname "$LOG")"
log() { echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] $*" >> "$LOG"; }

if [[ ! -d "$DATA_DIR" ]]; then
    log "ERROR: data dir missing: $DATA_DIR (skipping export)"
    exit 0
fi

# Step 1: Gmail metrics -> gmail-metrics.json
"$PY" - "$METRICS_FILE" > "$DATA_DIR/gmail-metrics.json" <<'PYEOF'
import json, sys
from datetime import datetime
try:
    with open(sys.argv[1]) as f:
        raw = [json.loads(line) for line in f if line.strip()]
except FileNotFoundError:
    raw = []
rows = []
for r in raw:
    if "run_id" not in r:
        continue  # legacy v3 bridge row (different schema); not exported
    started, ended = r.get("started_at"), r.get("ended_at")
    duration = 0
    if started and ended:
        try:
            duration = round((datetime.fromisoformat(ended) - datetime.fromisoformat(started)).total_seconds())
        except ValueError:
            pass
    details = r.get("details") or {}
    rows.append({
        "run_id": r.get("run_id", ""),
        "started_at": started or "",
        "ended_at": ended,
        "status": r.get("status", "unknown"),
        "duration_seconds": duration,
        "messages_scanned": r.get("messages_scanned", 0),
        "messages_trashed": r.get("messages_trashed", 0),
        "messages_archived": r.get("messages_archived", 0),
        "messages_flagged": r.get("messages_flagged", 0),
        "filters_created": r.get("filters_created", 0),
        "unsubscribes_succeeded": r.get("unsubscribes_succeeded", 0),
        "cost_usd": r.get("cost_usd", 0.0),
        "circuit_breaker_tripped": r.get("circuit_breaker_tripped", False),
        "agent_version": r.get("agent_version", ""),
        "attention_email_sent": details.get("attention_email_sent") == "true",
        # Public page: export only the exception class, never the message text,
        # which can embed sender addresses or subject fragments from gws errors.
        "error": details["error"].split(":")[0] if details.get("error") else None,
    })
rows.sort(key=lambda r: r.get("started_at", ""), reverse=True)
print(json.dumps(rows, indent=2))
PYEOF

# Step 2: Session archive metadata -> session-archive.json
"$PY" - > "$DATA_DIR/session-archive.json" <<'PYEOF'
import os, json, glob
from datetime import datetime
paths = glob.glob(os.path.expanduser('~/.claude/projects/*/session_archive/*.jsonl'))
paths += glob.glob(os.path.expanduser('~/.claude/session_archive/*.jsonl'))
rows = []
for p in paths:
    try:
        st = os.stat(p)
        dt = datetime.fromtimestamp(st.st_mtime)
        base = os.path.basename(p).replace('.jsonl', '')
        sid = base[:8] if len(base) >= 8 else base
        rows.append({
            'id': sid,
            'date': dt.strftime('%Y-%m-%d'),
            'time': dt.strftime('%H:%M'),
            'sizeBytes': st.st_size,
            'sizeMB': f'{st.st_size / (1024*1024):.2f}',
        })
    except OSError:
        pass
rows.sort(key=lambda r: (r['date'], r['time']), reverse=True)
print(json.dumps(rows, indent=2))
PYEOF

# Step 3: Commit and push (best-effort)
cd "$CRYPTO_REPO" || { log "ERROR: cd $CRYPTO_REPO failed"; exit 0; }
"$GIT" add src/data/gmail-metrics.json src/data/session-archive.json

if "$GIT" diff --cached --quiet; then
    log "no metric changes; nothing to commit"
    exit 0
fi

if "$GIT" commit -q -m "chore: update gmail metrics and session archive

Co-Authored-By: Claude <noreply@anthropic.com>"; then
    log "committed metric update"
else
    log "ERROR: commit failed (changes left staged)"
    exit 0
fi

if "$GIT" push >> "$LOG" 2>&1; then
    log "pushed OK; Vercel will rebuild"
else
    log "PUSH FAILED: commit retained locally, will publish on next manual push. Check git credentials under launchd (keychain may be unavailable; add a token to secrets.env)."
fi
exit 0
