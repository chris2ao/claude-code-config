#!/usr/bin/env bash
# homenet-ppsk-add.sh — append a PPSK entry to a PPSK-enabled SSID
# Usage: homenet-ppsk-add.sh <ssid> <password> [<vlan-network-name>] [--apply]

set -uo pipefail
source "$HOME/.claude/scripts/homenet-lib.sh"

SSID="${1:-}"
PSK="${2:-}"
VLAN_NAME="${3:-}"
MODE="${4:-preview}"

# Allow --apply in position 3 if no vlan name
if [ "$VLAN_NAME" = "--apply" ]; then
    MODE="--apply"
    VLAN_NAME=""
fi

[ -n "$SSID" ] && [ -n "$PSK" ] \
    || _homenet_fail "usage: homenet-ppsk-add.sh <ssid> <password> [<vlan-name>] [--apply]"

# PPSK/WPA requires >= 8 chars
[ "${#PSK}" -ge 8 ] || _homenet_fail "password too short (WPA-PSK requires >= 8 characters)"

homenet_load_secrets

wlan=$(homenet_wlan_by_name "$SSID")
[ -n "$wlan" ] && [ "$wlan" != "null" ] || _homenet_fail "SSID not found: $SSID"

wlan_id=$(echo "$wlan" | jq -r '._id')
ppsk_enabled=$(echo "$wlan" | jq -r '.private_preshared_keys_enabled // false')
[ "$ppsk_enabled" = "true" ] || _homenet_fail "PPSK is not enabled on '$SSID'. Enable it first or use the UI."

# Resolve target VLAN: explicit arg > SSID's current top-level networkconf_id
if [ -n "$VLAN_NAME" ]; then
    vlan_net_id=$(curl -sk -H "X-API-Key: $UNIFI_API_KEY" "$UNIFI_HOST/proxy/network/api/s/default/rest/networkconf" | \
        jq -r --arg n "$VLAN_NAME" '.data[] | select(.name == $n) | ._id' | head -n1)
    [ -n "$vlan_net_id" ] || _homenet_fail "network/VLAN not found: $VLAN_NAME"
else
    # Reuse the SSID's default networkconf_id so behavior matches existing entries
    vlan_net_id=$(echo "$wlan" | jq -r '.networkconf_id')
fi

# Check duplicate
current_ppsks=$(echo "$wlan" | jq '.private_preshared_keys // []')
exists=$(echo "$current_ppsks" | jq --arg p "$PSK" '[.[] | select(.password == $p)] | length')
if [ "$exists" -gt 0 ]; then
    echo "PPSK with this password already exists on '$SSID'. No change."
    exit 0
fi

new_entry=$(jq -n --arg p "$PSK" --arg v "$vlan_net_id" '{password: $p, networkconf_id: $v}')
new_ppsks=$(echo "$current_ppsks" | jq --argjson e "$new_entry" '. + [$e]')
new_size=$(echo "$new_ppsks" | jq 'length')

psk_fingerprint=$(printf '%s' "$PSK" | shasum -a 256 | cut -c1-8)

echo ""
echo "=== Preview: add PPSK entry ==="
echo "SSID: $SSID ($wlan_id)"
echo "Current PPSK count: $(echo "$current_ppsks" | jq 'length')"
echo "New entry fingerprint (sha256 prefix): $psk_fingerprint"
echo "New entry target VLAN: $vlan_net_id"
echo "New PPSK count: $new_size"

if [ "$MODE" != "--apply" ]; then
    echo ""
    echo "[preview only] re-run with --apply to commit."
    exit 0
fi

payload=$(jq -n --argjson keys "$new_ppsks" '{private_preshared_keys: $keys}')
echo ""
echo "Applying..."
resp=$(homenet_api "/proxy/network/api/s/default/rest/wlanconf/$wlan_id" -X PUT -H "Content-Type: application/json" -d "$payload")
rc=$(echo "$resp" | jq -r '.meta.rc // "-"')

if [ "$rc" != "ok" ]; then
    echo "API error: $(echo "$resp" | jq -r '.meta.msg // .')"
    exit 1
fi

echo "Applied. PPSK count: $(echo "$current_ppsks" | jq 'length') → $new_size."

# Log to HomeNetwork (no plaintext password, use fingerprint for audit)
if [ -f "$HOMENET_DIR/investigations.md" ]; then
    stamp=$(date +%Y-%m-%d\ %H:%M)
    {
        echo ""
        echo "### PPSK Added: $SSID"
        echo "- $stamp: added entry sha256-prefix=\`$psk_fingerprint\` → VLAN id \`$vlan_net_id\` (count $(echo "$current_ppsks" | jq 'length') → $new_size)"
    } >> "$HOMENET_DIR/investigations.md"
    echo "Logged to HomeNetwork/investigations.md (password fingerprint only, not plaintext)"
fi
