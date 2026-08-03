#!/usr/bin/env /opt/homebrew/bin/python3.11
"""
Rebuild memory_graph entity links (relationship_type='has_entity').

WHY THIS EXISTS
  mcp-memory-service 10.74.1 has an upstream bug: storage/graph.py store_entity_link()
  writes entity links with target_hash = the entity NAME (e.g. "Next.js"), while
  consolidation/consolidator.py _prune_orphaned_graph_edges() deletes every row whose
  target_hash is not a live content_hash in `memories`. An entity name never is, so
  EVERY consolidation run deletes 100% of entity links. 1011 links were lost on
  2026-07-26 and the loss went unnoticed for 6 days.

  This script re-derives the links from memory content. It is idempotent
  (INSERT OR IGNORE) and never deletes or modifies a memory.

  Run it AFTER consolidation (consolidation is Sun 03:00, so schedule this Sun 04:00).
  It survives `pip install -U mcp-memory-service`, unlike a site-packages patch.

EXIT CODES
  0 ok, 1 failure (safe to retry; nothing is deleted on failure)
"""

import os
import sqlite3
import sys
from datetime import datetime, timezone

DB = os.path.expanduser("~/Library/Application Support/mcp-memory/sqlite_vec.db")


def log(msg: str) -> None:
    print(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} {msg}", flush=True)


def main() -> int:
    if not os.path.exists(DB):
        log(f"FAIL: database not found at {DB}")
        return 1

    try:
        from mcp_memory_service.reasoning.entities import EntityExtractor
    except Exception as e:  # noqa: BLE001
        log(f"FAIL: cannot import EntityExtractor: {e}")
        return 1

    try:
        conn = sqlite3.connect(DB, timeout=30.0)
        conn.row_factory = sqlite3.Row
    except sqlite3.Error as e:
        log(f"FAIL: cannot open database: {e}")
        return 1

    try:
        before = conn.execute(
            "SELECT COUNT(*) FROM memory_graph WHERE relationship_type='has_entity'"
        ).fetchone()[0]

        rows = conn.execute(
            "SELECT content_hash, content, tags FROM memories WHERE deleted_at IS NULL"
        ).fetchall()

        extractor = EntityExtractor()
        stored = 0
        scanned = 0
        now = datetime.now(timezone.utc).timestamp()

        for row in rows:
            scanned += 1
            try:
                entities = extractor.extract_entities(row["content"], None)
            except Exception:  # noqa: BLE001
                # One bad memory must not abort the whole rebuild.
                continue
            for ent in entities:
                name = getattr(ent, "name", None)
                if not name:
                    continue
                etype = getattr(ent, "entity_type", "unknown")
                conn.execute(
                    """
                    INSERT OR IGNORE INTO memory_graph
                      (source_hash, target_hash, similarity, connection_types,
                       metadata, created_at, relationship_type)
                    VALUES (?, ?, 1.0, '["entity"]', ?, ?, 'has_entity')
                    """,
                    (
                        row["content_hash"],
                        name,
                        f'{{"entity_type": "{etype}"}}',
                        now,
                    ),
                )
                stored += 1

        conn.commit()
        after = conn.execute(
            "SELECT COUNT(*) FROM memory_graph WHERE relationship_type='has_entity'"
        ).fetchone()[0]

        log(f"OK: scanned={scanned} extracted={stored} links {before} -> {after}")

        # Loud warning if consolidation has clearly wiped links since last run.
        if before == 0 and after > 0:
            log("NOTE: entity links were at ZERO before this run (consolidation wipe).")
        return 0
    except sqlite3.Error as e:
        log(f"FAIL: sqlite error: {e}")
        return 1
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main())
