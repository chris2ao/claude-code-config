---
name: homenet-threat-enrich
description: On-demand RDAP and IPinfo enrichment for the top anomalies in the Mission Control Threat Intel tab. Read-only against external feeds; the only write is to the local SQLite (threat_intel_anomalies.enrichment_json + threat_intel_domain_cache rdap/ipinfo entries). Default invocation: claude -p "/homenet-threat-enrich".
---

# homenet-threat-enrich

## Purpose

The Threat Intelligence tab in the Home Network Mission Control Dashboard ranks anomalies by an additive score (URLhaus / Hagezi feed match, NOD, beaconing, tunnel, DGA, burst). The score buys triage but is not yet enriched: `registrar`, `registered_days_ago`, `asn`, `asn_org`, `country`. This skill walks the top N anomalies that are missing enrichment (or whose enrichment is older than 7 days), calls RDAP and IPinfo, and writes the result back to local SQLite. The dashboard's `/api/threat-intel/anomalies` endpoint reads the same field on its next refresh.

The skill runs **in this Claude Code session**. There is no separate Anthropic SDK call. SQLite I/O happens via Bash `sqlite3` for SELECTs and a small stdlib-only Python helper for the upsert. RDAP and IPinfo are public read-only HTTPS endpoints; both are rate-limited to 1 req/sec.

## Scope

- **Read-only** against RDAP (rdap.org/domain) and IPinfo (ipinfo.io free tier).
- **Local writes only:** `threat_intel_anomalies` (`enrichment_json`, `enrichment_fetched_at`) and `threat_intel_domain_cache` rows under `feed_name in ('rdap', 'ipinfo')`. Never mutates the URLhaus or Hagezi cache rows.
- **Idempotent on (etld1, feed_name).** Re-running within 7 days is a no-op unless `--force` is passed.

## Invocation

```
claude -p "/homenet-threat-enrich [--n N] [--min-score S] [--force] [--repo PATH] [--db-url URL] [--dry-run]"
```

| Flag | Default | Meaning |
|---|---|---|
| `--n N` | `20` | Max anomalies to enrich. Cap 50. |
| `--min-score S` | `5` | Skip anomalies with aggregate score below this. |
| `--force` | off | Bypass the 7-day TTL freshness check; always re-fetch. |
| `--repo PATH` | `~/GitProjects/chris2ao-home-network-mission-control-dashboard` | Repo root for `.env` discovery. |
| `--db-url URL` | unset | Override `DATABASE_URL` discovery. |
| `--dry-run` | off | Compose the enrichment plan and print it. Skip writes. |

## Data sources

### Dashboard SQLite (primary, always read)

All queries are read-only via `sqlite3` Bash. WAL mode keeps reads non-blocking.

- `threat_intel_anomalies` filtered by `score >= --min-score`, ordered by score desc, ID desc, limited to `--n` rows. Default skips rows whose `enrichment_fetched_at` is within the last 7 days.
- `threat_intel_domain_cache` for the existing rdap/ipinfo TTL check (when not `--force`).

### External feeds (one network call each, both per-domain)

- **RDAP** `https://rdap.org/domain/{etld1}` — JSON response. Look at `events[]` for `eventAction == "registration"`; pick the earliest date. Look at `entities[]` with `roles` containing `"registrar"` for the registrar name. 404/400/timeout treated as "RDAP unavailable" (record `rdap_unavailable: true`, do not retry inside the run).
- **IPinfo** `https://ipinfo.io/{ip}/json` free tier — JSON response. Resolve the FQDN to an IPv4 address via `socket.gethostbyname`; on resolution failure, skip IPinfo for that anomaly. Free tier covers 50K requests/month, well above home use.

Rate limit: `asyncio.sleep(1)` between domains. A 50-domain batch takes about 60-90s including network latency. The endpoint runs synchronously — if you want progress visibility, watch the dashboard's `/api/threat-intel/anomalies` refresh.

## Execution recipe

### 1. Resolve the repo + DB path

- Repo defaults to `~/GitProjects/chris2ao-home-network-mission-control-dashboard` (overridable via `--repo`).
- Read `{repo}/.env` for `DATABASE_URL`. If `--db-url` was passed, prefer that.
- Parse the `DATABASE_URL`: strip `sqlite+aiosqlite:///` or `sqlite:///`; treat `/`-prefixed remainder as absolute, otherwise resolve against `{repo}`.
- Verify the SQLite file exists. If not, error: `DB not found at <path>; pass --db-url or check {repo}/.env`. Never echo the raw `--db-url` back (it may contain credentials).

### 2. Pull the candidate anomalies

