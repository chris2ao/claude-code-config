"""Tests for memory-stale-sweep.py.

Run:  python3.11 -m pytest ~/.claude/scripts/tests/test_memory_stale_sweep.py
Needs pytest and the sqlite_vec package (the real schema has a vec0 table).
The temp databases are built from fixtures/memory_schema.sql, which is the real
mcp-memory-service 10.74.1 schema dumped from a .backup copy of the live DB.
"""

import asyncio
import hashlib
import importlib.util
import json
import os
import sqlite3
import subprocess
import sys
import time
from pathlib import Path

import pytest

sqlite_vec = pytest.importorskip("sqlite_vec")

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent / "memory-stale-sweep.py"
SCHEMA = HERE / "fixtures" / "memory_schema.sql"
CANARY = HERE.parent / "memory-health-canary.sh"

DAY = 86400.0
NOW = 1_790_000_000.0  # fixed "now" so idle math is deterministic


def _load_module():
    spec = importlib.util.spec_from_file_location("memory_stale_sweep", SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    sys.modules["memory_stale_sweep"] = mod
    spec.loader.exec_module(mod)
    return mod


ms = _load_module()


def vec_blob(seed: float = 0.1) -> bytes:
    return sqlite_vec.serialize_float32([seed] * 768)


def connect(path) -> sqlite3.Connection:
    conn = sqlite3.connect(str(path))
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)
    return conn


def make_db(path) -> Path:
    conn = connect(path)
    conn.executescript(SCHEMA.read_text())
    conn.commit()
    conn.close()
    return Path(path)


def add_mem(
    conn,
    h,
    tags="",
    mtype="note",
    created_days=400,
    accessed_days=None,
    access_count=None,
    deleted=False,
    content=None,
    metadata=None,
    graph_to=None,
):
    """Insert one memory (+ embedding, + optional graph edges)."""
    if metadata is None:
        meta = {}
        if access_count is not None:
            meta["access_count"] = access_count
        if accessed_days is not None:
            meta["last_accessed_at"] = NOW - accessed_days * DAY
        metadata = json.dumps(meta)
    created = NOW - created_days * DAY
    cur = conn.execute(
        "INSERT INTO memories (content_hash, content, tags, memory_type, metadata,"
        " created_at, updated_at, deleted_at) VALUES (?,?,?,?,?,?,?,?)",
        (
            h,
            content or f"content of {h}",
            tags,
            mtype,
            metadata,
            created,
            created,
            (NOW - DAY) if deleted else None,
        ),
    )
    rowid = cur.lastrowid
    if not deleted:
        conn.execute(
            "INSERT INTO memory_embeddings (rowid, content_embedding) VALUES (?, ?)",
            (rowid, vec_blob(rowid / 1000.0)),
        )
    for target in graph_to or []:
        conn.execute(
            "INSERT INTO memory_graph (source_hash, target_hash, similarity,"
            " connection_types, metadata, created_at, relationship_type)"
            " VALUES (?,?,0.9,'[\"semantic\"]','{}',?, 'related')",
            (h, target, NOW),
        )
    conn.commit()
    return rowid


@pytest.fixture(autouse=True)
def notifications(monkeypatch):
    """Never fire a real macOS notification from the suite; record the calls."""
    calls = []
    monkeypatch.setattr(ms, "notify_failure", lambda message: calls.append(message))
    return calls


@pytest.fixture()
def db(tmp_path):
    return make_db(tmp_path / "sqlite_vec.db")


def selected(db_path, now=NOW):
    conn = connect(db_path)
    try:
        return {c["hash"]: c for c in ms.select_candidates(conn, now)}
    finally:
        conn.close()


def populate(db_path, **kw):
    conn = connect(db_path)
    add_mem(conn, **kw)
    conn.close()


# --------------------------------------------------------------------------
# tag helpers
# --------------------------------------------------------------------------


def test_parse_tags_splits_trims_lowercases():
    assert ms.parse_tags(" Wazuh, SIEM ,,claude code workflow") == [
        "wazuh",
        "siem",
        "claude code workflow",
    ]
    assert ms.parse_tags(None) == []
    assert ms.parse_tags("") == []


@pytest.mark.parametrize(
    "tag,expected",
    [
        ("wazuh", True),
        ("WAZUH", True),
        ("siem-loglake", True),
        ("gmail-assistant-v3", True),
        ("siemens", False),
        ("mission-controller", False),
        ("openclaw", False),
        ("openclaw-mission-control", False),
        ("home-network-mission-control-dashboard", True),
        ("homelab-wazuh", True),
        ("missioncontrol", True),
    ],
)
def test_decommissioned_tag_matching(tag, expected):
    assert ms.is_decommissioned_tag(tag) is expected


# --------------------------------------------------------------------------
# Rule A
# --------------------------------------------------------------------------


def test_rule_a_selects_decommissioned_idle_over_90(db):
    populate(db, h="a1", tags="wazuh,homelab", created_days=200, accessed_days=91)
    got = selected(db)
    assert got["a1"]["rule"] == "A"


def test_rule_a_not_selected_when_idle_90_or_less(db):
    populate(db, h="a2", tags="siem", created_days=200, accessed_days=89, access_count=3)
    assert "a2" not in selected(db)


