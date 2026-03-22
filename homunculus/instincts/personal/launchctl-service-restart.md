---
id: launchctl-service-restart
trigger: "when managing macOS LaunchAgent services (restarts, watchdogs, cycling)"
confidence: 0.5
domain: "macos"
source: "session-archive-ingestion"
created: "2026-03-14"
---

# Use bootout/bootstrap for LaunchAgent Restarts

## Action
When restarting macOS LaunchAgent services, use `launchctl bootout gui/$(id -u)/com.service.name` followed by `launchctl bootstrap gui/$(id -u) /path/to/plist` instead of `stop/start` or `unload/load`. The `stop` command can leave the LaunchAgent unloaded, preventing subsequent restarts.

## Pattern
1. Stop the service: `launchctl bootout gui/$(id -u)/com.example.service`
2. Start the service: `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.example.service.plist`
3. Verify: `launchctl print gui/$(id -u)/com.example.service`

## Evidence
- 2026-03-08: Gateway watchdog cron ran every 5 minutes but never restarted the gateway. Debug tracing revealed that `openclaw gateway stop` unloaded the LaunchAgent, so subsequent start attempts failed silently. Switching to bootout/bootstrap fixed the issue.
