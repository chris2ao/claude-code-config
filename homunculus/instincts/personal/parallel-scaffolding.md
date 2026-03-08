---
id: parallel-scaffolding
trigger: "when scaffolding large monolithic projects (50+ files)"
confidence: 0.4
domain: "workflow"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Parallel Agent Task Streams for Large Scaffolds

## Action
Decompose into independent task streams, spawn parallel agents, coordinate dependencies between streams.

## Pattern
1. Identify independent streams (e.g., frontend UI, backend API, shared components)
2. Map dependencies between streams (components depend on UI primitives)
3. Launch independent streams as parallel agents
4. Dependent streams wait for prerequisites
5. Final review agent validates the combined result

## Evidence
- 2026-03-07: Mission Control (68 files) built via 3 parallel agents: mc-frontend, mc-backend, mc-components. Independent streams ran simultaneously, dependent work sequenced.