def test_rule_a_prefix_tag_siem_loglake(db):
    populate(db, h="a3", tags="siem-loglake", created_days=150, access_count=2)
    assert selected(db)["a3"]["rule"] == "A"


def test_rule_a_case_insensitive(db):
    populate(db, h="a4", tags="ClickHouse", created_days=150, access_count=2)
    assert selected(db)["a4"]["rule"] == "A"


def test_rule_a_all_decommissioned_bases(db):
    for i, t in enumerate(ms.DECOMMISSIONED_TAGS):
        populate(db, h=f"base{i}", tags=t, created_days=150, access_count=1)
    got = selected(db)
    assert len(got) == len(ms.DECOMMISSIONED_TAGS)
    assert all(c["rule"] == "A" for c in got.values())


def test_openclaw_only_memory_is_never_selected(db):
    populate(db, h="oc1", tags="openclaw,gateway", created_days=150, access_count=4)
    populate(db, h="oc2", tags="openclaw-mission-control", created_days=150, access_count=4)
    populate(db, h="oc3", tags="openclaw_missioncontrol", created_days=150, access_count=4)
    assert selected(db) == {}


def test_rule_a_idle_uses_created_when_never_accessed(db):
    # never accessed, created 100 days ago, access_count 1 so rule C is out
    populate(db, h="a5", tags="hnmcd", created_days=100, access_count=1)
    assert selected(db)["a5"]["rule"] == "A"
    populate(db, h="a6", tags="hnmcd", created_days=60, access_count=1)
    assert "a6" not in selected(db)


# --------------------------------------------------------------------------
# Rule B
# --------------------------------------------------------------------------


def test_rule_b_superseded_idle_over_30(db):
    populate(db, h="b1", tags="superseded,foo", created_days=100, accessed_days=31, access_count=5)
    assert selected(db)["b1"]["rule"] == "B"


def test_rule_b_not_selected_when_recently_accessed(db):
    populate(db, h="b2", tags="superseded", created_days=100, accessed_days=10, access_count=5)
    assert "b2" not in selected(db)


def test_rule_b_dated_superseded_tag(db):
    populate(db, h="b3", tags="superseded-2026-04-28", created_days=100, access_count=5)
    assert selected(db)["b3"]["rule"] == "B"


def test_rule_b_partially_superseded_is_not_matched(db):
    populate(db, h="b4", tags="partially-superseded-2026-04-30", created_days=100, access_count=5)
    assert "b4" not in selected(db)


def test_supersedes_pointer_tag_is_not_superseded(db):
    # supersedes:<hash> marks the NEW memory, which must stay
    populate(db, h="b5", tags="supersedes:0a904e2e", created_days=100, access_count=5)
    assert "b5" not in selected(db)


# --------------------------------------------------------------------------
# Rule C
# --------------------------------------------------------------------------


def test_rule_c_access_count_zero_and_old(db):
    populate(db, h="c1", tags="misc", created_days=181, access_count=0)
    assert selected(db)["c1"]["rule"] == "C"


def test_rule_c_access_count_missing_and_old(db):
    populate(db, h="c2", tags="misc", created_days=181)
    populate(db, h="c3", tags="misc", created_days=181, metadata=None)
    assert selected(db)["c2"]["rule"] == "C"


def test_rule_c_null_metadata(db):
    conn = connect(db)
    add_mem(conn, "c4", tags="misc", created_days=300)
    conn.execute("UPDATE memories SET metadata = NULL WHERE content_hash='c4'")
    conn.commit()
    conn.close()
    assert selected(db)["c4"]["rule"] == "C"


def test_rule_c_malformed_metadata_is_not_swept(db):
    populate(db, h="c5", tags="misc", created_days=300, metadata="{not json")
    assert "c5" not in selected(db)


def test_rule_c_not_selected_when_accessed_before(db):
    populate(db, h="c6", tags="misc", created_days=300, access_count=1)
    assert "c6" not in selected(db)


def test_rule_c_not_selected_when_young(db):
    populate(db, h="c7", tags="misc", created_days=179, access_count=0)
    assert "c7" not in selected(db)


# --------------------------------------------------------------------------
# protection, deleted rows, precedence, idle
# --------------------------------------------------------------------------


@pytest.mark.parametrize("tag", sorted(ms.PROTECTED_TAGS))
def test_protected_tags_never_selected(db, tag):
    populate(db, h="p-" + tag, tags=f"wazuh,superseded,{tag.upper()}", created_days=500, access_count=0)
    assert selected(db) == {}


@pytest.mark.parametrize("mtype", sorted(ms.PROTECTED_TYPES))
def test_protected_memory_types_never_selected(db, mtype):
    populate(db, h="t-" + mtype, tags="wazuh,superseded", mtype=mtype, created_days=500, access_count=0)
    assert selected(db) == {}


def test_protected_memory_type_case_insensitive(db):
    populate(db, h="t1", tags="wazuh", mtype="Gotcha", created_days=500, access_count=0)
    assert selected(db) == {}


def test_already_deleted_rows_are_ignored(db):
    populate(db, h="d1", tags="wazuh", created_days=500, access_count=0, deleted=True)
    assert selected(db) == {}


