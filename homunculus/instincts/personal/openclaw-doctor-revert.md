---
id: openclaw-doctor-revert
trigger: "when running openclaw doctor after manual config edits"
confidence: 0.4
domain: "openclaw"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Verify Config After openclaw doctor --fix

## Action
After running `openclaw doctor --fix`, verify that groupPolicy is still set to your desired value (e.g., "open"). Doctor applies schema normalization which reverts manual customizations to defaults (e.g., "allowlist").

## Pattern
1. Before doctor: note current groupPolicy and other custom settings
2. Run doctor
3. After doctor: check groupPolicy in openclaw.json
4. Reapply if reverted: set groupPolicy back to "open" for each agent's telegram binding

## Evidence
- 2026-03-06: Doctor reverted groupPolicy from "open" to "allowlist" on every run. Had to reapply after each doctor invocation.
