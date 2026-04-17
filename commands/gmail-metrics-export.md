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

Read `~/.cache/gmail-assistant/run-metrics.jsonl`. Each line is a JSON object with fields: `timestamp`, `account`, `duration_seconds`, `sync_mode`, `emails_processed`, `promotions_trashed`, `promotions_rescued`, `social_trashed`, `social_rescued`, `newsletters_trashed`, `newsletters_rescued`, `primary_kept`, `primary_archived`, `primary_trashed`, `primary_flagged`, `urgent_count`, `vip_overrides`, `security_threats_detected`, `drafts_generated`, `pending_replies`, `attention_email_sent`, `errors`, `circuit_breaker_triggered`.

Parse each line, collect into an array, sort by `timestamp` descending (newest first).

```bash
METRICS_FILE="$HOME/.cache/gmail-assistant/run-metrics.jsonl"
if [ -f "$METRICS_FILE" ]; then
  python3 -c "
import json, sys
with open('$METRICS_FILE') as f:
    rows = [json.loads(line) for line in f if line.strip()]
rows.sort(key=lambda r: r.get('timestamp',''), reverse=True)
print(json.dumps(rows, indent=2))
" > "$DATA_DIR/gmail-metrics.json"
else
  echo "[]" > "$DATA_DIR/gmail-metrics.json"
fi
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

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"

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
