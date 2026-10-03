#!/usr/bin/env /opt/homebrew/bin/python3.11
"""
Monthly stale-memory sweep for the vector memory DB (mcp-memory-service 10.74.1).

WHY THIS EXISTS
  Built-in forgetting is OFF (MCP_FORGETTING_ENABLED=false), so nothing ever leaves
  the database. This job is the decay mechanism: it soft-deletes memories that are
  clearly dead weight, with a backup, a manifest and a restore path.

  Dry-run is the default. Nothing is touched without --apply.

RULES (live rows only, first match wins, A then B then C)
  A  decommissioned topic: a tag in DECOMMISSIONED_TAGS (whole tag, or tag followed
     by "-", or one of DECOMMISSIONED_ALIASES) AND idle > IDLE_DAYS_DECOMMISSIONED.
  B  superseded: tag "superseded" (or "superseded-...") AND idle > IDLE_DAYS_SUPERSEDED.
  C  never used: access_count 0 or missing AND created > AGE_DAYS_NEVER_USED ago.
  idle = now - max(metadata.last_accessed_at, created_at).
  Protected rows (PROTECTED_TAGS, PROTECTED_TAG_SUFFIXES, PROTECTED_TYPES) are never swept.

  CAVEAT on access data: upstream only updates metadata.access_count and
  last_accessed_at from semantic retrieve() (memory_search). A memory that is only
  ever found through tag, time or list lookups never gets an access bump, so Rule C
  treats it as never used. That is why every rule keeps the protected tag/type shield
  and why --apply is capped and backed up.

SOFT-DELETE SEMANTICS (replicated from upstream storage/mixins/delete.py delete())
  1. DELETE FROM memory_embeddings WHERE rowid = <memories.id>   (vec0 row removed)
  2. DELETE FROM memory_graph WHERE source_hash = ? OR target_hash = ?
  3. UPDATE memories SET deleted_at = <time.time(), REAL> WHERE content_hash = ?
     AND deleted_at IS NULL
  The FTS5 row is NOT removed: the memories_fts_au trigger re-indexes it on UPDATE,
  and search filters on deleted_at IS NULL. Tombstones are kept (no purge).
  Because step 1 and 2 destroy data that a bare "clear deleted_at" could not bring
  back, the manifest stores each row's embedding (base64 float32) and graph edges so
  --restore can rebuild the row completely.

  This is done with direct SQL (same as the sibling jobs) instead of the SSE server
  HTTP API: the API offers no restore, no batch, and needs auth plumbing, while the
  statements above are small, stable and tested against the real upstream
  DeleteMixin.delete in the test suite. WAL plus busy_timeout 15000 makes the writes
  safe next to the running server.

USAGE
  memory-stale-sweep.py                       dry run, TSV on stdout
  memory-stale-sweep.py --out cands.tsv       dry run, TSV to a file
  memory-stale-sweep.py --apply               backup, manifest, soft-delete
  memory-stale-sweep.py --restore sweep-X.jsonl   undo a sweep

EXIT CODES
  0 ok, 1 failure (nothing is deleted on failure)

Needs only the stdlib, except --apply/--restore which load the sqlite_vec package
(the same one the canary uses) to touch the vec0 table.
"""

import argparse
import base64
import json
import os
import sqlite3
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

# --------------------------------------------------------------------------
# Constants (tune here)
# --------------------------------------------------------------------------

DB = os.path.expanduser("~/Library/Application Support/mcp-memory/sqlite_vec.db")
BACKUP_DIR = os.path.expanduser("~/Library/Application Support/mcp-memory/backups")
MANIFEST_DIR = os.path.expanduser("~/.claude/logs/memory-sweep")
LOG_PATH = os.path.expanduser("~/.claude/logs/memory-stale-sweep.log")

DECOMMISSIONED_TAGS = frozenset(
    {"wazuh", "siem", "clickhouse", "mission-control", "hnmcd", "knowledge-graph", "gmail-assistant"}
)
# Real tags found in the DB that name the same decommissioned topics but do not
# start with a base above. openclaw is live infra and is deliberately absent.
DECOMMISSIONED_ALIASES = frozenset(
    {
        "home-network-mission-control-dashboard",
        "chris2ao-home-network-mission-control-dashboard",
        "mission control",
        "missioncontrol",
        "homelab-wazuh",
        "chris2ao-homelab-wazuh",
        "homelab-wazuh-repo",
    }
)
SUPERSEDED_TAG = "superseded"

