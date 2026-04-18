---
platform: portable
description: "Remove a Private Pre-Shared Key (PPSK) entry from an SSID (preview by default, --apply to commit, refuses to brick SSID)"
---

# /homenet-ppsk-remove

Revoke a PPSK entry from a PPSK-enabled SSID by its password. Idempotent: if the password isn't present, exits without changes.

**Safety rail**: refuses `--apply` if removing would leave 0 PPSK entries AND the SSID-level PSK is UniFi-auto-generated (i.e., unknown). In that case no device could join the SSID afterward. Override with `--force-empty` if you really mean to brick the SSID.

## Usage

Preview:
```bash
!bash "$HOME/.claude/scripts/homenet-ppsk-remove.sh" "<ssid>" "<password>"
```

Apply:
```bash
!bash "$HOME/.claude/scripts/homenet-ppsk-remove.sh" "<ssid>" "<password>" --apply
```

Force removal even if it leaves 0 entries:
```bash
!bash "$HOME/.claude/scripts/homenet-ppsk-remove.sh" "<ssid>" "<password>" --force-empty
```

## Examples

```bash
# Revoke a compromised PPSK
!bash "$HOME/.claude/scripts/homenet-ppsk-remove.sh" "LAN Solo" "CJpassword1023" --apply

# Remove the initial test entry once real entries are populated
!bash "$HOME/.claude/scripts/homenet-ppsk-remove.sh" "LAN Solo" "TestEntry-Apr2026" --apply
```

## Effect timing

- Removing a PPSK does not immediately disconnect currently-associated clients. They remain connected until next re-association (sleep/wake, roam, or explicit disconnect). Next join attempt with that password is rejected.
- To kick an associated client immediately, follow up with `mcp__unifi__reconnect_client <mac>` or a `/cmd/stamgr kick-sta` call against the device's current MAC.

## Audit logging

Like `/homenet-ppsk-add`, logs only a SHA-256 fingerprint prefix (not plaintext) to `HomeNetwork/investigations.md`:

```
### PPSK Revoked: LAN Solo
- 2026-04-18 10:22: removed entry sha256-prefix=`a1b2c3d4` (count 3 → 2)
```