def test_precedence_a_over_b_over_c(db):
    populate(db, h="x1", tags="wazuh,superseded", created_days=500, access_count=0)
    populate(db, h="x2", tags="superseded", created_days=500, access_count=0)
    got = selected(db)
    assert got["x1"]["rule"] == "A"
    assert got["x2"]["rule"] == "B"


def test_idle_uses_last_accessed_when_newer_than_created(db):
    # created 400d ago but touched 10d ago: not idle, so rule A must not fire
    populate(db, h="i1", tags="wazuh", created_days=400, accessed_days=10, access_count=7)
    assert "i1" not in selected(db)


def test_idle_uses_created_when_newer_than_last_accessed(db):
    # last_accessed older than created (clock oddity): created wins, so idle=20d
    populate(db, h="i2", tags="wazuh", created_days=20, accessed_days=300, access_count=1)
    assert "i2" not in selected(db)


def test_candidate_fields(db):
    populate(db, h="f1", tags="wazuh,x", created_days=200, accessed_days=120, access_count=3, content="hello\n\tworld")
    c = selected(db)["f1"]
    assert c["idle_days"] == pytest.approx(120.0)
    assert c["access_count"] == 3
    assert c["tags"] == "wazuh,x"
    assert c["content"] == "hello\n\tworld"
    assert c["created"] == pytest.approx(NOW - 200 * DAY)
    assert c["last_accessed"] == pytest.approx(NOW - 120 * DAY)


def test_row_without_created_at_is_skipped(db):
    conn = connect(db)
    add_mem(conn, "n1", tags="wazuh", access_count=0)
    conn.execute("UPDATE memories SET created_at = NULL WHERE content_hash='n1'")
    conn.commit()
    conn.close()
    assert selected(db) == {}


# --------------------------------------------------------------------------
# dry-run
# --------------------------------------------------------------------------


def file_sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def run(argv, tmp_path, now=NOW):
    args = [
        "--backup-dir", str(tmp_path / "backups"),
        "--manifest-dir", str(tmp_path / "manifests"),
        "--log-file", str(tmp_path / "sweep.log"),
    ] + argv
    return ms.main(args, now=now)


def test_dry_run_does_not_modify_and_writes_out(db, tmp_path, capsys):
    populate(db, h="r1", tags="wazuh", created_days=200, accessed_days=120, access_count=3, content="line1\nline2")
    populate(db, h="r2", tags="keep,wazuh", created_days=200, accessed_days=120, access_count=3)
    before = file_sha(db)
    out = tmp_path / "cands.tsv"
    rc = run(["--db", str(db), "--out", str(out)], tmp_path)
    assert rc == 0
    assert file_sha(db) == before
    lines = out.read_text().splitlines()
    assert lines[0].split("\t") == ["hash", "rule", "tags", "idle_days", "access_count", "content"]
    rows = [l.split("\t") for l in lines[1:]]
    assert [r[0] for r in rows] == ["r1"]
    assert rows[0][1] == "A"
    assert rows[0][3] == "120.0"
    assert rows[0][5] == "line1 line2"
    assert not (tmp_path / "backups").exists()
    assert not (tmp_path / "manifests").exists()
    err = capsys.readouterr().err
    assert "dry-run" in err and "A=1" in err


def test_dry_run_prints_to_stdout_without_out(db, tmp_path, capsys):
    populate(db, h="r3", tags="siem", created_days=200, access_count=3)
    assert run(["--db", str(db)], tmp_path) == 0
    assert "r3\tA\t" in capsys.readouterr().out


def test_dry_run_opens_read_only(db, tmp_path, monkeypatch):
    seen = []
    real = sqlite3.connect

    def spy(target, *a, **kw):
        seen.append(str(target))
        return real(target, *a, **kw)

    monkeypatch.setattr(ms.sqlite3, "connect", spy)
    run(["--db", str(db)], tmp_path)
    assert any("mode=ro" in s for s in seen)
    assert not any(s == str(db) for s in seen)


def test_content_snippet_truncated(db, tmp_path, capsys):
    populate(db, h="r4", tags="siem", created_days=200, access_count=3, content="x" * 500)
    run(["--db", str(db)], tmp_path)
    row = [l for l in capsys.readouterr().out.splitlines() if l.startswith("r4")][0]
    assert len(row.split("\t")[5]) == 120


def test_missing_db_is_exit_1(tmp_path):
    assert run(["--db", str(tmp_path / "nope.db")], tmp_path) == 1


# --------------------------------------------------------------------------
# apply
# --------------------------------------------------------------------------


def seeded(db):
    """3 sweepable (A, B, C), 2 keepers, graph edges on swept and kept rows."""
    conn = connect(db)
    add_mem(conn, "sa", tags="wazuh", created_days=300, accessed_days=200, access_count=2, graph_to=["keep1", "ent:Wazuh"])
    add_mem(conn, "sb", tags="superseded", created_days=300, accessed_days=100, access_count=2)
    add_mem(conn, "sc", tags="misc", created_days=300, access_count=0)
    add_mem(conn, "keep1", tags="gotcha", created_days=300, access_count=0, graph_to=["sa", "sb"])
    add_mem(conn, "keep2", tags="misc", created_days=10, access_count=0)
    conn.close()


