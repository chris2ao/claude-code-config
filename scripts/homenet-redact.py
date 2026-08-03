#!/usr/bin/env python3
"""Produce a redacted parallel copy of HomeNetwork/ for NotebookLM upload.

Inputs:
  argv[1]: source dir (typically /Users/chris2ao/GitProjects/CJClaudin_Mac/HomeNetwork)
  argv[2]: destination dir (typically ~/.claude/state/homenet-redacted/<ts>/)
  argv[3] (optional): snapshot JSON path. If provided, every secret value found
          in the snapshot is added to the redaction list as an exact-string match,
          which catches secrets that the regex patterns might miss.

Replaces every detected secret in .md files with [REDACTED-<kind>-<sha8>] where
sha8 is the first 8 hex chars of sha256(secret). Reuses the same redaction token
across files so cross-references stay coherent.

Non-markdown files (PNGs, etc.) are copied verbatim. The .notebooklm-id file
is skipped entirely.

Reports the count of redactions and the unique secret count.
"""
from __future__ import annotations

import hashlib
import json
import re
import shutil
import sys
from pathlib import Path
from typing import Iterable

# (kind, regex). Each pattern's group(1) is the secret value to redact.
# Order matters: more specific patterns first.
REGEX_PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("psk", re.compile(r"(?i)\b(?:x_passphrase|passphrase|psk|preshared[_-]?key|wpa[_-]?psk)\b\s*[:=]\s*[\"']?([^\s\"',|]{8,})")),
    ("ppsk-pwd", re.compile(r"(?i)\b(?:password|pwd|ppsk[_-]?password)\b\s*[:=]\s*[\"']?([^\s\"',|]{8,})")),
    ("radius-secret", re.compile(r"(?i)\b(?:x_secret|shared[_-]?secret|radius[_-]?secret)\b\s*[:=]\s*[\"']?([^\s\"',|]{6,})")),
    ("api-key", re.compile(r"(?i)\b(?:x_api_key|api[_-]?key|apikey|access[_-]?token|bearer)\b\s*[:=]\s*[\"']?([A-Za-z0-9._\-]{20,})")),
    ("token-long", re.compile(r"\b([A-Za-z0-9_\-]{40,})\b")),  # last-resort: long opaque string
]

# Snapshot JSON keys whose values are always treated as secrets, regardless of context.
SNAPSHOT_SECRET_KEYS = {
    "x_passphrase",
    "passphrase",
    "x_secret",
    "x_api_key",
    "api_key",
    "password",
    "preshared_key",
    "wpa_psk",
    "shared_secret",
    "radius_secret",
}


def sha8(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()[:8]


def collect_snapshot_secrets(snapshot_path: Path) -> dict[str, str]:
    """Return {secret_value: kind} extracted from a snapshot JSON.

    Walks all keys recursively. Anything keyed by a name in SNAPSHOT_SECRET_KEYS
    with a non-empty string value is collected.
    """
    result: dict[str, str] = {}
    if not snapshot_path or not snapshot_path.exists():
        return result
    try:
        with snapshot_path.open() as f:
            data = json.load(f)
    except json.JSONDecodeError:
        return result

    def walk(obj):
        if isinstance(obj, dict):
            for k, v in obj.items():
                if k in SNAPSHOT_SECRET_KEYS and isinstance(v, str) and v.strip():
                    kind = "psk" if "phrase" in k or "psk" in k else (
                        "radius-secret" if "secret" in k or "radius" in k else (
                            "api-key" if "api" in k or "key" in k else "ppsk-pwd"
                        )
                    )
                    result.setdefault(v, kind)
                else:
                    walk(v)
        elif isinstance(obj, list):
            for item in obj:
                walk(item)

    walk(data)
    return result


def redact_text(text: str, snapshot_secrets: dict[str, str], counters: dict[str, int]) -> str:
    """Apply snapshot-string and regex-based redactions, in that order."""
    # Snapshot-string substitutions: exact matches everywhere.
    for value, kind in snapshot_secrets.items():
        if not value or value not in text:
            continue
        token = f"[REDACTED-{kind}-{sha8(value)}]"
        count = text.count(value)
        if count:
            text = text.replace(value, token)
            counters["snapshot"] = counters.get("snapshot", 0) + count

    # Regex-based fallbacks for anything the snapshot missed.
    for kind, pattern in REGEX_PATTERNS:
        def _sub(m: re.Match[str]) -> str:
            value = m.group(1)
            # Skip if already a redaction token
            if value.startswith("[REDACTED-"):
                return m.group(0)
            # Skip values already redacted via snapshot pass
            if any(value in k for k in snapshot_secrets):
                return m.group(0)
            token = f"[REDACTED-{kind}-{sha8(value)}]"
            counters[kind] = counters.get(kind, 0) + 1
            return m.group(0).replace(value, token)
        text = pattern.sub(_sub, text)

    return text


def iter_files(src: Path) -> Iterable[Path]:
    for p in src.rglob("*"):
        if p.is_file():
            yield p


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "usage: homenet-redact.py <source-dir> <dest-dir> [snapshot.json]",
            file=sys.stderr,
        )
        return 1

    src = Path(sys.argv[1]).expanduser().resolve()
    dst = Path(sys.argv[2]).expanduser().resolve()
    snapshot_path = Path(sys.argv[3]).expanduser().resolve() if len(sys.argv) > 3 else None

    if not src.is_dir():
        print(f"ERROR: source not a dir: {src}", file=sys.stderr)
        return 1
    dst.mkdir(parents=True, exist_ok=True)

    snapshot_secrets = collect_snapshot_secrets(snapshot_path) if snapshot_path else {}
    print(f"Snapshot secrets collected: {len(snapshot_secrets)}")

    counters: dict[str, int] = {}
    files_redacted = 0
    files_copied = 0

    for src_file in iter_files(src):
        rel = src_file.relative_to(src)
        if rel.name == ".notebooklm-id":
            continue  # never publish the notebook ID
        dst_file = dst / rel
        dst_file.parent.mkdir(parents=True, exist_ok=True)
        if src_file.suffix == ".md":
            text = src_file.read_text(encoding="utf-8")
            redacted = redact_text(text, snapshot_secrets, counters)
            dst_file.write_text(redacted, encoding="utf-8")
            files_redacted += 1
        else:
            shutil.copy2(src_file, dst_file)
            files_copied += 1

    total_redactions = sum(counters.values())
    print(f"Markdown files processed: {files_redacted}")
    print(f"Other files copied: {files_copied}")
    print(f"Total redactions: {total_redactions}")
    for k, v in sorted(counters.items()):
        print(f"  {k}: {v}")
    print(f"Output: {dst}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
