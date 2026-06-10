# /gmail-metrics-export - Export Gmail Metrics and Session Archive

Exports Gmail assistant run metrics and Claude session archive metadata to JSON files in the cryptoflexllc repo, then commits and pushes to trigger a Vercel rebuild. Feeds the "Claude Automation" section on `/analytics`.

## Arguments

- `--dry-run` (optional): Export JSON files but do not commit or push.
- `--no-push` (optional): Export and commit but do not push.

## Workflow

### Step 1: Verify Target Repo

```bash
CRYPTO_REPO="$HOME/GitProjects/cryptoflexllc"
DATA_DIR="$CRYPTO_REPO/src/data"
if [ ! -d "$DATA_DIR" ]; then
  echo "ERROR: Data directory not found at $DATA_DIR"
  exit 1
fi
echo "Target: $DATA_DIR"
```

### Step 2: Export Gmail Metrics

Read `~/.cache/gmail-agent/run-metrics.jsonl` (the v4 standalone Python agent; the old v3 bridge path `~/.cache/gmail-assistant/` is retired). Each line is a JSON object with fields: `run_id`, `started_at`, `ended_at`, `status` (success | error | circuit_broken | running), `messages_scanned`, `messages_trashed`, `messages_archived`, `messages_flagged`, `filters_suggested`, `filters_created`, `unsubscribes_attempted`, `unsubscribes_succeeded`, `cost_usd`, `circuit_breaker_tripped`, `agent_version`, `details` (map; may contain `attention_email_sent`, `draft_id`, `error`), `written_at`.

The export normalizes each row for the frontend (`GmailRun` in `src/lib/analytics-types.ts`): computes `duration_seconds` from `started_at`/`ended_at`, flattens `details.attention_email_sent` to a boolean and `details.error` to a string, and sorts by `started_at` descending (newest first).

```bash
METRICS_FILE="$HOME/.cache/gmail-agent/run-metrics.jsonl"
python3 - "$METRICS_FILE" > "$DATA_DIR/gmail-metrics.json" <<'PY'
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
            duration = round(
                (datetime.fromisoformat(ended) - datetime.fromisoformat(started)).total_seconds()
            )
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
PY
```

Write to: `$DATA_DIR/gmail-metrics.json`

### Step 3: Export Session Archive Metadata

List session archive files in `~/.claude/projects/*/session_archive/*.jsonl` (fallback: `~/.claude/session_archive/*.jsonl`). For each file, collect:

- `id` — short session identifier from the filename (first 8 chars of the UUID portion, or the full basename if short)
- `date` — file creation date (YYYY-MM-DD)
- `time` — file creation time (HH:MM)
- `sizeBytes` — raw byte size
- `sizeMB` — formatted size in MB, 2 decimal places

Sort newest first.

```bash
python3 -c "
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
            'sizeMB': f'{st.st_size / (1024*1024):.2f}'
        })
    except OSError:
        pass

rows.sort(key=lambda r: (r['date'], r['time']), reverse=True)
print(json.dumps(rows, indent=2))
" > "$DATA_DIR/session-archive.json"
```

Write to: `$DATA_DIR/session-archive.json`

### Step 4: Commit and Push (unless --dry-run)

```bash
cd "$CRYPTO_REPO"
git add src/data/gmail-metrics.json src/data/session-archive.json
git diff --cached --stat

if git diff --cached --quiet; then
  echo "No changes. Skipping commit."
else
  git commit -m "chore: update gmail metrics and session archive

Co-Authored-By: Claude <noreply@anthropic.com>"

  # Push unless --no-push
  if [ "$1" != "--no-push" ] && [ "$1" != "--dry-run" ]; then
    git push
    echo "Pushed. Vercel will rebuild in ~60s."
  fi
fi
```

If `--dry-run`, skip both commit and push. If `--no-push`, commit but leave the push to the next commit in this session.

### Step 5: Report

```
## Gmail Metrics Export Complete

- Gmail runs: N
- Session archives: N
- Data written to:
    - src/data/gmail-metrics.json
    - src/data/session-archive.json
- Committed: yes/no
- Pushed: yes/no
```
