---
id: alert-ux-ack
trigger: "when designing alert UX for system dashboards"
confidence: 0.4
domain: "ux"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# ACK as Visual Dim, Not Hide

## Action
Make alert acknowledgement a visual state change (dim/mute) rather than hiding. Cycle through alerts every 5 seconds. Always show highest-severity alert prominently.

## Pattern
1. ACK changes visual state (opacity, border color) but keeps alert visible
2. Alert banner cycles through active alerts on interval (5s)
3. Highest severity always shown first
4. Dismissed alerts can be reviewed in alert history

## Evidence
- 2026-03-07: Alerts need to stay visible for operator awareness even after acknowledgement. Hiding ACKed alerts risks missing recurring issues.