# Plural spellings are included on purpose: protecting more is the safe direction.
PROTECTED_TAGS = frozenset(
    {
        "important", "critical", "reference", "permanent", "gotcha", "decision",
        "milestone", "keep",
        "references", "gotchas", "decisions", "milestones",
    }
)
# Compound tags such as clickhouse-gotchas or architecture-decision are protected too.
PROTECTED_TAG_SUFFIXES = ("-gotcha", "-gotchas", "-decision", "-decisions")
PROTECTED_TYPES = frozenset({"gotcha", "decision", "architecture", "reference"})

IDLE_DAYS_DECOMMISSIONED = 90
IDLE_DAYS_SUPERSEDED = 30
AGE_DAYS_NEVER_USED = 180

# Abort --apply when a run would sweep more than max(FLOOR, FRACTION * live rows).
# Guards the unattended monthly run against a logic or data surprise. --force skips it.
MAX_SWEEP_FRACTION = 0.25
MAX_SWEEP_FLOOR = 50

KEEP_PRESWEEP_BACKUPS = 6
BUSY_TIMEOUT_MS = 15000
TSV_SNIPPET = 120
MANIFEST_SNIPPET = 160
DAY = 86400.0

RULE_ORDER = ("A", "B", "C")


# --------------------------------------------------------------------------
# Logging
# --------------------------------------------------------------------------


class Logger:
    """stdout in the relink-job style; optionally also appended to a log file."""

    def __init__(self, file_path):
        self.file_path = file_path
        self.last_fail = None

    def line(self, msg: str) -> str:
        return f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} {msg}"

    def emit(self, msg: str) -> None:
        text = self.line(msg)
        if msg.startswith("FAIL"):
            self.last_fail = msg
        print(text, flush=True)
        if self.file_path:
            try:
                os.makedirs(os.path.dirname(self.file_path) or ".", exist_ok=True)
                with open(self.file_path, "a", encoding="utf-8") as fh:
                    fh.write(text + "\n")
            except OSError as e:
                print(f"{text} (log file write failed: {e})", file=sys.stderr)


def notify_failure(message: str) -> None:
    """Best-effort macOS notification so a failed scheduled sweep is not silent."""
    safe = str(message).replace("\\", "\\\\").replace('"', '\\"')[:200]
    script = f'display notification "{safe}" with title "Memory sweep FAILED"'
    try:
        subprocess.run(["osascript", "-e", script], capture_output=True, timeout=10, check=False)
    except Exception:  # noqa: BLE001  (best effort, never mask the real failure)
        pass


# --------------------------------------------------------------------------
# Selection (pure logic plus one read-only query)
# --------------------------------------------------------------------------


def parse_tags(raw):
    """Tags are stored comma separated. Returns lowercased, trimmed, non-empty tags."""
    if not raw:
        return []
    return [t.strip().lower() for t in str(raw).split(",") if t.strip()]


def _has_base(tag: str, bases) -> bool:
    return tag in bases or any(tag.startswith(b + "-") for b in bases)


def is_decommissioned_tag(tag: str) -> bool:
    tag = tag.strip().lower()
    return _has_base(tag, DECOMMISSIONED_TAGS) or tag in DECOMMISSIONED_ALIASES


def is_protected_tag(tag: str) -> bool:
    tag = tag.strip().lower()
    return tag in PROTECTED_TAGS or tag.endswith(PROTECTED_TAG_SUFFIXES)


def is_superseded_tag(tag: str) -> bool:
    tag = tag.strip().lower()
    return tag == SUPERSEDED_TAG or tag.startswith(SUPERSEDED_TAG + "-")


def parse_metadata(raw):
    """Returns (dict, ok). NULL/empty metadata is ok and empty; malformed is not ok."""
    if raw is None or str(raw).strip() == "":
        return {}, True
    try:
        data = json.loads(raw)
    except (TypeError, ValueError):
        return {}, False
    if not isinstance(data, dict):
        return {}, False
    return data, True


