#!/usr/bin/env bash
# homenet-review.sh — reconcile allowlist vs actual client usage per SSID
# Usage: homenet-review.sh [ssid-name]
# If ssid-name omitted, reviews every Wi-Fi SSID.

set -uo pipefail
source "$HOME/.claude/scripts/homenet-lib.sh"

TARGET_SSID="${1:-}"
WINDOW_DAYS="${HOMENET_REVIEW_WINDOW_DAYS:-30}"

homenet_load_secrets
cutoff=$(( $(date +%s) - WINDOW_DAYS * 86400 ))

active=$(homenet_api "/proxy/network/api/s/default/stat/sta")
[ "$(homenet_last_code)" = "200" ] || _homenet_fail "stat/sta returned $(homenet_last_code)"
users=$(homenet_api "/proxy/network/api/s/default/rest/user")
[ "$(homenet_last_code)" = "200" ] || _homenet_fail "rest/user returned $(homenet_last_code)"
wlans=$(homenet_wlans)

# Iterate SSIDs
echo "$wlans" | jq -c --arg target "$TARGET_SSID" '.data[] | select($target == "" or .name == $target)' | while read -r wlan; do
    name=$(echo "$wlan" | jq -r '.name')
    id=$(echo "$wlan" | jq -r '._id')
    filter_on=$(echo "$wlan" | jq -r '.mac_filter_enabled')
    policy=$(echo "$wlan" | jq -r '.mac_filter_policy')
    allowlist=$(echo "$wlan" | jq -r '(.mac_filter_list // []) | .[]' | sort -u)

    echo ""
    echo "=== $name ==="
    echo "filter_enabled=$filter_on  policy=$policy  allowlist_size=$(echo "$allowlist" | grep -c .)"

    # Active MACs on this SSID (Wi-Fi only)
    active_macs=$(echo "$active" | jq -r --arg id "$id" '.data[] | select(.wlanconf_id == $id) | .mac' | sort -u)

    # Historical MACs on this SSID seen within window
    hist_macs=$(echo "$users" | jq -r --arg id "$id" --argjson cut "$cutoff" \
        '.data[] | select(.wlanconf_id == $id and .last_seen > $cut) | .mac' | sort -u)

    # Merge active + hist for "ever seen recently"
    seen=$(printf "%s\n%s\n" "$active_macs" "$hist_macs" | sort -u | grep -v '^$' || true)

    # Category 1: active but not on allowlist (would be blocked if enabled)
    blocked_if_enabled=$(comm -23 <(echo "$active_macs" | grep -v '^$' || true) <(echo "$allowlist" | grep -v '^$' || true))
    # Category 2: on allowlist but not seen in window (stale)
    stale=$(comm -23 <(echo "$allowlist" | grep -v '^$' || true) <(echo "$seen" | grep -v '^$' || true))
    # Category 3: seen (historical) but not on allowlist (eligible to add)
    eligible=$(comm -23 <(echo "$seen" | grep -v '^$' || true) <(echo "$allowlist" | grep -v '^$' || true))

    echo ""
    echo "  Active now: $(echo "$active_macs" | grep -c .)"
    echo "  Seen in last ${WINDOW_DAYS}d: $(echo "$seen" | grep -c .)"
    echo ""

    enrich_row() {
        local mac="$1"
        local src="$2"
        local info
        info=$(echo "$users" | jq -r --arg m "$mac" '.data[] | select(.mac == $m) | [.hostname // "-", .oui // "-", .name // "-"] | @tsv' | head -n1)
        printf "    %s  %s  %s\n" "$mac" "$src" "${info:-$mac}"
    }

    if [ -n "$blocked_if_enabled" ] && [ "$(echo "$blocked_if_enabled" | grep -c .)" -gt 0 ]; then
        echo "  [!] Active-but-NOT-on-allowlist (would be blocked if filter enabled):"
        while read -r m; do [ -n "$m" ] && enrich_row "$m" "active"; done <<< "$blocked_if_enabled"
    fi
    if [ -n "$eligible" ] && [ "$(echo "$eligible" | grep -c .)" -gt 0 ]; then
        echo "  [+] Seen in window, not yet on allowlist (candidates to add):"
        while read -r m; do [ -n "$m" ] && enrich_row "$m" "historical"; done <<< "$eligible"
    fi
    if [ -n "$stale" ] && [ "$(echo "$stale" | grep -c .)" -gt 0 ]; then
        echo "  [-] On allowlist, not seen in ${WINDOW_DAYS}d (stale, consider removing):"
        while read -r m; do [ -n "$m" ] && printf "    %s\n" "$m"; done <<< "$stale"
    fi
done

echo ""
echo "Done."