def state(db):
    conn = connect(db)
    try:
        mem = conn.execute("SELECT id, content_hash, deleted_at, tags, content, metadata FROM memories ORDER BY id").fetchall()
        emb = conn.execute("SELECT rowid FROM memory_embeddings ORDER BY rowid").fetchall()
        graph = conn.execute("SELECT source_hash, target_hash FROM memory_graph ORDER BY 1,2").fetchall()
        fts = conn.execute("SELECT rowid FROM memory_content_fts_docsize ORDER BY 1").fetchall()
        return mem, emb, graph, fts
    finally:
        conn.close()


def test_apply_soft_deletes_matching_rows_only(db, tmp_path):
    seeded(db)
    assert run(["--db", str(db), "--apply"], tmp_path) == 0
    mem, emb, graph, _ = state(db)
    deleted = {m[1] for m in mem if m[2] is not None}
    assert deleted == {"sa", "sb", "sc"}
    live_ids = {m[0] for m in mem if m[2] is None}
    assert {e[0] for e in emb} == live_ids
    # every graph edge touching a swept hash is gone, the rest untouched
    assert graph == []  # seeded edges all touched sa/sb


def test_apply_deleted_at_is_real_epoch_like_upstream(db, tmp_path):
    seeded(db)
    t0 = time.time()
    run(["--db", str(db), "--apply"], tmp_path, now=t0)
    conn = connect(db)
    vals = conn.execute("SELECT deleted_at, typeof(deleted_at) FROM memories WHERE deleted_at IS NOT NULL").fetchall()
    conn.close()
    assert vals and all(t == "real" and t0 - 5 <= v <= time.time() + 5 for v, t in vals)


def upstream_delete(db_path, hashes):
    """Run the REAL upstream DeleteMixin.delete against a database."""
    delete_mod = pytest.importorskip("mcp_memory_service.storage.mixins.delete")

    class Harness(delete_mod.DeleteMixin):
        def __init__(self, path):
            self.conn = connect(path)

        async def _execute_with_retry(self, fn):
            return fn()

    h = Harness(db_path)

    async def go():
        for x in hashes:
            ok, msg = await h.delete(x)
            assert ok, msg

    asyncio.run(go())
    h.conn.close()


def test_apply_matches_upstream_delete_exactly(tmp_path):
    a = make_db(tmp_path / "a.db")
    b = make_db(tmp_path / "b.db")
    seeded(a)
    seeded(b)
    upstream_delete(b, ["sa", "sb", "sc"])
    assert run(["--db", str(a), "--apply"], tmp_path) == 0

    def norm(path):
        mem, emb, graph, fts = state(path)
        mem = [(i, h, d is not None, t, c, m) for i, h, d, t, c, m in mem]
        return mem, emb, graph, fts

    assert norm(a) == norm(b)
    # and deleted_at has the same type/magnitude as upstream's
    ca, cb = connect(a), connect(b)
    qa = ca.execute("SELECT typeof(deleted_at) FROM memories WHERE content_hash='sa'").fetchone()
    qb = cb.execute("SELECT typeof(deleted_at) FROM memories WHERE content_hash='sa'").fetchone()
    assert qa == qb == ("real",)
    ca.close(); cb.close()


def test_apply_makes_backup_manifest_ledger_and_log(db, tmp_path):
    seeded(db)
    assert run(["--db", str(db), "--apply"], tmp_path) == 0
    backups = list((tmp_path / "backups").glob("sqlite_vec-presweep-*.db"))
    assert len(backups) == 1
    bc = connect(backups[0])
    assert bc.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    # the backup still holds the pre-sweep live rows
    assert bc.execute("SELECT count(*) FROM memories WHERE deleted_at IS NULL").fetchone()[0] == 5
    bc.close()

    manifests = list((tmp_path / "manifests").glob("sweep-*.jsonl"))
    assert len(manifests) == 1
    recs = [json.loads(l) for l in manifests[0].read_text().splitlines()]
    assert {r["hash"] for r in recs} == {"sa", "sb", "sc"}
    r = {x["hash"]: x for x in recs}["sa"]
    for key in ("rule", "tags", "created", "last_accessed", "snippet"):
        assert key in r
    assert r["rule"] == "A"
    assert len(r["snippet"]) <= 160

    ledger = [json.loads(l) for l in (tmp_path / "manifests" / "ledger.jsonl").read_text().splitlines()]
    assert len(ledger) == 1
    assert ledger[0]["swept"] == 3
    assert ledger[0]["graph_rows_deleted"] == 4
    assert ledger[0]["manifest"] == str(manifests[0])

    log = (tmp_path / "sweep.log").read_text().strip().splitlines()
    assert len(log) == 1
    assert " OK: " in log[0] and "swept=3" in log[0] and "A=1" in log[0]


def test_apply_with_no_candidates_does_nothing(db, tmp_path):
    populate(db, h="k1", tags="misc", created_days=5, access_count=0)
    assert run(["--db", str(db), "--apply"], tmp_path) == 0
    assert not (tmp_path / "backups").exists()
    assert not (tmp_path / "manifests").exists()
    assert "swept=0" in (tmp_path / "sweep.log").read_text()