def _as_float(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def _as_int(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def classify(row, now):
    """Return a candidate dict for a live row, or None if it must be kept."""
    created = _as_float(row["created_at"])
    if created is None:
        return None
    tags = parse_tags(row["tags"])
    mtype = (row["memory_type"] or "").strip().lower()
    if mtype in PROTECTED_TYPES or any(is_protected_tag(t) for t in tags):
        return None

    meta, meta_ok = parse_metadata(row["metadata"])
    last_accessed = _as_float(meta.get("last_accessed_at"))
    access_count = _as_int(meta.get("access_count")) if "access_count" in meta else None
    newest = max(created, last_accessed) if last_accessed is not None else created
    idle_days = (now - newest) / DAY

    rule = None
    if idle_days > IDLE_DAYS_DECOMMISSIONED and any(is_decommissioned_tag(t) for t in tags):
        rule = "A"
    elif idle_days > IDLE_DAYS_SUPERSEDED and any(is_superseded_tag(t) for t in tags):
        rule = "B"
    elif (
        meta_ok
        and not access_count
        and (now - created) / DAY > AGE_DAYS_NEVER_USED
    ):
        rule = "C"
    if rule is None:
        return None
    return {
        "id": row["id"],
        "hash": row["content_hash"],
        "rule": rule,
        "tags": row["tags"] or "",
        "created": created,
        "last_accessed": last_accessed,
        "idle_days": round(idle_days, 1),
        "access_count": access_count if access_count is not None else 0,
        "content": row["content"] or "",
    }


def select_candidates(conn, now):
    """All sweep candidates among live (deleted_at IS NULL) rows."""
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT id, content_hash, content, tags, memory_type, metadata, created_at"
        " FROM memories WHERE deleted_at IS NULL"
    ).fetchall()
    found = [c for c in (classify(r, now) for r in rows) if c]
    found.sort(key=lambda c: (RULE_ORDER.index(c["rule"]), -c["idle_days"], c["hash"]))
    return found


def count_by_rule(cands):
    return {r: sum(1 for c in cands if c["rule"] == r) for r in RULE_ORDER}


def flat(text, limit):
    return " ".join(str(text).split())[:limit]


def render_tsv(cands) -> str:
    lines = ["\t".join(["hash", "rule", "tags", "idle_days", "access_count", "content"])]
    for c in cands:
        lines.append(
            "\t".join(
                [c["hash"], c["rule"], flat(c["tags"], 200), str(c["idle_days"]),
                 str(c["access_count"]), flat(c["content"], TSV_SNIPPET)]
            )
        )
    return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------
# Database helpers
# --------------------------------------------------------------------------


def open_readonly(path):
    uri = Path(path).resolve().as_uri() + "?mode=ro"
    conn = sqlite3.connect(uri, uri=True, timeout=BUSY_TIMEOUT_MS / 1000.0)
    conn.execute(f"PRAGMA busy_timeout={BUSY_TIMEOUT_MS}")
    return conn


def load_vec(conn):
    import sqlite_vec  # deferred: only --apply/--restore need the vec0 module

    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)


def open_readwrite(path):
    conn = sqlite3.connect(path, timeout=BUSY_TIMEOUT_MS / 1000.0, isolation_level=None)
    conn.execute(f"PRAGMA busy_timeout={BUSY_TIMEOUT_MS}")
    load_vec(conn)
    return conn


def integrity_ok(path) -> bool:
    conn = sqlite3.connect(str(path))
    try:
        try:
            load_vec(conn)
        except Exception:  # noqa: BLE001  (the check works without it too)
            pass
        return conn.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    except sqlite3.Error:
        return False
    finally:
        conn.close()


def make_backup(db_path, dest) -> None:
    src = sqlite3.connect(db_path, timeout=BUSY_TIMEOUT_MS / 1000.0)
    dst = sqlite3.connect(str(dest))
    try:
        src.backup(dst)
    finally:
        dst.close()
        src.close()


