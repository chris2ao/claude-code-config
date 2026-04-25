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

### 5. Embedded Gateway Token Warning on macOS

Doctor flags `Gateway service embeds OPENCLAW_GATEWAY_TOKEN and should be reinstalled.` and recommends `openclaw gateway install --force`. **On macOS this does not clear the warning** (verified in 2026.4.23). The audit at `dist/service-audit-*.js` skips the warning only when `environmentValueSources.OPENCLAW_GATEWAY_TOKEN === "file"`; the systemd module sets that field, but the launchd module has no file-source support. There is no `--token-file` option (only `--password-file` for password auth).

Practical workaround: tighten the plist permissions so they match `~/.openclaw/.env`.

```bash
chmod 600 ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

Token in `~/.openclaw/openclaw.json` is a `${OPENCLAW_GATEWAY_TOKEN}` placeholder; the actual value lives in `~/.openclaw/.env` (mode 600). After chmod, exposure matches. Doctor will keep firing the warning because it audits plist content, not perms. Treat as a known macOS-only false positive until upstream adds launchd file-source support.

### 6. Session Store Maintenance

Two distinct kinds of session debt that doctor reports separately:

```bash
# Entries pointing to missing transcript files (.jsonl deleted out from under sessions.json)
openclaw sessions cleanup --enforce --fix-missing \
  --store ~/.openclaw/agents/<agent>/sessions/sessions.json

# Orphan transcript files (.jsonl on disk not referenced by sessions.json) — archive manually
cd ~/.openclaw/agents/<agent>/sessions
TS=$(date -u +%Y-%m-%dT%H-%M-%S.000Z)
for f in <orphan-uuid>.jsonl; do mv "$f" "$f.deleted.$TS"; done
```

`--fix-missing` is needed in addition to `--enforce`; without it, `cleanup` only handles age/count retention. Renaming to `*.deleted.<ts>` matches the pattern doctor itself uses, keeps the data recoverable, and clears the orphan count.

## Source Instincts

- `openclaw-doctor-revert`: "when running openclaw doctor after manual config edits"
- `openclaw-memorysearch`: "when configuring memory search in OpenClaw"
- `openclaw-agents-nesting`: "when parsing openclaw status --json output"
- `telegram-polling-watchdog`: "when integrating Telegram with long-polling"
- `openclaw-launchd-token-gap`: "when doctor reports embedded OPENCLAW_GATEWAY_TOKEN on macOS"
- `openclaw-session-cleanup`: "when doctor reports orphan transcripts or missing-transcript entries"
