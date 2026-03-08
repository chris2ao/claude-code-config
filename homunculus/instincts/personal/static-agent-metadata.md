---
id: static-agent-metadata
trigger: "when building dashboards for dynamic agent systems"
confidence: 0.4
domain: "frontend"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Extract Agent Metadata to Static Data File

## Action
Pre-compute agent metadata (name, role, skills, description) into a static TypeScript data file sourced from agent config files. Update the data file when agent config changes, not at render time.

## Pattern
1. Read agent SOUL.md/IDENTITY.md files once
2. Create static data file (e.g., team-data.ts) with all agent info
3. Dashboard components import from static file
4. Update data file as part of config change workflow

## Evidence
- 2026-03-07: Mission Control Team page uses team-data.ts instead of dynamic file reads. Avoids expensive runtime queries for data that rarely changes.
