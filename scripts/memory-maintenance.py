#!/opt/homebrew/bin/python3.11
"""
memory-maintenance.py - Daily vector memory maintenance (zero API cost)

Runs directly against mcp-memory-service SQLite database.
Performs deduplication, consolidation, and scratchpad cleanup.

Required env vars (set in crontab):
  MCP_MEMORY_STORAGE_BACKEND=sqlite_vec
  MCP_OAUTH_ENABLED=false
  MCP_OAUTH_PRIVATE_KEY=disabled
  MCP_OAUTH_PUBLIC_KEY=disabled

Logs to: ~/.openclaw/logs/memory-maintenance.log
"""

import asyncio
import logging
import sys
import time
from datetime import datetime
from pathlib import Path

LOG_DIR = Path.home() / ".openclaw" / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("memory-maintenance")


async def run_dedup(storage):
    """Remove duplicate memories by content hash."""
    try:
        count, msg = await storage.cleanup_duplicates()
        log.info("Dedup: removed %d duplicates. %s", count, msg)
        return count
    except Exception as e:
        log.error("Dedup failed: %s", e)
        return 0


async def run_consolidation(storage):
    """Run dream-inspired consolidation (daily on weekdays, weekly on Sundays)."""
    try:
        from mcp_memory_service.consolidation import (
            ConsolidationConfig,
            DreamInspiredConsolidator,
        )

        horizon = "weekly" if datetime.now().weekday() == 6 else "daily"
        consolidator = DreamInspiredConsolidator(storage, ConsolidationConfig())
        report = await consolidator.consolidate(time_horizon=horizon)
        log.info("Consolidation (%s): %s", horizon, report)
        return report
    except ImportError:
        log.warning("Consolidation module not available, skipping")
        return None
    except Exception as e:
        log.error("Consolidation failed: %s", e)
        return None


def cleanup_scratchpads():
    """Delete session scratchpad files older than 24 hours."""
    scratchpad_dir = Path.home() / ".claude" / "session-state"
    if not scratchpad_dir.exists():
        log.info("Scratchpad dir does not exist, skipping cleanup")
        return 0

    cutoff = time.time() - 86400  # 24 hours ago
    removed = 0
    for f in scratchpad_dir.glob("*.md"):
        try:
            if f.stat().st_mtime < cutoff:
                f.unlink()
                removed += 1
                log.info("Removed stale scratchpad: %s", f.name)
        except OSError as e:
            log.warning("Could not remove %s: %s", f.name, e)

    log.info("Scratchpad cleanup: removed %d stale files", removed)
    return removed


async def main():
    log.info("=== Memory maintenance started ===")
    start = time.time()

    # Step 1: Scratchpad cleanup (no imports needed)
    cleanup_scratchpads()

    # Step 2: Database operations
    try:
        from mcp_memory_service.config import SQLITE_VEC_PATH
        from mcp_memory_service.storage.factory import create_storage_instance
    except ImportError as e:
        log.error(
            "Cannot import mcp-memory-service. Is it installed? %s", e
        )
        log.info(
            "=== Memory maintenance finished (scratchpad only) in %.1fs ===",
            time.time() - start,
        )
        return

    try:
        storage = await create_storage_instance(SQLITE_VEC_PATH)
    except Exception as e:
        log.error("Cannot connect to storage at %s: %s", SQLITE_VEC_PATH, e)
        return

    try:
        await run_dedup(storage)
        await run_consolidation(storage)
    finally:
        try:
            await storage.close()
        except Exception:
            pass

    elapsed = time.time() - start
    log.info("=== Memory maintenance finished in %.1fs ===", elapsed)


if __name__ == "__main__":
    asyncio.run(main())
