---
platform: portable
description: "Add a Private Pre-Shared Key (PPSK) entry to a PPSK-enabled SSID (preview by default, --apply to commit)"
---

# /homenet-ppsk-add

Append a PPSK entry to an SSID that has PPSK enabled. Idempotent: if the same password already exists, exits without changes. Writes an audit entry to `HomeNetwork/investigations.md` with only the SHA-256 fingerprint prefix of the password (not the plaintext) to keep the repo safe to commit.

## Usage

Preview:
```bash
!bash "$HOME/.claude/scripts/homenet-ppsk-add.sh" "<ssid>" "<password>"
```

Apply (use current SSID's VLAN binding):
```bash
!bash "$HOME/.claude/scripts/homenet-ppsk-add.sh" "<ssid>" "<password>" --apply
```

Apply and override the PPSK's VLAN to a specific network:
```bash
!bash "$HOME/.claude/scripts/homenet-ppsk-add.sh" "<ssid>" "<password>" "<vlan-network-name>" --apply
```

## Examples

```bash
# Add a PPSK for the quarantine SSID, default VLAN binding (the SSID's own VLAN = RoamingQuarantine)
!bash "$HOME/.claude/scripts/homenet-ppsk-add.sh" "LAN Solo" "SomeStrongPSK-2026" --apply

# Add a PPSK that routes a trusted device to the Default VLAN instead of the quarantine VLAN
!bash "$HOME/.claude/scripts/homenet-ppsk-add.sh" "LAN Solo" "SomeStrongPSK-2026" "Default" --apply
```

## Guards

- **Password length**: refuses anything < 8 characters (WPA-PSK minimum).
- **PPSK enabled check**: refuses if the target SSID does not have `private_preshared_keys_enabled: true`.
- **Idempotent**: if an entry with the same password already exists, exits without changes.
- **VLAN lookup**: if you pass a VLAN name, it must exist. Otherwise the SSID's current `networkconf_id` is reused.

## Security property: SSID-level PSK is hidden on PPSK SSIDs

When `private_preshared_keys_enabled: true` on an SSID, UniFi auto-generates the SSID-level `x_passphrase` and does not surface it to the admin (UI shows PPSK list only; REST returns an opaque value). Effectively, all access is forced through per-device PPSK entries. This is a desirable property: revoking a device means removing its PPSK row, not rotating a shared secret. When this skill adds a PPSK it relies on that property, so the SSID-level passphrase is never logged, previewed, or written to `HomeNetwork/`.

## Audit logging

Passwords are never written to `HomeNetwork/investigations.md` in plaintext. Each addition logs:
- Timestamp
- SSID name
- Target VLAN `_id`
- SHA-256 fingerprint prefix of the password (first 8 hex chars) so you can verify a known-PSK later without ever storing it

Example log line:
```
### PPSK Added: LAN Solo
- 2026-04-18 10:15: added entry sha256-prefix=`a1b2c3d4` → VLAN id `69e38784a885c34e9f8da78a` (count 2 → 3)
```
