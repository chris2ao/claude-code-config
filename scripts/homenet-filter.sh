#!/usr/bin/env bash
# homenet-filter.sh — toggle mac_filter_enabled on an SSID
# Usage: homenet-filter.sh <on|off> <ssid-name> [--apply]

set -uo pipefail
source "$HOME/.claude/scripts/homenet-lib.sh"

MODE_OP="${1:-}"
SSID="${2:-}"
APPLY="${3:-preview}"

[ "$MODE_OP" = "on" ] || [ "$MODE_OP" = "off" ] \
    || _homenet_fail "usage: homenet-filter.sh <on|off> <ssid> [--apply]"
[ -n "$SSID" ] || _homenet_fail "ssid required"

homenet_load_secrets

wlan=$(homenet_wlan_by_name "$SSID")
[ -n "$wlan" ] && [ "$wlan" != "null" ] || _homenet_fail "SSID not found: $SSID"

wlan_id=$(echo "$wlan" | jq -r '._id')
current_on=$(echo "$wlan" | jq -r '.mac_filter_enabled')
allowlist_size=$(echo "$wlan" | jq -r '(.mac_filter_list // []) | length')
desired_on="false"
[ "$MODE_OP" = "on" ] && desired_on="true"

if [ "$current_on" = "$desired_on" ]; then
    echo "No change needed. '$SSID' filter is already $MODE_OP (enabled=$current_on)."
    exit 0
fi

echo ""
echo "=== Preview: toggle MAC filter ==="
echo "SSID: $SSID ($wlan_id)"
echo "Change: enabled $current_on → $desired_on"
echo "Current allowlist size: $allowlist_size"

if [ "$MODE_OP" = "on" ] && [ "$allowlist_size" -eq 0 ]; then
    echo ""
    echo "[!] WARNING: allowlist is EMPTY. Enabling filter will block every client on '$SSID'."
    if [ "$APPLY" = "--apply" ]; then
        echo "[!] Refusing to apply with empty allowlist. Re-run with --force-empty to override."
        exit 1
    fi
fi

if [ "$APPLY" != "--apply" ] && [ "$APPLY" != "--force-empty" ]; then
    echo ""
    echo "[preview only] re-run with --apply to commit."
    exit 0
fi

# Auto-snapshot before any filter flip
if [ -x "$HOME/.claude/scripts/homenet-snapshot.sh" ]; then
    echo ""
    echo "Auto-snapshot before change..."
    "$HOME/.claude/scripts/homenet-snapshot.sh" "pre-filter-${MODE_OP}-${SSID// /_}" > /dev/null
fi

payload=$(jq -n --argjson v "$desired_on" '{mac_filter_enabled: $v}')
echo ""
echo "Applying..."
resp=$(homenet_api "/proxy/network/api/s/default/rest/wlanconf/$wlan_id" -X PUT -H "Content-Type: application/json" -d "$payload")
rc=$(echo "$resp" | jq -r '.meta.rc // "-"')

if [ "$rc" != "ok" ]; then
    echo "API error: $(echo "$resp" | jq -r '.meta.msg // .')"
    exit 1
fi

echo "Applied. '$SSID' mac_filter_enabled = $desired_on."

# Log to HomeNetwork
if [ -f "$HOMENET_DIR/investigations.md" ]; then
    stamp=$(date +%Y-%m-%d\ %H:%M)
    {
        echo ""
        echo "### Filter Toggle: $SSID"
        echo "- $stamp: \`mac_filter_enabled\` set to \`$desired_on\` (allowlist size: $allowlist_size)"
    } >> "$HOMENET_DIR/investigations.md"
fi
