#!/usr/bin/env bash
# homenet-allow-mac.sh — add a MAC to an SSID's allowlist
# Usage: homenet-allow-mac.sh <ssid-name> <mac> <label> [--apply]

set -uo pipefail
source "$HOME/.claude/scripts/homenet-lib.sh"

SSID="${1:-}"
MAC_RAW="${2:-}"
LABEL="${3:-}"
MODE="${4:-preview}"

[ -n "$SSID" ] && [ -n "$MAC_RAW" ] && [ -n "$LABEL" ] \
    || _homenet_fail "usage: homenet-allow-mac.sh <ssid> <mac> <label> [--apply]"

homenet_validate_mac "$MAC_RAW"
MAC=$(homenet_normalize_mac "$MAC_RAW")
homenet_load_secrets

wlan=$(homenet_wlan_by_name "$SSID")
[ -n "$wlan" ] && [ "$wlan" != "null" ] || _homenet_fail "SSID not found: $SSID"

wlan_id=$(echo "$wlan" | jq -r '._id')
current_list=$(echo "$wlan" | jq -r '(.mac_filter_list // []) | .[]' | tr '[:upper:]' '[:lower:]')
filter_on=$(echo "$wlan" | jq -r '.mac_filter_enabled')
policy=$(echo "$wlan" | jq -r '.mac_filter_policy')

if echo "$current_list" | grep -qx "$MAC"; then
    echo "MAC $MAC is already on the allowlist for '$SSID'. No change."
    exit 0
fi

new_list=$(printf "%s\n%s\n" "$current_list" "$MAC" | grep -v '^$' | sort -u | jq -Rn '[inputs]')

echo ""
echo "=== Preview: add MAC to allowlist ==="
echo "SSID: $SSID ($wlan_id)"
echo "Current filter_enabled=$filter_on  policy=$policy  size=$(echo "$current_list" | grep -c .)"
echo "Adding: $MAC  ($LABEL)"
echo "New allowlist size: $(echo "$new_list" | jq 'length')"

if [ "$MODE" != "--apply" ]; then
    echo ""
    echo "[preview only] re-run with --apply to commit."
    exit 0
fi

# Apply via UniFi API. PUT full wlanconf is risky (would overwrite); send only the delta.
payload=$(jq -n --argjson list "$new_list" '{mac_filter_list: $list}')
echo ""
echo "Applying..."
resp=$(homenet_api "/proxy/network/api/s/default/rest/wlanconf/$wlan_id" -X PUT -H "Content-Type: application/json" -d "$payload")
rc=$(echo "$resp" | jq -r '.meta.rc // "-"')

if [ "$rc" != "ok" ]; then
    echo "API error: $(echo "$resp" | jq -r '.meta.msg // .')"
    exit 1
fi

echo "Applied. MAC added to allowlist."

# Update HomeNetwork/inventory.md
if [ -f "$HOMENET_DIR/inventory.md" ]; then
    stamp=$(date +%Y-%m-%d)
    # Append to an Allowlist additions log at the bottom
    if ! grep -q "^## Allowlist Additions Log$" "$HOMENET_DIR/inventory.md"; then
        {
            echo ""
            echo "## Allowlist Additions Log"
            echo ""
        } >> "$HOMENET_DIR/inventory.md"
    fi
    echo "- $stamp: \`$MAC\` → \`$SSID\`  ($LABEL)" >> "$HOMENET_DIR/inventory.md"
    echo "Updated HomeNetwork/inventory.md"
fi
