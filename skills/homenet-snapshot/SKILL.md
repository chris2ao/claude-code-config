---
platform: portable
description: "Snapshot all UniFi wlanconf (SSID) state to HomeNetwork/backups for rollback"
---

# /homenet-snapshot

Write a timestamped JSON snapshot of every Wi-Fi SSID's configuration (including MAC allowlists) to `~/.claude/state/homenet-backups/`. Use before any filter flip or allowlist mutation so we have a clean rollback point.

**Why not in the git repo?** Snapshots contain plaintext `x_passphrase` and PPSK `password` fields. Keeping them outside any tracked repo is defense-in-depth: even if `.gitignore` is lost or bypassed, the secrets can't be committed. Override with `HOMENET_BACKUP_DIR=<path>` if you have a specific reason, but never point it inside a git-tracked directory.

## Usage

```bash
!bash "$HOME/.claude/scripts/homenet-snapshot.sh" [reason]
```

The optional `reason` string (e.g. `pre-phase-1`, `pre-filter-on-streaming`) is embedded in the snapshot JSON for provenance.

## When to use

- Before turning on any MAC filter (`/homenet-filter on ...`)
- Before bulk allowlist edits
- At the start of each rollout phase
- Ad-hoc audit checkpoints

## Output

Prints the snapshot path, SSID count, and a one-line summary per SSID showing filter state and allowlist size.

## Restore

Manually: `cat HomeNetwork/backups/wlanconf-<ts>.json | jq '.wlans[]'` then PUT each back via the UniFi API. There's no skill for restore yet — keep snapshots even if you think the change was fine.
