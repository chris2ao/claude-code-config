---
id: headless-mac-pmset
trigger: "when deploying to headless Mac hardware"
confidence: 0.4
domain: "devops"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Disable Sleep for 24/7 Mac Operation

## Action
Run `sudo pmset -a sleep 0 disksleep 0 displaysleep 0 ttyskeepawake 0 autorestart 1` to disable all power management and enable auto-restart after power failure.

## Pattern
1. Disable all sleep modes: sleep 0, disksleep 0, displaysleep 0
2. Disable TTY keepawake: ttyskeepawake 0
3. Enable auto-restart: autorestart 1
4. Verify with `pmset -g`

## Evidence
- 2026-03-06: OpenClaw on M4 Mac Mini requires continuous 24/7 operation. Default power management would put machine to sleep.
