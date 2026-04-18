---
platform: portable
description: "Reconcile each SSID's MAC allowlist against actually-seen clients (active + historical)"
---

# /homenet-review

Diff the MAC allowlist on each Wi-Fi SSID against the clients actually using the network. Identifies four important states per SSID:

- **Active now**: count of MACs currently associated.
- **Active but NOT on allowlist**: clients that would be kicked if the filter were enabled right now. Highest-priority finding.
- **Seen in last N days, not on allowlist**: candidates to add (legitimate devices you haven't approved yet).
- **On allowlist, not seen in N days**: stale entries you might remove.

Read-only: makes no changes.

## Usage

Review all SSIDs:
```bash
!bash "$HOME/.claude/scripts/homenet-review.sh"
```

Review one SSID:
```bash
!bash "$HOME/.claude/scripts/homenet-review.sh" "The LAN of the Free"
```

Change the window (default 30 days):
```bash
!HOMENET_REVIEW_WINDOW_DAYS=60 bash "$HOME/.claude/scripts/homenet-review.sh"
```

## When to use

- Step 1 of every rollout phase (baseline)
- Daily during the 48h observation window after enforcement is enabled
- Before committing a phase's final allowlist
- When a family member says "my phone can't connect" (to confirm their MAC isn't listed)

## Output

Per SSID: filter state, allowlist size, three categorized lists of MACs with hostname/OUI enrichment. No JSON, human-readable.
