#!/usr/bin/env bash
# homenet-snapshot.sh — save a timestamped copy of all wlanconf state.
# IMPORTANT: Backups contain plaintext x_passphrase and PPSK password fields.
# They are written to ~/.claude/state/homenet-backups/ OUTSIDE any git repo.
# Never move this output path inside a tracked repository.

set -uo pipefail
source "$HOME/.claude/scripts/homenet-lib.sh"

REASON="${1:-manual}"
homenet_require_dir
homenet_load_secrets

BACKUP_DIR="${HOMENET_BACKUP_DIR:-$HOME/.claude/state/homenet-backups}"
mkdir -p "$BACKUP_DIR"

ts=$(homenet_timestamp)
out="$BACKUP_DIR/wlanconf-${ts}.json"

homenet_log "snapshotting all wlanconf to $out (reason: $REASON)"
body=$(homenet_api "/proxy/network/api/s/default/rest/wlanconf")
[ "$(homenet_last_code)" = "200" ] || _homenet_fail "API returned $(homenet_last_code)"

count=$(echo "$body" | jq '.data | length')
echo "$body" | jq --arg reason "$REASON" --arg ts "$ts" '{ts: $ts, reason: $reason, wlans: .data}' > "$out"

echo ""
echo "Snapshot saved: $out"
echo "SSIDs captured: $count"
echo ""
echo "Summary:"
echo "$body" | jq -r '.data[] | "  - \(.name)  filter=\(.mac_filter_enabled)  policy=\(.mac_filter_policy)  entries=\((.mac_filter_list // []) | length)"'
