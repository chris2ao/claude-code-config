#!/usr/bin/env bash
# bridge-launcher.sh
# Wrapper around `claude remote-control` that detects the new environment ID
# on startup and updates the Gmail Assistant trigger to point to it.
#
# Problem: each bridge restart generates a new environment_id, but the
# scheduled trigger still references the old one, causing silent failures.

set -uo pipefail

TRIGGER_ID="trig_018km7FBZka2JcYuD5SMQvzf"
BRIDGE_LOG="$HOME/.claude/logs/remote-control.log"
LAUNCHER_LOG="$HOME/.claude/logs/bridge-launcher.log"
ENV_ID_FILE="$HOME/.claude/current-env-id"
CLAUDE="$HOME/.local/bin/claude"

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LAUNCHER_LOG"; }

# Ensure log directory exists
mkdir -p "$(dirname "$LAUNCHER_LOG")"

# Clear bridge log so we only see fresh output
: > "$BRIDGE_LOG"

log "Bridge launcher starting (PID $$)"

# Background watcher: detect env ID and update trigger
(
  for _ in $(seq 1 60); do
    sleep 1
    # The bridge logs a URL like: https://claude.ai/code?environment=env_XXXXX
    ENV_ID=$(grep -o 'environment=[^[:space:]"&]*' "$BRIDGE_LOG" 2>/dev/null \
             | head -1 \
             | cut -d= -f2) || true

    if [[ -n "${ENV_ID:-}" ]]; then
      log "Detected environment ID: $ENV_ID"
      echo "$ENV_ID" > "$ENV_ID_FILE"

      # Check if trigger already has this env ID (skip update if so)
      OLD_ENV_ID=$(cat "$ENV_ID_FILE.prev" 2>/dev/null || echo "")
      if [[ "$ENV_ID" == "$OLD_ENV_ID" ]]; then
        log "Environment ID unchanged, skipping trigger update"
        exit 0
      fi

      log "Updating trigger $TRIGGER_ID to environment $ENV_ID"
      UPDATE_PROMPT="You must update a scheduled trigger's environment_id. Use the RemoteTrigger tool with action 'update', trigger_id '$TRIGGER_ID'. The body should set job_config.ccr.environment_id to '$ENV_ID'. You MUST preserve the existing events, session_context, and all other fields from the current trigger config. First use RemoteTrigger action 'get' to read the current config, then use action 'update' with the full job_config but with the new environment_id. Reply only 'done' when complete."

      echo "$UPDATE_PROMPT" \
        | "$CLAUDE" -p --model haiku --verbose 2>&1 \
        | while IFS= read -r line; do log "  claude: $line"; done

      EXIT_CODE=${PIPESTATUS[1]}
      if [[ "$EXIT_CODE" -eq 0 ]]; then
        log "Trigger update succeeded"
        echo "$ENV_ID" > "$ENV_ID_FILE.prev"
      else
        log "WARNING: claude -p exited with code $EXIT_CODE"
      fi
      exit 0
    fi
  done
  log "ERROR: Timed out after 60s waiting for environment URL in bridge log"
) &

log "Starting bridge process"
exec "$CLAUDE" remote-control --name "Mac Mini Bridge"
