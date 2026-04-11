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

      # Update trigger with retries and verification
      MAX_RETRIES=3
      for ATTEMPT in $(seq 1 "$MAX_RETRIES"); do
        log "Updating trigger $TRIGGER_ID to environment $ENV_ID (attempt $ATTEMPT/$MAX_RETRIES)"

        UPDATE_PROMPT="CRITICAL: You must update a scheduled trigger and then VERIFY the update succeeded.

Step 1: Use the RemoteTrigger tool with action 'get' and trigger_id '$TRIGGER_ID' to read the current config. Save the full job_config.

Step 2: Use the RemoteTrigger tool with action 'update' and trigger_id '$TRIGGER_ID'. The body must contain the COMPLETE job_config from step 1, with ONLY job_config.ccr.environment_id changed to '$ENV_ID'. Preserve events, session_context, model, and all other fields exactly as they are.

Step 3: Use the RemoteTrigger tool with action 'get' and trigger_id '$TRIGGER_ID' again. Check that the response contains environment_id '$ENV_ID'.

If step 3 confirms the update, reply with exactly: VERIFIED
If step 3 shows a different environment_id, reply with exactly: FAILED"

        UPDATE_OUTPUT=$("$CLAUDE" -p --model sonnet --allowedTools "RemoteTrigger" --bare <<< "$UPDATE_PROMPT" 2>&1)
        EXIT_CODE=$?

        log "  claude exit code: $EXIT_CODE"
        echo "$UPDATE_OUTPUT" | while IFS= read -r line; do log "  claude: $line"; done

        if [[ "$EXIT_CODE" -eq 0 ]] && echo "$UPDATE_OUTPUT" | grep -q "VERIFIED"; then
          log "Trigger update VERIFIED on attempt $ATTEMPT"
          echo "$ENV_ID" > "$ENV_ID_FILE.prev"
          exit 0
        fi

        log "WARNING: Update not verified on attempt $ATTEMPT"
        sleep 5
      done

      log "ERROR: Trigger update failed after $MAX_RETRIES attempts. Bridge env=$ENV_ID, trigger may still use old env."
      osascript -e 'display notification "Gmail trigger update failed after 3 retries. Manual fix needed." with title "Claude Bridge" sound name "Basso"' 2>/dev/null || true
      exit 1
    fi
  done
  log "ERROR: Timed out after 60s waiting for environment URL in bridge log"
) &

log "Starting bridge process"
exec "$CLAUDE" remote-control --name "Mac Mini Bridge"
