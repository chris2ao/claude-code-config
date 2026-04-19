---
platform: portable
description: "Generate or refresh comprehensive UniFi network documentation in HomeNetwork/, render logical+physical diagrams, and publish a redacted NotebookLM notebook (read-only against the UniFi MCP)"
user_invocable: true
---

# /homenet-document

Run the full network-documentation pipeline ad-hoc. Pulls live UniFi state, refreshes every `HomeNetwork/*.md` file in CJClaudin_Mac, regenerates logical and physical network diagrams, and publishes a redacted notebook to NotebookLM.

## When to use

- After significant network changes (new device, new SSID, firewall edit, VLAN restructure)
- Before security-sensitive work where current docs matter
- Periodic refresh (monthly is reasonable; the pipeline is idempotent)
- To bootstrap documentation on a fresh install of the project

## Usage

```
/homenet-document [options]
```

### Options

- `--diagrams-only` — skip the specialists, NotebookLM, and security/research analysis. Just re-pull data and re-render the two diagrams. Fast (~60s).
- `--no-notebooklm` — run everything except the NotebookLM publication step. Useful when offline or when you do not want to refresh the notebook.
- `--threads <comma-list>` — override the default research thread IDs (`udm-pro-hardening,u7-pro-rf-tuning,zbf-home-iot-segmentation`)

## What happens

1. **Phase 1: Data extraction.** Architect calls 30+ UniFi MCP tools to capture every reachable category (devices, clients, networks, WLANs, firewall, zones, port forwards, RADIUS, VPN, MAC ACLs, system health, alarms, events, topology, DPI, Protect cameras and NVRs). Output: `~/.claude/state/homenet-snapshots/<timestamp>.json`.
2. **Phase 2: Parallel analysis.** Three specialists run simultaneously:
   - `network-tech-writer` rewrites every HomeNetwork/ markdown file (README, inventory, topology, investigations, devices/, configurations/) using house style and the tiered client strategy.
   - `network-security-engineer` scores risks and writes `devices/security-recommendations.md` with MCP-actionable fixes only, ranked by Severity − Usability Impact.
   - `network-research` runs `/deep-research` threads and writes cited findings to `research/`.
3. **Phase 3: Diagram generation.** Architect runs `~/.claude/scripts/homenet-render-diagrams.py` (Python `diagrams` library + Graphviz). Generates `diagrams/logical-network.{svg,png}` and `diagrams/physical-topology.{svg,png}`.
4. **Phase 4: Synthesis.** Architect writes the README executive summary, cross-links research into security recommendations, updates the maintenance log.
5. **Phase 5: Redaction + NotebookLM.** Architect runs `~/.claude/scripts/homenet-redact.py` to scrub PSKs, PPSK passwords, RADIUS shared secrets, API keys, and bearer tokens from a copy of HomeNetwork/. Creates or updates the "Johnson Home Network" notebook in NotebookLM, brand-primes it, and uploads every redacted markdown plus diagram PNGs as sources.
6. **Phase 6: Final report.** You get a structured summary with file lists, stats, and suggested next actions.

## Prerequisites

- UniFi MCP server (`unifi`) configured in `~/.claude.json` and reachable
- NotebookLM MCP server (`notebooklm`) authenticated (`nlm login` if expired)
- Python 3 with the `diagrams` package installed: `pip3 install diagrams`
- Graphviz: `brew install graphviz`
- macOS with `~/.claude/scripts/homenet-*.sh` already in place (matches existing /homenet-* skill family)

## Output

| Path | Contents |
|------|----------|
| `~/.claude/state/homenet-snapshots/<ts>.json` | Raw MCP data (contains secrets; outside any git repo) |
| `~/.claude/state/homenet-redacted/<ts>/` | Redacted parallel tree of HomeNetwork/ used for NotebookLM upload |
| `HomeNetwork/README.md` | Updated index, exec summary, maintenance log entry |
| `HomeNetwork/inventory.md` | Tiered client list (full + transient table) |
| `HomeNetwork/topology.md` | VLANs/SSIDs/APs + embedded diagrams |
| `HomeNetwork/investigations.md` | Updated open questions |
| `HomeNetwork/devices/*.md` | Per-category device profiles incl. new av-media.md and mobile-and-tablets.md |
| `HomeNetwork/devices/security-recommendations.md` | Ranked findings with MCP commands |
| `HomeNetwork/configurations/*.md` | Per-config-area docs (networks, wlans, firewall, port-forwards, system-health) |
| `HomeNetwork/research/*.md` | Cited research findings |
| `HomeNetwork/diagrams/*.{svg,png}` | Logical and physical topology |
| `HomeNetwork/.notebooklm-id` | Persisted notebook ID for re-runs (gitignored) |

## Implementation

This skill spawns the network-architect orchestrator, which runs all six phases:

```
Agent(
  prompt="Follow the instructions in /Users/chris2ao/GitProjects/CJClaudin_Mac/.claude/agents/network-architect.md.
          Project root: /Users/chris2ao/GitProjects/CJClaudin_Mac.
          Options: <args from user>.",
  subagent_type="general-purpose",
  model="opus",
  name="network-architect"
)
```

## Relationship to other /homenet-* skills

This skill is **read-only** against the UniFi MCP. It documents the network and proposes recommendations but never mutates configuration. The mutation skills remain the right tool for actually applying changes:

- `/homenet-snapshot` — quick wlanconf-only backup (use before SSID changes)
- `/homenet-allow-mac` / `/homenet-deny-mac` — MAC allowlist edits
- `/homenet-filter` — toggle MAC filtering per SSID
- `/homenet-ppsk-add` / `/homenet-ppsk-remove` — PPSK management
- `/homenet-review` — reconcile MAC allowlist against active + historical clients

`/homenet-document` is the comprehensive companion: documentation, diagrams, security review, and NotebookLM publication, all in one pass.

## Limitations

- Per-flow traffic data is not exposed by the UniFi API on Network 10.2; DPI per-app aggregates are the closest substitute.
- LLDP / physical cable-run topology is not exposed; physical diagram uses switch port indices, not cable labels.
- NotebookLM generation has no guaranteed time; large notebooks take 5+ minutes to ingest sources.
- Cookie auth for NotebookLM expires every 2-4 weeks. If publication fails, run `nlm login` and re-invoke with `--no-notebooklm` first to verify everything else, then re-run with NotebookLM enabled.
