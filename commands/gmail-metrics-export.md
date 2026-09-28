# /gmail-metrics-export - Export Gmail Metrics and Session Archive

Exports Gmail agent run metrics and Claude session-archive metadata and POSTs them to the cryptoflexllc ingest API (`POST /api/gmail/metrics`), which stores them in Neon (`automation_snapshots` table). The "Claude Automation" section on `/analytics` reads that snapshot at request time.

**CHANGED 2026-09-22:** this command used to write JSON into `cryptoflexllc/src/data/` and commit + push, which rebuilt the whole site on every export (see `docs/plans/deployment-storage-reduction-plan.md` in the cryptoflexllc repo). It now runs the live script, which is the single source of truth and also runs automatically after every gmail-agent run. Do not re-implement its steps here.

## Arguments

- `--dry-run` (optional): build the request body and report its size, but do not POST.

## Workflow

### Step 1: Run the script

```bash
~/.claude/scripts/gmail-metrics-export.sh $ARGUMENTS
```

The script always exits 0. It reads the token (`GMAIL_AGENT_SITE_TOKEN` in `~/.claude/secrets/secrets.env`, same value as the site's `GMAIL_AGENT_API_TOKEN`) through a curl config file, so it never appears in `ps`. Never echo the token.

### Step 2: Check the outcome

```bash
tail -3 ~/.claude/logs/gmail-metrics-export.log
```

- `pushed OK: HTTP 200` means the snapshot is stored.
- `PUSH FAILED: ... HTTP 3xx` means the base URL redirected (use `https://www.cryptoflexllc.com`, never follow the redirect since it drops the Authorization header).
- `HTTP 401` means the token does not match Vercel's `GMAIL_AGENT_API_TOKEN`; `HTTP 400` means a row failed the route's zod schema (`src/lib/gmail-metrics-schemas.ts`).

### Step 3: Report

```
## Gmail Metrics Export Complete

- Mode: dry run / pushed
- Result: <last log line>
```