def test_apply_aborts_when_backup_fails_integrity(db, tmp_path, monkeypatch):
    seeded(db)
    monkeypatch.setattr(ms, "integrity_ok", lambda path: False)
    before = state(db)
    assert run(["--db", str(db), "--apply"], tmp_path) == 1
    assert state(db) == before
    assert list((tmp_path / "backups").glob("*")) == []  # bad backup removed
    assert "FAIL" in (tmp_path / "sweep.log").read_text()


def test_manifest_is_written_before_any_delete(db, tmp_path, monkeypatch):
    seeded(db)

    def boom(*a, **kw):
        raise sqlite3.OperationalError("simulated delete failure")

    monkeypatch.setattr(ms, "soft_delete_rows", boom)
    before = state(db)
    assert run(["--db", str(db), "--apply"], tmp_path) == 1
    assert state(db) == before
    manifests = list((tmp_path / "manifests").glob("sweep-*.jsonl"))
    assert len(manifests) == 1 and len(manifests[0].read_text().splitlines()) == 3
    assert not (tmp_path / "manifests" / "ledger.jsonl").exists()


def test_failed_delete_rolls_back_atomically(db, tmp_path, monkeypatch):
    seeded(db)
    real = ms.soft_delete_one
    calls = {"n": 0}

    def flaky(conn, cand, now):
        calls["n"] += 1
        if calls["n"] == 2:
            raise sqlite3.OperationalError("disk I/O error")
        return real(conn, cand, now)

    monkeypatch.setattr(ms, "soft_delete_one", flaky)
    before = state(db)
    assert run(["--db", str(db), "--apply"], tmp_path) == 1
    assert state(db) == before


def test_safety_cap_aborts_large_sweeps_unless_forced(db, tmp_path, monkeypatch):
    monkeypatch.setattr(ms, "MAX_SWEEP_FLOOR", 3)
    conn = connect(db)
    for i in range(6):
        add_mem(conn, f"v{i}", tags="wazuh", created_days=300, access_count=1)
    add_mem(conn, "live", tags="misc", created_days=1, access_count=1)
    conn.close()
    before = state(db)
    assert run(["--db", str(db), "--apply"], tmp_path) == 1
    assert state(db) == before
    assert "cap" in (tmp_path / "sweep.log").read_text()
    assert run(["--db", str(db), "--apply", "--force"], tmp_path) == 0
    mem = state(db)[0]
    assert sum(1 for m in mem if m[2] is not None) == 6


def test_presweep_backups_are_rotated(db, tmp_path):
    bk = tmp_path / "backups"
    bk.mkdir()
    for i in range(ms.KEEP_PRESWEEP_BACKUPS + 3):
        p = bk / f"sqlite_vec-presweep-2026010{i % 10}-0000{i:02d}.db"
        p.write_bytes(b"x")
        os.utime(p, (1000 + i, 1000 + i))
    other = bk / "sqlite_vec-auto-20260101-000000.db"
    other.write_bytes(b"x")
    seeded(db)
    assert run(["--db", str(db), "--apply"], tmp_path) == 0
    assert other.exists()
    assert len(list(bk.glob("sqlite_vec-presweep-*.db"))) == ms.KEEP_PRESWEEP_BACKUPS


# --------------------------------------------------------------------------
# restore
# --------------------------------------------------------------------------


def test_restore_round_trip(db, tmp_path):
    seeded(db)
    conn = connect(db)
    emb_before = dict(conn.execute("SELECT rowid, content_embedding FROM memory_embeddings").fetchall())
    graph_before = conn.execute("SELECT * FROM memory_graph ORDER BY 1,2").fetchall()
    ids_before = dict(conn.execute("SELECT content_hash, id FROM memories").fetchall())
    conn.close()

    assert run(["--db", str(db), "--apply"], tmp_path) == 0
    manifest = next((tmp_path / "manifests").glob("sweep-*.jsonl"))
    assert run(["--db", str(db), "--restore", str(manifest)], tmp_path) == 0

    conn = connect(db)
    assert conn.execute("SELECT count(*) FROM memories WHERE deleted_at IS NOT NULL").fetchone()[0] == 0
    emb_after = dict(conn.execute("SELECT rowid, content_embedding FROM memory_embeddings").fetchall())
    assert emb_after == emb_before
    assert conn.execute("SELECT * FROM memory_graph ORDER BY 1,2").fetchall() == graph_before
    assert dict(conn.execute("SELECT content_hash, id FROM memories").fetchall()) == ids_before
    conn.close()
    # and the swept rows are selectable again, i.e. they are fully live
    assert set(selected(db)) == {"sa", "sb", "sc"}


def test_restore_skips_live_and_unknown_hashes(db, tmp_path):
    seeded(db)
    manifest = tmp_path / "m.jsonl"
    manifest.write_text(
        json.dumps({"hash": "keep2"}) + "\n" + json.dumps({"hash": "ghost"}) + "\n\n"
    )
    before = state(db)
    assert run(["--db", str(db), "--restore", str(manifest)], tmp_path) == 0
    assert state(db) == before
    assert "restored=0" in (tmp_path / "sweep.log").read_text()


