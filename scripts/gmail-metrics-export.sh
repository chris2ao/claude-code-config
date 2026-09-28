#!/usr/bin/env bash
# Export gmail-agent run metrics + Claude session-archive metadata and POST
# them to the cryptoflexllc.com ingest API. Feeds the "Claude Automation"
# section on cryptoflexllc.com/analytics.
#
# Invoked best-effort at the end of scripts/launch_agent.sh, right after the
# agent run completes. This script must NEVER affect the agent's exit status:
# it always exits 0 and logs the outcome (HTTP status only, never the token)
# to ~/.claude/logs/gmail-metrics-export.log.
#
# CHANGED 2026-09-22: this used to write the two JSON files into the
# cryptoflexllc repo's src/data/ and git commit + push, which triggered a
# full Vercel rebuild of the ~815 MB site on every run (see
# docs/plans/deployment-storage-reduction-plan.md, section C, in the
# cryptoflexllc repo). The JSON is now written to a temp dir, combined into
# one request body, and POSTed to /api/gmail/metrics, which upserts it into
# Neon (automation_snapshots table). /analytics reads it at request time.
# This script no longer touches the cryptoflexllc git repo at all.
#
# Mirrors the manual /gmail-metrics-export command so both stay in sync.
set -uo pipefail

METRICS_FILE="$HOME/.cache/gmail-agent/run-metrics.jsonl"
LOG="$HOME/.claude/logs/gmail-metrics-export.log"
SECRETS_FILE="$HOME/.claude/secrets/secrets.env"
PY="/usr/bin/python3"
CURL="/usr/bin/curl"
# www is canonical: the bare domain answers with a 307, and curl must not
# follow it (a cross-host redirect drops the Authorization header).
BASE_URL="${CRYPTOFLEX_BASE_URL:-https://www.cryptoflexllc.com}"
ENDPOINT="$BASE_URL/api/gmail/metrics"
TIMEOUT_SECS=30

mkdir -p "$(dirname "$LOG")"
log() { echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] $*" >> "$LOG"; }

TMP_DIR="$(mktemp -d)" || { log "ERROR: mktemp failed"; exit 0; }
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

GMAIL_METRICS_FILE="$TMP_DIR/gmail-metrics.json"
SESSION_ARCHIVE_FILE="$TMP_DIR/session-archive.json"
BODY_FILE="$TMP_DIR/body.json"
CURL_CONFIG_FILE="$TMP_DIR/curl.cfg"

# Step 1: Gmail metrics -> gmail-metrics.json (temp dir, not the repo)
"$PY" - "$METRICS_FILE" > "$GMAIL_METRICS_FILE" <<'PYEOF'
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
        # Quiet mode (2026-08-22) suppresses pending-only emails and records why.
        "attention_suppressed": bool(details.get("attention_suppressed_reason")),
        # Public page: export only the exception class, never the message text,
        # which can embed sender addresses or subject fragments from gws errors.
        "error": details["error"].split(":")[0] if details.get("error") else None,
    })
rows.sort(key=lambda r: r.get("started_at", ""), reverse=True)
print(json.dumps(rows))
PYEOF

# Step 2: Session archive metadata -> session-archive.json (temp dir)
"$PY" - > "$SESSION_ARCHIVE_FILE" <<'PYEOF'
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
print(json.dumps(rows))
PYEOF

# Step 3: Combine both exports into the ingest route's request body
"$PY" - "$GMAIL_METRICS_FILE" "$SESSION_ARCHIVE_FILE" "$BODY_FILE" <<'PYEOF'
import json, sys
gmail_path, session_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(gmail_path) as f:
    gmail_metrics = json.load(f)
with open(session_path) as f:
    session_archive = json.load(f)
with open(out_path, "w") as f:
    json.dump({"gmailMetrics": gmail_metrics, "sessionArchive": session_archive}, f)
PYEOF

# --dry-run: build and report the body (also to stdout for manual runs), no POST.
if [[ "${1:-}" == "--dry-run" ]]; then
    BODY_BYTES="$(wc -c < "$BODY_FILE" | tr -d ' ')"
    log "dry run: body built ($BODY_BYTES bytes), not sent"
    echo "dry run: body built ($BODY_BYTES bytes), not sent to $ENDPOINT"
    exit 0
fi

if [[ ! -f "$SECRETS_FILE" ]]; then
    log "ERROR: secrets file missing: $SECRETS_FILE (skipping push)"
    exit 0
fi

# Read only the one token line we need out of the secrets file, without
# sourcing (and so exposing in this process's environment) the whole file.
GMAIL_AGENT_SITE_TOKEN="$(grep -m1 '^GMAIL_AGENT_SITE_TOKEN=' "$SECRETS_FILE" | cut -d= -f2-)"

if [[ -z "$GMAIL_AGENT_SITE_TOKEN" ]]; then
    log "ERROR: GMAIL_AGENT_SITE_TOKEN not set in $SECRETS_FILE (skipping push)"
    exit 0
fi

# Pass the token via a curl config file rather than argv or an inline
# header flag, so it never appears in `ps`/process listings. Scoped to this
# temp dir and removed by the EXIT trap.
{
    printf 'header = "Authorization: Bearer %s"\n' "$GMAIL_AGENT_SITE_TOKEN"
    printf 'header = "Content-Type: application/json"\n'
    # Vercel's Security Checkpoint challenges the default curl/* user agent
    # with a 429 page; a named client UA passes (verified 2026-09-22).
    printf 'user-agent = "cryptoflexllc-metrics-export/1.0"\n'
} > "$CURL_CONFIG_FILE"
chmod 600 "$CURL_CONFIG_FILE"
unset GMAIL_AGENT_SITE_TOKEN

HTTP_STATUS="$("$CURL" --silent --show-error --output /dev/null --write-out '%{http_code}' \
    --fail-with-body --max-time "$TIMEOUT_SECS" \
    --config "$CURL_CONFIG_FILE" \
    --data-binary "@$BODY_FILE" \
    "$ENDPOINT")"
CURL_EXIT=$?

# --fail-with-body only fails on 4xx/5xx, so a 3xx still exits 0: require 2xx.
if [[ "$CURL_EXIT" -eq 0 && "$HTTP_STATUS" == 2* ]]; then
    log "pushed OK: HTTP $HTTP_STATUS ($ENDPOINT)"
else
    log "PUSH FAILED: curl exit $CURL_EXIT, HTTP $HTTP_STATUS ($ENDPOINT)"
fi

exit 0
