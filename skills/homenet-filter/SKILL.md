---
platform: portable
description: "Toggle mac_filter_enabled on a UniFi SSID (auto-snapshots before change, refuses empty-allowlist enables)"
---

# /homenet-filter

Flip `mac_filter_enabled` on a specific SSID. This is the **enforcement switch**: when on, the allowlist is honored; when off, every client with the PSK can join regardless of MAC.

Has safety rails:
- **Auto-snapshot**: calls `/homenet-snapshot` first so rollback is always possible.
- **Empty-allowlist guard**: refuses to turn the filter ON if the allowlist is empty (would lock everyone out). Override with `--force-empty` only if you know what you're doing.
- **Idempotent**: no-op if the filter is already in the desired state.

## Usage

Preview:
```bash
!bash "$HOME/.claude/scripts/homenet-filter.sh" <on|off> "<ssid-name>"
```

Apply:
```bash
!bash "$HOME/.claude/scripts/homenet-filter.sh" <on|off> "<ssid-name>" --apply
```

## Examples

```bash
# Turn filter ON for the Streaming SSID (after allowlist is populated)
!bash "$HOME/.claude/scripts/homenet-filter.sh" on "Johnson Streaming Devices" --apply

# Panic button: turn filter OFF immediately to unblock everyone
!bash "$HOME/.claude/scripts/homenet-filter.sh" off "Silence of the LANS" --apply
```

## Effect timing

- Flipping **on**: already-associated clients stay connected until their next re-association. New association attempts filter immediately. Full effect usually within minutes.
- Flipping **off**: effect is immediate. Previously-blocked devices can associate on their next attempt.

## When to use

- Step D of each rollout phase (enforcement enable, after a 24h stage period).
- Rollback (`off`) if a phase's observation window turns up unexpected lockouts.
- Pausing enforcement temporarily during onboarding of a new device.

## Safety notes

- Before flipping **on** for `The LAN of the Free` or `Silence of the LANS`: confirm you're operating from a wired connection (ethernet), not the Wi-Fi you're about to filter.
- This skill does NOT modify `mac_filter_list`. Use `/homenet-allow-mac` for that.

## Validated rollout pattern

The preview-then-apply flow with auto-snapshot is the vetted idiom for any destructive UniFi change, not a suggestion. During the 2026-04 MAC-allowlist rollout across three SSIDs, the lockout guard here (refuses `on` with an empty allowlist) and the matching guard in `/homenet-ppsk-remove` (refuses a remove that would brick the SSID) each caught real operator mistakes before they hit the wire. Do not bypass `--force-empty` or `--apply` without a preview unless you have rollback-from-snapshot steps already typed out.