def test_restore_without_embedding_in_manifest_still_clears_deleted_at(db, tmp_path):
    populate(db, h="z1", tags="wazuh", created_days=300, access_count=0, deleted=True)
    manifest = tmp_path / "m.jsonl"
    manifest.write_text(json.dumps({"hash": "z1"}) + "\n")
    assert run(["--db", str(db), "--restore", str(manifest)], tmp_path) == 0
    conn = connect(db)
    assert conn.execute("SELECT deleted_at FROM memories WHERE content_hash='z1'").fetchone()[0] is None
    conn.close()
    assert "no-embedding=1" in (tmp_path / "sweep.log").read_text()


def test_restore_bad_manifest_path_is_exit_1(db, tmp_path):
    assert run(["--db", str(db), "--restore", str(tmp_path / "missing.jsonl")], tmp_path) == 1


def test_restore_malformed_line_is_exit_1_and_changes_nothing(db, tmp_path):
    seeded(db)
    run(["--db", str(db), "--apply"], tmp_path)
    manifest = next((tmp_path / "manifests").glob("sweep-*.jsonl"))
    good = manifest.read_text()
    manifest.write_text(good + "{broken\n")
    before = state(db)
    assert run(["--db", str(db), "--restore", str(manifest)], tmp_path) == 1
    assert state(db) == before


def test_mode_flags_are_mutually_exclusive(db, tmp_path):
    with pytest.raises(SystemExit):
        run(["--db", str(db), "--apply", "--restore", "x.jsonl"], tmp_path)


# --------------------------------------------------------------------------
# canary compatibility (memory-health-canary.sh)
# --------------------------------------------------------------------------


def run_canary(tmp_path, db_path, state_obj, ledger_lines):
    stub = tmp_path / "stubbin"
    stub.mkdir(exist_ok=True)
    (stub / "osascript").write_text("#!/bin/sh\nexit 0\n")
    (stub / "osascript").chmod(0o755)
    state_path = tmp_path / "canary-state.json"
    state_path.write_text(json.dumps(state_obj))
    ledger = tmp_path / "ledger.jsonl"
    ledger.write_text("".join(json.dumps(x) + "\n" for x in ledger_lines))
    log = tmp_path / "canary.log"
    env = dict(
        os.environ,
        PATH=f"{stub}:{os.environ['PATH']}",
        CANARY_DB=str(db_path),
        CANARY_STATE=str(state_path),
        CANARY_LOG=str(log),
        CANARY_SWEEP_LEDGER=str(ledger),
        CANARY_ARCHIVE_DIR=str(tmp_path / "no-archives"),
        CANARY_PY=sys.executable,
    )
    subprocess.run(["bash", str(CANARY)], env=env, check=True, capture_output=True, timeout=120)
    return log.read_text() if log.exists() else "", json.loads(state_path.read_text())


@pytest.mark.skipif(subprocess.run(["which", "jq"], capture_output=True).returncode != 0, reason="jq missing")
class TestCanary:
    def canary_db(self, tmp_path, n_live):
        p = make_db(tmp_path / "canary.db")
        conn = connect(p)
        for i in range(n_live):
            add_mem(conn, f"c{i}", tags="misc", created_days=1, access_count=1)
        conn.close()
        return p

    def test_unexplained_drop_still_fails(self, tmp_path):
        p = self.canary_db(tmp_path, 10)
        log, _ = run_canary(tmp_path, p, {"memory_count_hwm": 30, "graph_count_hwm": 0, "last_run": "2026-01-01T00:00:00Z"}, [])
        assert "memory count dropped" in log

    def test_recorded_sweep_explains_drop(self, tmp_path):
        p = self.canary_db(tmp_path, 10)
        led = [{"epoch": time.time() - 60, "swept": 20, "graph_rows_deleted": 0, "restored": 0}]
        log, st = run_canary(tmp_path, p, {"memory_count_hwm": 30, "graph_count_hwm": 0, "last_run": "2026-01-01T00:00:00Z"}, led)
        assert "memory count dropped" not in log
        assert st["memory_count_hwm"] == 10  # hwm lowered by the swept count

    def test_sweep_before_last_run_is_not_counted_twice(self, tmp_path):
        p = self.canary_db(tmp_path, 10)
        led = [{"epoch": 1_700_000_000, "swept": 20, "graph_rows_deleted": 0}]
        log, _ = run_canary(tmp_path, p, {"memory_count_hwm": 30, "graph_count_hwm": 0, "last_run": "2026-01-01T00:00:00Z"}, led)
        assert "memory count dropped" in log

    def test_partial_explanation_still_fails(self, tmp_path):
        p = self.canary_db(tmp_path, 10)
        led = [{"epoch": time.time() - 60, "swept": 5, "graph_rows_deleted": 0}]
        log, _ = run_canary(tmp_path, p, {"memory_count_hwm": 30, "graph_count_hwm": 0, "last_run": "2026-01-01T00:00:00Z"}, led)
        assert "memory count dropped" in log

    def test_graph_rows_removed_by_sweep_are_explained(self, tmp_path):
        p = self.canary_db(tmp_path, 10)
        led = [{"epoch": time.time() - 60, "swept": 0, "graph_rows_deleted": 500}]
        log, _ = run_canary(tmp_path, p, {"memory_count_hwm": 10, "graph_count_hwm": 500, "last_run": "2026-01-01T00:00:00Z"}, led)
        assert "memory_graph shrank" not in log


