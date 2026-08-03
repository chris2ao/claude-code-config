#!/usr/bin/env python3.11
"""One-off quality rescore: DeBERTa ONNX scores for all active memories.

Dry-run by default: prints before/after distributions, writes nothing.
Apply mode: timestamped .backup, single transaction, rollback on error.
Run ONLY inside the memory-p2-apply.sh window (servers down)."""
import argparse
import asyncio
import json
import math
import os
import sqlite3
import subprocess
import sys
from datetime import datetime
from pathlib import Path

DB = Path.home() / "Library/Application Support/mcp-memory/sqlite_vec.db"
BKDIR = DB.parent / "backups"
MAX_FAILURES = 5          # abort threshold for per-memory scoring errors
MIN_STDEV = 0.01          # refuse to write an all-flat result

# Env parity with the servers, set BEFORE importing package config modules
os.environ.setdefault("MCP_QUALITY_LOCAL_MODEL", "nvidia-quality-classifier-deberta")
os.environ.setdefault("MCP_QUALITY_BOOST_ENABLED", "true")
os.environ.setdefault("MCP_QUALITY_BOOST_WEIGHT", "0.25")

from mcp_memory_service.models.memory import Memory
from mcp_memory_service.quality.config import QualityConfig
from mcp_memory_service.quality.scorer import QualityScorer


def refuse_if_open():
    r = subprocess.run(["lsof", "-t", str(DB)], capture_output=True, text=True)
    pids = r.stdout.split()
    if pids:
        sys.exit(f"REFUSED: DB open by PID(s) {pids}. Run inside the apply window.")


def row_to_memory(row):
    rid, content, chash, tags, mtype, meta, cat, uat = row
    return rid, Memory(
        content=content, content_hash=chash,
        tags=[t for t in (tags or "").split(",") if t],
        memory_type=mtype, metadata=json.loads(meta or "{}"),
        created_at=cat, updated_at=uat)


def dist(scores, label):
    xs = [s for s in scores if s is not None]
    if not xs:
        print(f"{label}: no scores")
        return 0.0
    mean = sum(xs) / len(xs)
    sd = math.sqrt(sum((x - mean) ** 2 for x in xs) / len(xs))
    buckets = [0] * 10
    for x in xs:
        buckets[min(int(x * 10), 9)] += 1
    print(f"{label}: n={len(xs)} mean={mean:.3f} stdev={sd:.3f} hist={buckets}")
    return sd


async def score_all(pairs):
    scorer = QualityScorer(QualityConfig.from_env())   # local DeBERTa + implicit blend
    failures, out = 0, []
    for rid, mem in pairs:
        try:
            # calculate_quality_score writes quality_score/quality_provider/
            # quality_components/ai_scores into mem.metadata
            await scorer.calculate_quality_score(mem, query="")
            out.append((rid, mem))
        except Exception as e:
            failures += 1
            print(f"FAIL {mem.content_hash[:12]}: {e}", file=sys.stderr)
            if failures > MAX_FAILURES:
                sys.exit(f"ABORT: {failures} scoring failures exceeds threshold {MAX_FAILURES}; nothing written.")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write results (default: dry-run)")
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()

    refuse_if_open()
    conn = sqlite3.connect(DB)   # plain sqlite3: only memories.metadata is touched
    sql = ("SELECT id, content, content_hash, tags, memory_type, metadata, "
           "created_at, updated_at FROM memories WHERE deleted_at IS NULL")
    if args.limit:
        sql += f" LIMIT {args.limit}"
    pairs = [row_to_memory(r) for r in conn.execute(sql)]
    print(f"Loaded {len(pairs)} active memories")

    dist([m.metadata.get("quality_score") for _, m in pairs], "BEFORE")
    scored = asyncio.run(score_all(pairs))
    sd = dist([m.metadata.get("quality_score") for _, m in scored], "AFTER")
    if sd < MIN_STDEV:
        sys.exit(f"REFUSED: post-score stdev {sd:.4f} < {MIN_STDEV}, looks flat; nothing written.")
    if not args.apply:
        print("Dry-run complete. Re-run with --apply to write.")
        return

    BKDIR.mkdir(exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    bk = BKDIR / f"sqlite_vec-prequality-{stamp}.db"
    subprocess.run(["sqlite3", str(DB), f".backup '{bk}'"], check=True)
    print(f"Backup: {bk}")

    try:
        conn.execute("BEGIN IMMEDIATE")
        conn.executemany(
            "UPDATE memories SET metadata = ? WHERE id = ?",
            [(json.dumps(m.metadata), rid) for rid, m in scored])
        conn.commit()
    except Exception as e:
        conn.rollback()
        sys.exit(f"ROLLED BACK: {e}")

    n = conn.execute("SELECT count(*) FROM memories WHERE deleted_at IS NULL "
                     "AND json_extract(metadata,'$.quality_score') IS NOT NULL").fetchone()[0]
    print(f"Verified: {n} scored rows in DB")


if __name__ == "__main__":
    main()