```sql
SELECT id, etld1, domain, score
  FROM threat_intel_anomalies
 WHERE score >= :min_score
   AND (
        :force
     OR enrichment_fetched_at IS NULL
     OR enrichment_fetched_at < datetime('now', '-7 days')
   )
 ORDER BY score DESC, id DESC
 LIMIT :n;
```

Keep N capped at 50 even if the operator passes a higher number. Print a header line: `enriching N domains, min_score=S, force=on/off`.

**Python compatibility:** macOS system `python3` is 3.9 (CommandLineTools). Do not use `from datetime import UTC` — it lands only in 3.11+. Use `from datetime import datetime, timezone` and alias `UTC = timezone.utc`. Same goes for `httpx`: not in stdlib and not guaranteed to be installed. Prefer `urllib.request` for the RDAP/IPinfo GETs unless running inside the dashboard venv.

### 3. For each anomaly, fetch RDAP + IPinfo

- `httpx.get(f"https://rdap.org/domain/{etld1}")` — 10s timeout. Parse JSON. Extract earliest `eventDate` where `eventAction == "registration"` (handle ICANN ISO 8601, Verisign date-only, Nominet, DENIC formats — see `backend/src/homenet_dashboard/utils/rdap.py:parse_rdap_date` for the canonical parser; reuse it via `import` if running inside the dashboard venv, otherwise inline a copy in the skill helper).
- Resolve `domain` to an IPv4 via `socket.gethostbyname`. On `gaierror`, skip IPinfo and record `asn=null, country=null`.
- `httpx.get(f"https://ipinfo.io/{ip}/json")` — 10s timeout. Parse JSON. Capture `org` (which holds the ASN org), `asn`, `country`.
- Sleep 1s before the next iteration.

### 4. Upsert each enrichment blob

Two SQLite UPSERTs per anomaly:

```sql
-- Update the anomaly row
UPDATE threat_intel_anomalies
   SET enrichment_json = :blob,
       enrichment_fetched_at = datetime('now')
 WHERE id = :id;

-- Upsert the (etld1, 'rdap') cache row with 7d TTL
INSERT OR REPLACE INTO threat_intel_domain_cache
  (etld1, domain, feed_name, payload_json, fetched_at, expires_at)
  VALUES (:etld1, :domain, 'rdap', :rdap_payload,
          datetime('now'), datetime('now', '+7 days'));

-- And the (etld1, 'ipinfo') cache row with 24h TTL
INSERT OR REPLACE INTO threat_intel_domain_cache
  (etld1, domain, feed_name, payload_json, fetched_at, expires_at)
  VALUES (:etld1, :domain, 'ipinfo', :ipinfo_payload,
          datetime('now'), datetime('now', '+1 day'));
```

Skip the IPinfo upsert when no IP could be resolved.

### 5. Emit a structured log line per domain + a summary at the end

Per-domain: `enriched etld1=X rdap_age_days=Y asn=Z`.

Summary: `done enriched=N rdap_unavailable=M ipinfo_unavailable=K failures=F`.

## Behavioral guardrails

- **Never call any RDAP / IPinfo URL with user-controlled input.** The only path is `https://rdap.org/domain/{etld1}` and `https://ipinfo.io/{ip}/json`, both URL-encoded.
- **Never write to UniFi, Pi-hole, or any non-local resource.** All MCP servers are off-limits; this skill is HTTPS-only against rdap.org and ipinfo.io.
- **Refuse to run if `MISSION_CONTROL_MODE=A` AND the operator passed `--apply`** (no `--apply` flag exists today; this is a guard for future scope creep). Mode A is read-only against UniFi / Pi-hole; the skill's external feeds are public, so the local-write path is allowed in any mode.
- **Skill is idempotent.** A re-run within 7 days touches no rows unless `--force`.

## Operator-facing failure modes

- `RDAP unavailable for {etld1}`: 404 / 400 / timeout / non-JSON. Recorded as `rdap_unavailable: true`; the dashboard inline-expand panel renders this state explicitly.
- `IPinfo rate limit` or `monthly cap exhausted`: 429. Stop the run and emit `ipinfo_rate_limit_hit=true` in the summary log line. Anomalies enriched up to that point are persisted.
- `socket.gaierror`: domain does not resolve right now. Record `asn=null, country=null`; do not retry inside the run.

## Verification (post-run)

- `sqlite3 <db> "SELECT COUNT(*) FROM threat_intel_anomalies WHERE enrichment_fetched_at > datetime('now', '-1 hour')"` should match `--n` minus failures.
- Open the dashboard at `/threat-intel`, expand a high-score anomaly row. The inline detail should show the registrar, age, and ASN org for any successfully enriched row.
- `sqlite3 <db> "SELECT COUNT(*) FROM threat_intel_domain_cache WHERE feed_name IN ('rdap','ipinfo')"` should reflect the run.