# --------------------------------------------------------------------------
# review follow-ups
# --------------------------------------------------------------------------


def second_connection_is_blocked(db_path) -> bool:
    """True when another connection cannot take the write lock right now."""
    other = sqlite3.connect(str(db_path), timeout=0, isolation_level=None)
    try:
        other.execute("BEGIN IMMEDIATE")
        other.execute("ROLLBACK")
        return False
    except sqlite3.OperationalError:
        return True
    finally:
        other.close()


def test_backup_then_lock_then_select_capture_and_manifest_inside_one_transaction(db, tmp_path, monkeypatch):
    seeded(db)
    events = []
    real_backup = ms.make_backup
    real_select = ms.select_candidates
    real_capture = ms.capture_restore_data
    real_manifest = ms.write_manifest
    real_delete = ms.soft_delete_rows

    monkeypatch.setattr(ms, "make_backup", lambda *a, **k: (events.append(("backup", second_connection_is_blocked(db))), real_backup(*a, **k))[1])
    monkeypatch.setattr(ms, "select_candidates", lambda *a, **k: (events.append(("select", second_connection_is_blocked(db))), real_select(*a, **k))[1])
    monkeypatch.setattr(ms, "capture_restore_data", lambda *a, **k: (events.append(("capture", second_connection_is_blocked(db))), real_capture(*a, **k))[1])
    monkeypatch.setattr(ms, "write_manifest", lambda *a, **k: (events.append(("manifest", second_connection_is_blocked(db))), real_manifest(*a, **k))[1])
    monkeypatch.setattr(ms, "soft_delete_rows", lambda *a, **k: (events.append(("delete", second_connection_is_blocked(db))), real_delete(*a, **k))[1])

    assert run(["--db", str(db), "--apply"], tmp_path) == 0
    names = [e[0] for e in events]
    assert names.index("backup") < names.index("select", names.index("backup"))
    locked_phase = [e for e in events if e[0] in ("capture", "manifest", "delete")]
    assert locked_phase and all(blocked for _, blocked in locked_phase)
    backup_ev = [e for e in events if e[0] == "backup"][0]
    assert backup_ev[1] is False  # backup is taken before the write lock
    # the authoritative (last) selection runs under the lock
    last_select = [e for e in events if e[0] == "select"][-1]
    assert last_select[1] is True


def test_row_touched_between_preview_and_lock_is_not_swept(db, tmp_path, monkeypatch):
    seeded(db)
    real_select = ms.select_candidates
    calls = {"n": 0}

    def racing(conn, now):
        calls["n"] += 1
        out = real_select(conn, now)
        if calls["n"] == 1:  # after the preview, a search touches "sc"
            other = sqlite3.connect(str(db))
            other.execute(
                "UPDATE memories SET metadata = ? WHERE content_hash = 'sc'",
                (json.dumps({"access_count": 5, "last_accessed_at": NOW}),),
            )
            other.commit()
            other.close()
        return out

    monkeypatch.setattr(ms, "select_candidates", racing)
    assert run(["--db", str(db), "--apply"], tmp_path) == 0
    deleted = {m[1] for m in state(db)[0] if m[2] is not None}
    assert deleted == {"sa", "sb"}
    recs = [json.loads(l) for l in next((tmp_path / "manifests").glob("sweep-*.jsonl")).read_text().splitlines()]
    assert {r["hash"] for r in recs} == {"sa", "sb"}


def test_cap_is_rechecked_inside_the_transaction(db, tmp_path, monkeypatch):
    monkeypatch.setattr(ms, "MAX_SWEEP_FLOOR", 3)
    conn = connect(db)
    add_mem(conn, "only", tags="wazuh", created_days=300, access_count=1)
    for i in range(20):
        add_mem(conn, f"live{i}", tags="misc", created_days=1, access_count=1)
    conn.close()
    real_select = ms.select_candidates
    calls = {"n": 0}

    def racing(c, now):
        calls["n"] += 1
        if calls["n"] == 1:
            out = real_select(c, now)
            other = connect(db)
            for i in range(10):  # a flood of sweepable rows lands before the lock
                add_mem(other, f"flood{i}", tags="wazuh", created_days=300, access_count=1)
            other.close()
            return out
        return real_select(c, now)

    monkeypatch.setattr(ms, "select_candidates", racing)
    before_deleted = 0
    assert run(["--db", str(db), "--apply"], tmp_path) == 1
    assert sum(1 for m in state(db)[0] if m[2] is not None) == before_deleted
    assert "cap" in (tmp_path / "sweep.log").read_text()
    assert list((tmp_path / "manifests").glob("sweep-*.jsonl")) == []


# restore must not link a restored row to a still-deleted neighbour -------------