def rotate_backups(backup_dir, keep) -> list:
    files = sorted(
        Path(backup_dir).glob("sqlite_vec-presweep-*.db"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    removed = []
    for old in files[keep:]:
        try:
            old.unlink()
            removed.append(old.name)
        except OSError:
            pass
    return removed


# --------------------------------------------------------------------------
# Soft delete (mirrors upstream DeleteMixin.delete) and restore data capture
# --------------------------------------------------------------------------


def capture_restore_data(conn, cand) -> dict:
    """Embedding and graph edges that soft delete destroys, for --restore."""
    emb = conn.execute(
        "SELECT content_embedding FROM memory_embeddings WHERE rowid = ?", (cand["id"],)
    ).fetchone()
    graph = conn.execute(
        "SELECT source_hash, target_hash, similarity, connection_types, metadata,"
        " created_at, relationship_type FROM memory_graph"
        " WHERE source_hash = ? OR target_hash = ?",
        (cand["hash"], cand["hash"]),
    ).fetchall()
    return {
        "embedding_b64": base64.b64encode(emb[0]).decode("ascii") if emb and emb[0] else None,
        "graph": [list(g) for g in graph],
    }


def soft_delete_one(conn, cand, now):
    """Soft delete one row exactly like upstream. Returns graph rows removed, or None
    if the row was no longer live."""
    live = conn.execute(
        "SELECT id FROM memories WHERE content_hash = ? AND deleted_at IS NULL",
        (cand["hash"],),
    ).fetchone()
    if not live:
        return None
    try:
        conn.execute("DELETE FROM memory_embeddings WHERE rowid = ?", (live[0],))
    except sqlite3.Error as vec_err:
        # upstream proceeds with the soft delete when the vec row is unreadable
        print(f"WARN: could not delete embedding for {cand['hash']}: {vec_err}", file=sys.stderr)
    cur = conn.execute(
        "DELETE FROM memory_graph WHERE source_hash = ? OR target_hash = ?",
        (cand["hash"], cand["hash"]),
    )
    graph_deleted = cur.rowcount
    cur = conn.execute(
        "UPDATE memories SET deleted_at = ? WHERE content_hash = ? AND deleted_at IS NULL",
        (now, cand["hash"]),
    )
    return graph_deleted if cur.rowcount else None


def soft_delete_rows(conn, cands, now):
    """Soft delete every candidate. The caller owns the transaction (BEGIN IMMEDIATE,
    COMMIT or ROLLBACK). Returns (swept, graph_rows_deleted)."""
    swept = 0
    graph_total = 0
    for cand in cands:
        graph_deleted = soft_delete_one(conn, cand, now)
        if graph_deleted is not None:
            swept += 1
            graph_total += graph_deleted
    return swept, graph_total


# --------------------------------------------------------------------------
# Manifest, ledger
# --------------------------------------------------------------------------


def stamp(now) -> str:
    return datetime.fromtimestamp(now).strftime("%Y%m%d-%H%M%S")


def write_manifest(path, cands, extras) -> None:
    """One JSON object per line, flushed and fsynced before any row is touched."""
    with open(path, "x", encoding="utf-8") as fh:
        for c in cands:
            rec = {
                "hash": c["hash"],
                "id": c["id"],
                "rule": c["rule"],
                "tags": c["tags"],
                "created": c["created"],
                "last_accessed": c["last_accessed"],
                "idle_days": c["idle_days"],
                "snippet": flat(c["content"], MANIFEST_SNIPPET),
            }
            rec.update(extras[c["hash"]])
            fh.write(json.dumps(rec, ensure_ascii=False) + "\n")
        fh.flush()
        os.fsync(fh.fileno())


def append_ledger(manifest_dir, entry) -> None:
    """Machine-readable record of what changed, read by memory-health-canary.sh so a
    recorded sweep is not mistaken for data loss."""
    path = Path(manifest_dir) / "ledger.jsonl"
    with open(path, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(entry) + "\n")


# --------------------------------------------------------------------------
# Modes
# --------------------------------------------------------------------------


def summary_text(cands, live=None):
    counts = count_by_rule(cands)
    base = f"candidates={len(cands)} " + " ".join(f"{r}={n}" for r, n in counts.items())
    return base + (f" live={live}" if live is not None else "")


def run_dry(args, now, log) -> int:
    conn = open_readonly(args.db)
    try:
        cands = select_candidates(conn, now)
        live = conn.execute("SELECT count(*) FROM memories WHERE deleted_at IS NULL").fetchone()[0]
    finally:
        conn.close()
    tsv = render_tsv(cands)
    if args.out:
        Path(args.out).write_text(tsv, encoding="utf-8")
    else:
        sys.stdout.write(tsv)
    print(f"dry-run: {summary_text(cands, live)} (nothing modified)", file=sys.stderr)
    return 0


def count_live(conn) -> int:
    return conn.execute("SELECT count(*) FROM memories WHERE deleted_at IS NULL").fetchone()[0]


def sweep_cap(live: int) -> int:
    return max(MAX_SWEEP_FLOOR, int(MAX_SWEEP_FRACTION * live))


def over_cap_message(cands, live) -> str:
    return (
        f"FAIL: {len(cands)} candidates exceed the safety cap of {sweep_cap(live)} "
        f"({summary_text(cands, live)}); review a dry run, then rerun with --force"
    )


def rollback_if_open(conn) -> None:
    if conn.in_transaction:
        conn.execute("ROLLBACK")


def run_apply(args, now, log) -> int:
    """Order: preview (no lock) -> backup + integrity_check -> BEGIN IMMEDIATE ->
    authoritative select -> cap re-check -> capture embeddings/edges -> manifest
    (fsynced) -> delete -> COMMIT. Selection happens under the write lock so a row
    touched by a search in the meantime cannot be swept on stale data."""
    conn = open_readwrite(args.db)
    try:
        preview = select_candidates(conn, now)
        live = count_live(conn)
        if not preview:
            log.emit(f"OK: swept=0 {summary_text(preview, live)}")
            return 0
        if len(preview) > sweep_cap(live) and not args.force:
            log.emit(over_cap_message(preview, live))
            return 1

        ts = stamp(now)
        backup_dir = Path(args.backup_dir)
        backup_dir.mkdir(parents=True, exist_ok=True)
        backup = backup_dir / f"sqlite_vec-presweep-{ts}.db"
        make_backup(args.db, backup)
        if not integrity_ok(backup):
            backup.unlink(missing_ok=True)
            log.emit("FAIL: presweep backup failed integrity_check, aborting (nothing deleted)")
            return 1

        conn.execute("BEGIN IMMEDIATE")
        try:
            cands = select_candidates(conn, now)
            live = count_live(conn)
            if not cands:
                rollback_if_open(conn)
                log.emit(f"OK: swept=0 {summary_text(cands, live)}")
                return 0
            if len(cands) > sweep_cap(live) and not args.force:
                rollback_if_open(conn)
                log.emit(over_cap_message(cands, live))
                return 1
            extras = {c["hash"]: capture_restore_data(conn, c) for c in cands}
            manifest_dir = Path(args.manifest_dir)
            manifest_dir.mkdir(parents=True, exist_ok=True)
            manifest = manifest_dir / f"sweep-{ts}.jsonl"
            write_manifest(manifest, cands, extras)
            swept, graph_deleted = soft_delete_rows(conn, cands, now)
            conn.execute("COMMIT")
        except BaseException:
            rollback_if_open(conn)
            raise

        append_ledger(
            manifest_dir,
            {
                "ts": datetime.fromtimestamp(now).isoformat(timespec="seconds"),
                "epoch": now,
                "mode": "apply",
                "swept": swept,
                "graph_rows_deleted": graph_deleted,
                "manifest": str(manifest),
                "backup": str(backup),
            },
        )
        rotate_backups(backup_dir, KEEP_PRESWEEP_BACKUPS)
        log.emit(
            f"OK: swept={swept} {summary_text(cands, live)} graph_rows_deleted={graph_deleted} "
            f"manifest={manifest.name} backup={backup.name}"
        )
        return 0
    finally:
        conn.close()


def read_manifest(path):
    records = []
    with open(path, "r", encoding="utf-8") as fh:
        for n, line in enumerate(fh, 1):
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except ValueError as e:
                raise ValueError(f"{path}:{n}: malformed JSON ({e})") from e
            if not isinstance(rec, dict) or "hash" not in rec:
                raise ValueError(f"{path}:{n}: record has no 'hash'")
            records.append(rec)
    return records


def restore_one(conn, rec) -> str:
    """Returns 'restored', 'restored-no-embedding', 'skipped' (already live) or 'missing'."""
    row = conn.execute(
        "SELECT id, deleted_at FROM memories WHERE content_hash = ?", (rec["hash"],)
    ).fetchone()
    if not row:
        return "missing"
    mem_id, deleted_at = row
    if deleted_at is None:
        return "skipped"
    conn.execute("UPDATE memories SET deleted_at = NULL WHERE content_hash = ?", (rec["hash"],))
    for g in rec.get("graph") or []:
        other = g[1] if g[0] == rec["hash"] else g[0]
        if other != rec["hash"] and conn.execute(
            "SELECT 1 FROM memories WHERE content_hash = ? AND deleted_at IS NOT NULL", (other,)
        ).fetchone():
            continue  # neighbour is still soft-deleted: do not link to a hidden row
        conn.execute(
            "INSERT OR IGNORE INTO memory_graph (source_hash, target_hash, similarity,"
            " connection_types, metadata, created_at, relationship_type)"
            " VALUES (?,?,?,?,?,?,?)",
            g,
        )
    blob = rec.get("embedding_b64")
    if not blob:
        return "restored-no-embedding"
    exists = conn.execute("SELECT 1 FROM memory_embeddings WHERE rowid = ?", (mem_id,)).fetchone()
    if not exists:
        conn.execute(
            "INSERT INTO memory_embeddings (rowid, content_embedding) VALUES (?, ?)",
            (mem_id, base64.b64decode(blob)),
        )
    return "restored"


def run_restore(args, now, log) -> int:
    try:
        records = read_manifest(args.restore)
    except (OSError, ValueError) as e:
        log.emit(f"FAIL: cannot read manifest: {e}")
        return 1
    conn = open_readwrite(args.db)
    tally = {"restored": 0, "restored-no-embedding": 0, "skipped": 0, "missing": 0}
    try:
        conn.execute("BEGIN IMMEDIATE")
        try:
            for rec in records:
                tally[restore_one(conn, rec)] += 1
            conn.execute("COMMIT")
        except Exception:
            conn.execute("ROLLBACK")
            raise
    finally:
        conn.close()
    restored = tally["restored"] + tally["restored-no-embedding"]
    manifest_dir = Path(args.manifest_dir)
    if restored:
        manifest_dir.mkdir(parents=True, exist_ok=True)
        append_ledger(
            manifest_dir,
            {"epoch": now, "mode": "restore", "restored": restored, "manifest": str(args.restore)},
        )
    log.emit(
        f"OK: restored={restored} skipped-live={tally['skipped']} missing={tally['missing']} "
        f"no-embedding={tally['restored-no-embedding']} manifest={Path(args.restore).name}"
    )
    return 0


def build_parser():
    p = argparse.ArgumentParser(description="Monthly stale-memory sweep (dry-run by default).")
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true", help="soft-delete the candidates")
    mode.add_argument("--restore", metavar="MANIFEST", help="undo a sweep from its manifest")
    p.add_argument("--out", help="dry run: write the candidate TSV here instead of stdout")
    p.add_argument("--force", action="store_true", help="skip the sweep-size safety cap")
    p.add_argument("--db", default=DB)
    p.add_argument("--backup-dir", default=BACKUP_DIR)
    p.add_argument("--manifest-dir", default=MANIFEST_DIR)
    p.add_argument("--log-file", default=None, help="append the summary line here")
    return p


def dispatch(args, now, log) -> int:
    if not os.path.exists(args.db):
        log.emit(f"FAIL: database not found at {args.db}")
        return 1
    if args.apply:
        return run_apply(args, now, log)
    if args.restore:
        return run_restore(args, now, log)
    return run_dry(args, now, log)


def main(argv=None, now=None) -> int:
    args = build_parser().parse_args(argv)
    now = time.time() if now is None else now
    log_path = args.log_file or (LOG_PATH if sys.stdout.isatty() else None)
    log = Logger(log_path)
    try:
        rc = dispatch(args, now, log)
    except Exception as e:  # noqa: BLE001  (a scheduled run must report, not traceback)
        log.emit(f"FAIL: {type(e).__name__}: {e}")
        rc = 1
    if rc != 0 and args.apply:
        notify_failure(log.last_fail or "sweep failed, see memory-stale-sweep.log")
    return rc


if __name__ == "__main__":
    sys.exit(main())
