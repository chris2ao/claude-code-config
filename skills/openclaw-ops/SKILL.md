---
platform: portable
description: "Configuration gotchas and operational patterns for OpenClaw multi-agent systems"
---

# /openclaw-ops - OpenClaw Configuration and Operations

Activate when configuring OpenClaw, parsing its status output, setting up Telegram integrations, or troubleshooting agent memory search. These are non-obvious config gotchas that cost time to rediscover.

## Steps

### 1. Verify Config After openclaw doctor --fix

`openclaw doctor --fix` applies schema normalization which reverts manual customizations to defaults. After every doctor invocation, check these settings:

```bash
openclaw doctor --fix
# Always re-verify after:
jq '.agents.defaults.groupPolicy' ~/.openclaw/openclaw.json
# If reverted to "allowlist", restore:
jq '.agents.defaults.groupPolicy = "open"' ~/.openclaw/openclaw.json > tmp && mv tmp ~/.openclaw/openclaw.json
```

Reapply any custom values (groupPolicy, telegram bindings, plugin enables) after each doctor run.

### 2. memorySearch Config Nesting

Place `memorySearch` under `agents.defaults`, not at top level or at `agents`:

```json
// Correct
{ "agents": { "defaults": { "memorySearch": { ... } } } }

// Wrong (top-level, silently ignored)
{ "memorySearch": { ... } }

// Wrong (wrong nesting level)
{ "agents": { "memorySearch": { ... } } }
```

### 3. Status JSON Agent Nesting

When parsing `openclaw status --json`, agents are at `result.agents.agents` (an array), not `result.agents`:

```ts
const status = JSON.parse(await execFileAsync('openclaw', ['status', '--json']))
const agentList = status.agents.agents  // array
// NOT: status.agents (object with nested structure)
```

### 4. Telegram Long-Polling Watchdog

Telegram long-polling connections die after ~8 minutes idle. Add a cron watchdog to auto-restart the gateway:

```bash
# Add to crontab: crontab -e
*/5 * * * * ~/.claude/scripts/telegram-watchdog.sh >> ~/.openclaw/logs/watchdog.log 2>&1
```

The watchdog script should:
1. Check the last activity timestamp from the gateway log
2. If stalled more than 10 minutes, run `launchctl bootout` then `launchctl bootstrap` (not `stop/start`)
3. Log the restart event with timestamp

## Source Instincts

- `openclaw-doctor-revert`: "when running openclaw doctor after manual config edits"
- `openclaw-memorysearch`: "when configuring memory search in OpenClaw"
- `openclaw-agents-nesting`: "when parsing openclaw status --json output"
- `telegram-polling-watchdog`: "when integrating Telegram with long-polling"
