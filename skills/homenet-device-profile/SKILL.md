---
name: homenet-device-profile
description: Generate a device-first behavior profile of the home LAN by joining UniFi client state with Pi-hole DNS data. Read-only. Classifies each device by type, trust tier, online cadence, and DNS behavior using explicit rules in ~/.claude/scripts/device-signatures.yml. Default output is stdout; --write persists to HomeNetwork/devices/device-profiles.md.
---

# homenet-device-profile

## Purpose

Answer "what is this endpoint and what is it doing?" for every device on the home LAN by combining:

- **UniFi:** active + historical clients, MAC, hostname, vendor OUI, IP, network/SSID, wired/wireless, uptime, signal
- **Pi-hole:** top clients by query count, top permitted/blocked domains, blocked %, per-IP activity

Result: one markdown report grouped by device type, with trust tier + cadence + DNS behavior per device. Unknown / unclassified devices get their top 5 permitted domains listed so they can be labeled manually.

## Scope

- **Device-first.** Profiles describe endpoints, not users. Temporal (time-of-day) analysis is off by default and only enabled via `--include-temporal`.
- **Read-only.** Never mutates UniFi or Pi-hole. If the profile suggests action (e.g. MAC should join an allowlist, volume spike on an IoT device), surface as a recommendation. Actuation lives in `homenet-allow-mac`, `homenet-filter`, etc.

## Invocation

```
/homenet-device-profile [--window DAYS] [--device MAC] [--include-temporal] [--write] [--force]
```

| Flag | Default | Meaning |
|---|---|---|
| `--window DAYS` | `7` | Pi-hole lookback (Pi-hole retention is whatever is configured; we report what is available) |
| `--device MAC` | unset | Narrow to single device; emit deep-dive subsection |
| `--include-temporal` | off | Include time-of-day cadence (opt-in for privacy) |
| `--write` | off | Persist to `HomeNetwork/devices/device-profiles.md`; default is stdout only |
| `--force` | off | Overwrite even if HomeNetwork tree has uncommitted changes |

## Data sources

### UniFi MCP
- `mcp__unifi__list_clients` — current snapshot (IP, MAC, hostname, network, wired/wireless, signal, uptime, tx/rx bytes)
- `mcp__unifi__list_all_clients` — historical (MAC, hostname, ID)
- `mcp__unifi__list_mac_filter` — SSID allowlist membership
- `mcp__unifi__list_networks` — network / VLAN map (for trust-tier assignment)
- `mcp__unifi__list_wlans` — SSID map
- `mcp__unifi__get_client_history` — per-device session history (only when `--device` is set)

### Pi-hole MCP
- `mcp__pihole__get_stats` — LAN-wide baseline (total queries, total blocked)
- `mcp__pihole__get_top_clients count=50` — volume per client IP
- `mcp__pihole__get_top_clients count=30 blocked=true` — blocked-volume per client IP
- `mcp__pihole__get_top_permitted count=50` — LAN-wide domain baseline
- `mcp__pihole__get_top_blocked count=30` — LAN-wide blocked-domain baseline
- `mcp__pihole__get_history` — time-series (only when `--include-temporal` is set)
- `mcp__pihole__get_query_log filter` — per-client deep dive (only when `--device` is set)

## Execution recipe (agent instructions)

1. **Gather** UniFi and Pi-hole data in parallel via the MCP tools listed above. Keep raw JSON in memory.
2. **Build join table** keyed by current IP:
   - Left join UniFi-active clients onto Pi-hole per-IP query counts.
   - For UniFi-historical-only MACs, note them in an "offline" section; no DNS join.
   - Flag `ip-drift` if the same IP appears bound to multiple different MACs in UniFi's historical data within the window.
3. **Privacy-MAC handling:** MAC with locally-administered bit (2nd nibble of first byte ∈ {2,6,a,e}) → mark as `privacy-mac-pool`. Aggregate per SSID; do **not** emit per-MAC profile for privacy MACs since they rotate.
4. **Classify** each non-privacy MAC using `~/.claude/scripts/device-signatures.yml`:
   - Type from OUI + DNS-cluster rules (first match wins). Fallback `unclassified`.
   - Trust tier from `list_mac_filter` + network assignment.
   - Cadence from `uptime_human` + wired vs wireless (long uptime wired = infrastructure-like).
   - DNS behavior = `volume_quintile` (vs LAN baseline) + `blocked_pct` + top 3 matched `dns_categories`.
5. **Diff** against `~/.claude/state/device-profiles/last.json`:
   - New MACs since last run.
   - New top-10 domains per device.
   - Volume spike (2x+ rolling avg).
6. **Emit** markdown report (see format below).
7. If `--write`: atomically replace `HomeNetwork/devices/device-profiles.md`. Sanity-check no plaintext passwords/PSKs/PPSK keys. Update `~/.claude/state/device-profiles/<ts>.json` and symlink `last.json`.

## Output format

```
# Device Profiles

Generated: <ISO>
Window: <N days>
UniFi snapshot: <snapshot ts or "live">
Pi-hole lookback: <since ts>
LAN baseline: <total_queries> queries, <blocked_pct>% blocked

## Summary
- Active devices: <N> (<W> wireless, <R> wired)
- Historical-only devices: <M>
- Classification coverage: <X>% typed
- Privacy-MAC pool size: <P>
- Flags: <count> ip-drift, <count> new-since-last, <count> volume-spike

## Active devices by type

### <type> (count)
| MAC | Hostname | IP | Trust | Cadence | Volume (quintile / raw) | Blocked % | Top DNS categories | Flags |

## Privacy-MAC pool
(per SSID aggregate)

## Unclassified devices
| MAC | Hostname | Vendor (OUI) | Top 5 permitted domains |

## Drift vs last run
(empty on first run)

## Recommendations
- Unlabeled active devices: ...
- Devices on allowlist with zero DNS in window: ...
- Devices with volume spike > 2x rolling avg: ...
```

## Safety / refusals

- Read-only MCP calls only. No `update_*`, `create_*`, `delete_*`, `add_mac_filter`, `block_client` etc.
- Before `--write`: scan generated markdown for `x_passphrase`, `password=`, raw PPSK hex, full URLs with query strings. Refuse on match.
- Refuse `--write` if `HomeNetwork/devices/device-profiles.md` has uncommitted git changes, unless `--force`.
- Privacy MACs are aggregated only.
- `--include-temporal` requires explicit opt-in and gets a privacy note in the report header.

## First-run note

The first run has no `~/.claude/state/device-profiles/last.json`, so the **Drift vs last run** section will be "first run — no baseline, drift tracking begins with the next invocation." This is expected and not an error.

## Related skills

- `homenet-document` — full UniFi state dump. This skill reuses its snapshot if fresh, else fetches live.
- `homenet-review` — allowlist reconciliation. This skill may inform a review but never mutates.
- `homenet-allow-mac` / `homenet-deny-mac` / `homenet-filter` — mutation skills for any action the profile recommends.
