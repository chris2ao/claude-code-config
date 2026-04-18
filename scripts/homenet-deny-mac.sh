#!/usr/bin/env bash
# homenet-deny-mac.sh — remove a MAC from an SSID's allowlist
# Usage: homenet-deny-mac.sh <ssid-name> <mac> [--apply]

set -uo pipefail
source "$HOME/.claude/scripts/homenet-lib.sh"

SSID="${1:-}"
MAC_RAW="${2:-}"
MODE="${3:-preview}"
KICK_FLAG="${4:-}"

[ -n "$SSID" ] && [ -n "$MAC_RAW" ] \
    || _homenet_fail "usage: homenet-deny-mac.sh <ssid> <mac> [--apply] [--kick]"

homenet_validate_mac "$MAC_RAW"
MAC=$(homenet_normalize_mac "$MAC_RAW")
homenet_load_secrets

wlan=$(homenet_wlan_by_name "$SSID")
[ -n "$wlan" ] && [ "$wlan" != "null" ] || _homenet_fail "SSID not found: $SSID"

wlan_id=$(echo "$wlan" | jq -r '._id')
current_list=$(echo "$wlan" | jq -r '(.mac_filter_list // []) | .[]' | tr '[:upper:]' '[:lower:]')
filter_on=$(echo "$wlan" | jq -r '.mac_filter_enabled')

if ! echo "$current_list" | grep -qx "$MAC"; then
    echo "MAC $MAC is not on the allowlist for '$SSID'. No change."
    exit 0
fi

new_list=$(echo "$current_list" | grep -vx "$MAC" | grep -v '^$' | jq -Rn '[inputs]')
new_size=$(echo "$new_list" | jq 'length')

echo ""
echo "=== Preview: remove MAC from allowlist ==="
echo "SSID: $SSID ($wlan_id)"
echo "Current filter_enabled=$filter_on  size=$(echo "$current_list" | grep -c .)"
echo "Removing: $MAC"
echo "New allowlist size: $new_size"

if [ "$filter_on" = "true" ] && [ "$new_size" -eq 0 ]; then
    echo ""
    echo "[!] WARNING: removing this MAC leaves allowlist EMPTY while filter is ENABLED."
    echo "[!] Every client on '$SSID' will be kicked. Disable the filter first with:"
    echo "    bash $HOME/.claude/scripts/homenet-filter.sh off \"$SSID\" --apply"
    if [ "$MODE" = "--apply" ]; then
        echo "[!] Refusing to apply. Re-run with --force-lockout to override."
        exit 1
    fi
fi

if [ "$MODE" != "--apply" ] && [ "$MODE" != "--force-lockout" ]; then
    echo ""
    echo "[preview only] re-run with --apply to commit."
    exit 0
fi

# Apply via UniFi API
payload=$(jq -n --argjson list "$new_list" '{mac_filter_list: $list}')
echo ""
echo "Applying..."
resp=$(homenet_api "/proxy/network/api/s/default/rest/wlanconf/$wlan_id" -X PUT -H "Content-Type: application/json" -d "$payload")
rc=$(echo "$resp" | jq -r '.meta.rc // "-"')

if [ "$rc" != "ok" ]; then
    echo "API error: $(echo "$resp" | jq -r '.meta.msg // .')"
    exit 1
fi

echo "Applied. MAC removed from allowlist."

# Log the revocation to investigations.md
if [ -f "$HOMENET_DIR/investigations.md" ]; then
    stamp=$(date +%Y-%m-%d\ %H:%M)
    {
        echo ""
        echo "### Allowlist Revocation: $SSID"
        echo "- $stamp: removed \`$MAC\` (list size $(echo "$current_list" | grep -c .) → $new_size)"
    } >> "$HOMENET_DIR/investigations.md"
    echo "Logged to HomeNetwork/investigations.md"
fi

# Optional kick-sta: force already-associated client to re-auth (and be denied)
if [ "$KICK_FLAG" = "--kick" ]; then
    active_now=$(homenet_api "/proxy/network/api/s/default/stat/sta" | jq -r --arg m "$MAC" '.data[] | select(.mac == $m) | .mac' | head -n1)
    if [ -z "$active_now" ]; then
        echo ""
        echo "Note: $MAC is not currently associated. No kick needed."
    else
        echo ""
        echo "Kicking $MAC via /cmd/stamgr kick-sta..."
        kick=$(homenet_api "/proxy/network/api/s/default/cmd/stamgr" -X POST \
            -H "Content-Type: application/json" \
            -d "$(jq -n --arg m "$MAC" '{cmd: "kick-sta", mac: $m}')")
        kick_rc=$(echo "$kick" | jq -r '.meta.rc // "-"')
        if [ "$kick_rc" = "ok" ]; then
            echo "Kicked. Device will be denied on next re-association attempt."
            if [ -f "$HOMENET_DIR/investigations.md" ]; then
                echo "- $(date +%Y-%m-%d\ %H:%M): kicked \`$MAC\` (kick-sta) after allowlist removal" >> "$HOMENET_DIR/investigations.md"
            fi
        else
            echo "Kick failed: $(echo "$kick" | jq -r '.meta.msg // .')"
        fi
    fi
fi
