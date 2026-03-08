---
id: telegram-polling-watchdog
trigger: "when integrating Telegram with long-polling"
confidence: 0.4
domain: "openclaw"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Watchdog Cron for Telegram Long-Polling

## Action
Add a cron watchdog (*/5 * * * *) that checks if Telegram polling has stalled (>10 minutes since last activity) and auto-restarts the gateway.

## Pattern
1. Cron runs every 5 minutes
2. Check gateway process health and last poll timestamp
3. If stalled >10 minutes, restart gateway
4. Log restart events for debugging

## Evidence
- 2026-03-06: Gateway long-polling connections die after ~8 minutes idle (known OpenClaw/Telegram issue). Watchdog cron handles automatic recovery.
