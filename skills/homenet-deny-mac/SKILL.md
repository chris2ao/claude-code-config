---
platform: portable
description: "Remove a MAC address from a UniFi SSID's allowlist (preview by default, --apply to commit, --kick to force immediate disconnect, refuses lockout)"
---

# /homenet-deny-mac

Removes a MAC from a specific SSID's `mac_filter_list` and logs the revocation to `HomeNetwork/investigations.md`. Idempotent: if the MAC isn't on the list, exits without changes.

## Usage

Preview:
```bash
!bash "$HOME/.claude/scripts/homenet-deny-mac.sh" "<ssid-name>" "<mac>"
```

Apply:
```bash
!bash "$HOME/.claude/scripts/homenet-deny-mac.sh" "<ssid-name>" "<mac>" --apply
```

Apply and immediately kick (forces re-association, which the allowlist then denies):
```bash
!bash "$HOME/.claude/scripts/homenet-deny-mac.sh" "<ssid-name>" "<mac>" --apply --kick
```

## Kick prompt requirement (MUST FOLLOW)

**If the user invokes this skill with `--kick`, Claude MUST first confirm intent via `AskUserQuestion` before running the script.** The `--kick` flag forces an already-associated device off the network immediately via `kick-sta`, which is visible and disruptive. The user should explicitly opt in each time.

Claude orchestration pattern:
1. User says something like "remove MAC X and kick them".
2. Claude uses `AskUserQuestion` with: "Kick `<mac>` off `<ssid>` now? This will force re-auth and deny them on next attempt."
3. If user confirms: run script with `--apply --kick`.
4. If user declines: run script with `--apply` only (device remains connected until natural re-association).

This prompt does NOT replace the user's initial request — it confirms the disruptive side effect before execution.

## Examples

```bash
# Remove the historical iPad from LAN of the Free allowlist
!bash "$HOME/.claude/scripts/homenet-deny-mac.sh" "The LAN of the Free" "26:18:7b:79:9e:df" --apply

# Revoke a guest laptop when their visit ends
!bash "$HOME/.claude/scripts/homenet-deny-mac.sh" "Silence of the LANS" "aa:bb:cc:dd:ee:ff" --apply
```

## Safety rails

**Lockout guard.** If the MAC you're removing is the last entry on an allowlist AND the filter is currently enabled, the skill refuses `--apply` (would kick every client on the SSID). Disable the filter first with `/homenet-filter off <ssid> --apply`, or override with `--force-lockout` if you really mean it.

**MAC format validation.** Requires `aa:bb:cc:dd:ee:ff` colon-separated hex. Normalizes to lowercase automatically.

**Idempotent.** Running twice in a row is safe — the second run detects the MAC is already gone and exits.

## Effect timing

- Flipping the allowlist does not kick currently-connected clients. The affected MAC remains connected until its next re-association (can take minutes to hours). At that point it's denied.
- To kick the client immediately, follow up with `block_client` on the MAC via the UniFi MCP.

## Side effects

- Appends a revocation entry under `### Allowlist Revocation: <ssid>` in `HomeNetwork/investigations.md`.
- Does NOT toggle the filter. Use `/homenet-filter` separately.
