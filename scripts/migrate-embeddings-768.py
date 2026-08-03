#!/usr/bin/env python3.11
"""Rebuild memory_embeddings as FLOAT[768] using Ollama nomic-embed-text.

Run ONLY while no Claude Code session / mcp_memory_service process is running.
The whole rebuild is one transaction: any failure rolls back to the 384d table.
"""
import json
import math
import re
import sqlite3
import subprocess
import sys
import urllib.error
import urllib.request

DB = "/Users/chris2ao/Library/Application Support/mcp-memory/sqlite_vec.db"
OLLAMA_URL = "http://localhost:11434/v1/embeddings"
MODEL = "nomic-embed-text"
DIM = 768
BATCH = 16
# Ollama's /v1/embeddings rejects inputs beyond the model context length
# instead of truncating (verified: 10.8k chars -> HTTP 400, 8k chars -> ok).
# Truncation applies to the embedding INPUT only; stored content is untouched.
EMBED_MAX_CHARS = 8000


def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def embed_batch(texts):
    safe_texts = []
    for t in texts:
        t = t if isinstance(t, str) and t.strip() else "(empty memory)"
        if len(t) > EMBED_MAX_CHARS:
            print(f"  truncating one embedding input from {len(t)} to {EMBED_MAX_CHARS} chars")
            t = t[:EMBED_MAX_CHARS]
        safe_texts.append(t)
    payload = json.dumps({"model": MODEL, "input": safe_texts}).encode()
    req = urllib.request.Request(
        OLLAMA_URL, data=payload, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = json.load(resp)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode(errors="replace")[:300]
        raise RuntimeError(f"Ollama HTTP {exc.code}: {body}") from exc
    rows = sorted(data["data"], key=lambda d: d["index"])
    vectors = [r["embedding"] for r in rows]
    for v in vectors:
        if len(v) != DIM:
            fail(f"unexpected dimension {len(v)}, wanted {DIM}")
        if any(math.isnan(x) or math.isinf(x) for x in v):
            fail("embedding contains NaN or inf")
    return vectors


def main():
    holders = subprocess.run(["lsof", "-t", DB], capture_output=True, text=True)
    if holders.stdout.strip():
        fail(f"database is open by pid(s) {holders.stdout.split()}; close Claude Code first")

    import sqlite_vec
    conn = sqlite3.connect(DB)
    conn.enable_load_extension(True)
    sqlite_vec.load(conn)
    conn.enable_load_extension(False)

    old_sql = conn.execute(
        "SELECT sql FROM sqlite_master WHERE name='memory_embeddings'").fetchone()
    if not old_sql:
        fail("memory_embeddings table not found")
    old_dim = int(re.search(r"FLOAT\[(\d+)\]", old_sql[0]).group(1))
    print(f"current embedding dimension: {old_dim}")
    if old_dim == DIM:
        print("already 768d, nothing to do")
        return

    existing = conn.execute("SELECT count(*) FROM memory_embeddings").fetchone()[0]
    rows = conn.execute(
        "SELECT id, content FROM memories WHERE deleted_at IS NULL ORDER BY id").fetchall()
    print(f"embeddings before: {existing}, live memories to embed: {len(rows)}")

    smoke = embed_batch(["dimension smoke test"])
    print(f"ollama ok, dimension {len(smoke[0])}")

    conn.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    try:
        conn.execute("BEGIN")
        conn.execute("DROP TABLE memory_embeddings")
        conn.execute(
            f"CREATE VIRTUAL TABLE memory_embeddings USING vec0("
            f"content_embedding FLOAT[{DIM}] distance_metric=cosine)")
        done = 0
        for i in range(0, len(rows), BATCH):
            chunk = rows[i:i + BATCH]
            vectors = embed_batch([c[1] for c in chunk])
            for (mem_id, _content), vec in zip(chunk, vectors):
                conn.execute(
                    "INSERT INTO memory_embeddings (rowid, content_embedding) VALUES (?, ?)",
                    (mem_id, sqlite_vec.serialize_float32(vec)))
            done += len(chunk)
            print(f"  {done}/{len(rows)}")
        conn.execute("COMMIT")
    except Exception as exc:
        conn.execute("ROLLBACK")
        fail(f"rebuild rolled back: {exc}")

    new_sql = conn.execute(
        "SELECT sql FROM sqlite_master WHERE name='memory_embeddings'").fetchone()[0]
    count = conn.execute("SELECT count(*) FROM memory_embeddings").fetchone()[0]
    conn.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    conn.close()
    print(f"done: {count} embeddings, schema: {new_sql.strip()}")
    if f"FLOAT[{DIM}]" not in new_sql:
        fail("schema does not show FLOAT[768] after rebuild")


if __name__ == "__main__":
    main()
