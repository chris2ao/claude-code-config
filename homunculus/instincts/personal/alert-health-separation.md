---
id: alert-health-separation
trigger: "when implementing alert aggregation systems that include health checks"
confidence: 0.4
domain: "monitoring"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Separate Health Checks from Alert Polling

## Action
Never include health check calls inside alert polling cycles. Health checks can generate alerts, which trigger more polling, creating feedback loops. Add cooldown timers on dispatch functions.

## Pattern
1. Remove health checks (watchdog, system checks) from Promise.all alert batches
2. Run health checks on a separate, slower interval
3. Add dispatch cooldown (e.g., 5 minutes) to prevent alert storms
4. Health check results feed into alert state, but don't trigger re-polling

## Evidence
- 2026-03-05: Gateway watchdog in getActiveAlerts() Promise.all created feedback loop: watchdog checks system, generates alerts, triggers watchdog again. Fixed by removing from batch + 5-min cooldown.
