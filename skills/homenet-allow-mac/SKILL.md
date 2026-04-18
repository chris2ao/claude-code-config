---
platform: portable
description: "Add a MAC address to a UniFi SSID's allowlist (preview by default, --apply to commit)"
---

# /homenet-allow-mac

Adds a MAC to a specific SSID's `mac_filter_list` and labels the addition in `HomeNetwork/inventory.md`. Idempotent: if the MAC is already on the list, exits without changes.

## Usage

Preview (no change applied):
```bash
!bash "$HOME/.claude/scripts/homenet-allow-mac.sh" "<ssid-name>" "<mac>" "<label>"
```

Apply:
```bash
!bash "$HOME/.claude/scripts/homenet-allow-mac.sh" "<ssid-name>" "<mac>" "<label>" --apply
```

**MAC format**: `aa:bb:cc:dd:ee:ff` (lowercase hex, colon-separated). The script lowercases automatically but rejects other formats.

## Examples

```bash
# Approve Melinda's iPhone on the Streaming SSID
!bash "$HOME/.claude/scripts/homenet-allow-mac.sh" "Johnson Streaming Devices" "c0:17:54:98:d0:b6" "Melinda-iphone (allowlisted on streaming SSID)" --apply

# Add the Mac mini's Wi-Fi side to LAN of the Free
!bash "$HOME/.claude/scripts/homenet-allow-mac.sh" "The LAN of the Free" "9a:ac:8d:d5:fb:f8" "Mac mini Wi-Fi (session host)" --apply
```

## Preflight checklist

Before running with `--apply`:
1. `/homenet-snapshot` has been taken in the current session (ideally within the last hour).
2. The MAC is confirmed (not a guess, not a rotating privacy MAC that'll change).
3. The target device has Private MAC / Random MAC disabled for this SSID (if applicable).
4. You understand the filter is either OFF (pre-stage) or ON (live enforcement). Check `/homenet-review <ssid>` first if unsure.

## Side effects

- Appends a row to `HomeNetwork/inventory.md` under "Allowlist Additions Log".
- Does NOT enable the filter; only edits the list. Use `/homenet-filter on <ssid>` separately.