def test_restore_skips_edges_to_still_deleted_memories(db, tmp_path):
    conn = connect(db)
    add_mem(conn, "ra", tags="wazuh", created_days=300, accessed_days=200, access_count=2, graph_to=["rb", "keepx", "ent:Wazuh"])
    add_mem(conn, "rb", tags="wazuh", created_days=300, accessed_days=200, access_count=2)
    add_mem(conn, "keepx", tags="gotcha", created_days=300, access_count=1)
    conn.close()
    assert run(["--db", str(db), "--apply"], tmp_path) == 0
    manifest = next((tmp_path / "manifests").glob("sweep-*.jsonl"))
    only_ra = tmp_path / "only-ra.jsonl"
    only_ra.write_text("".join(l + "\n" for l in manifest.read_text().splitlines() if json.loads(l)["hash"] == "ra"))
    assert run(["--db", str(db), "--restore", str(only_ra)], tmp_path) == 0
    conn = connect(db)
    edges = {tuple(r) for r in conn.execute("SELECT source_hash, target_hash FROM memory_graph")}
    conn.close()
    assert ("ra", "rb") not in edges  # rb is still soft-deleted
    assert ("ra", "keepx") in edges
    assert ("ra", "ent:Wazuh") in edges  # entity-name target, not a memory hash


def test_restoring_both_ends_restores_the_shared_edge(db, tmp_path):
    conn = connect(db)
    add_mem(conn, "ra", tags="wazuh", created_days=300, accessed_days=200, access_count=2, graph_to=["rb"])
    add_mem(conn, "rb", tags="wazuh", created_days=300, accessed_days=200, access_count=2)
    conn.close()
    run(["--db", str(db), "--apply"], tmp_path)
    manifest = next((tmp_path / "manifests").glob("sweep-*.jsonl"))
    assert run(["--db", str(db), "--restore", str(manifest)], tmp_path) == 0
    conn = connect(db)
    edges = {tuple(r) for r in conn.execute("SELECT source_hash, target_hash FROM memory_graph")}
    conn.close()
    assert ("ra", "rb") in edges


# failure notifications ------------------------------------------------------------


def test_apply_failure_paths_notify(db, tmp_path, notifications, monkeypatch):
    seeded(db)
    monkeypatch.setattr(ms, "integrity_ok", lambda path: False)
    assert run(["--db", str(db), "--apply"], tmp_path) == 1
    assert len(notifications) == 1 and "integrity" in notifications[0]


def test_apply_missing_db_notifies(tmp_path, notifications):
    assert run(["--db", str(tmp_path / "nope.db"), "--apply"], tmp_path) == 1
    assert len(notifications) == 1


def test_apply_unexpected_exception_notifies_and_exits_1(db, tmp_path, notifications, monkeypatch):
    seeded(db)
    monkeypatch.setattr(ms, "soft_delete_rows", lambda *a, **k: (_ for _ in ()).throw(ValueError("boom")))
    assert run(["--db", str(db), "--apply"], tmp_path) == 1
    assert len(notifications) == 1 and "boom" in notifications[0]


def test_apply_success_and_dry_run_do_not_notify(db, tmp_path, notifications):
    seeded(db)
    assert run(["--db", str(db)], tmp_path) == 0
    assert run(["--db", str(db), "--apply"], tmp_path) == 0
    assert run(["--db", str(tmp_path / "nope.db")], tmp_path) == 1  # dry run failure
    assert notifications == []


def test_notify_failure_calls_osascript_with_title(tmp_path, monkeypatch):
    monkeypatch.undo()  # drop the autouse stub for this test
    real = _load_module().notify_failure
    stub = tmp_path / "bin"
    stub.mkdir()
    out = tmp_path / "argv.txt"
    (stub / "osascript").write_text(f'#!/bin/sh\nprintf "%s\\n" "$@" > "{out}"\n')
    (stub / "osascript").chmod(0o755)
    monkeypatch.setenv("PATH", f"{stub}:{os.environ['PATH']}")
    real('disk "full" \\ now')
    text = out.read_text()
    assert "Memory sweep FAILED" in text
    assert 'disk \\"full\\" \\\\ now' in text  # quotes and backslashes escaped for AppleScript


def test_notify_failure_ignores_errors(tmp_path, monkeypatch):
    monkeypatch.undo()
    real = _load_module().notify_failure
    monkeypatch.setenv("PATH", str(tmp_path))  # no osascript at all
    real("anything")  # must not raise


# protected suffix tags -------------------------------------------------------------


@pytest.mark.parametrize("tag", ["clickhouse-gotchas", "fastmcp-gotcha", "architecture-decision", "design-decisions", "ClickHouse-Gotchas"])
def test_tags_ending_in_gotcha_or_decision_are_protected(db, tag):
    populate(db, h="sfx", tags=f"clickhouse,{tag}", created_days=500, access_count=0)
    assert selected(db) == {}


def test_similar_but_not_suffix_tags_are_not_protected(db):
    populate(db, h="nsfx", tags="wazuh,decision-framework,gotcha-ish", created_days=500, access_count=0)
    assert selected(db)["nsfx"]["rule"] == "A"


# relative log file ---------------------------------------------------------------


def test_relative_log_file_path_works(db, tmp_path, monkeypatch):
    populate(db, h="k1", tags="misc", created_days=5, access_count=0)
    monkeypatch.chdir(tmp_path)
    rc = ms.main(["--db", str(db), "--apply", "--backup-dir", str(tmp_path / "b"),
                  "--manifest-dir", str(tmp_path / "m"), "--log-file", "rel.log"], now=NOW)
    assert rc == 0
    assert "swept=0" in (tmp_path / "rel.log").read_text()


def test_docstring_documents_access_count_caveat():
    assert "retrieve()" in ms.__doc__ and "never used" in ms.__doc__.lower()
