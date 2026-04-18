#!/usr/bin/env bash
# homenet-lib.sh — shared helpers for /homenet-* skills
# Source with: source "$HOME/.claude/scripts/homenet-lib.sh"

set -uo pipefail

HOMENET_DIR="${HOMENET_DIR:-/Users/chris2ao/GitProjects/CJClaudin_Mac/HomeNetwork}"
SECRETS_FILE="${SECRETS_FILE:-$HOME/.claude/secrets/secrets.env}"

_homenet_fail() { echo "homenet: $*" >&2; exit 1; }

homenet_load_secrets() {
    [ -f "$SECRETS_FILE" ] || _homenet_fail "secrets file not found: $SECRETS_FILE"
    # shellcheck disable=SC1090
    source "$SECRETS_FILE"
    [ -n "${UNIFI_HOST:-}" ] || _homenet_fail "UNIFI_HOST not set"
    [ -n "${UNIFI_API_KEY:-}" ] || _homenet_fail "UNIFI_API_KEY not set"
}

# Thin curl wrapper. $1 = path starting with /. stdout = response body.
# Writes HTTP status to /tmp/homenet-http-code so callers can read it
# across subshell boundaries (command substitution runs in a subshell).
homenet_api() {
    local path="$1"
    shift || true
    local tmp
    tmp=$(mktemp)
    curl -sk -o "$tmp" -w "%{http_code}" -H "X-API-Key: $UNIFI_API_KEY" "$@" "$UNIFI_HOST$path" > /tmp/homenet-http-code
    cat "$tmp"
    rm -f "$tmp"
}

homenet_last_code() {
    cat /tmp/homenet-http-code 2>/dev/null || echo "0"
}

# GET all SSIDs (wlanconf). Caches within a single script invocation.
homenet_wlans() {
    if [ -z "${_HOMENET_WLAN_CACHE:-}" ]; then
        _HOMENET_WLAN_CACHE=$(homenet_api "/proxy/network/api/s/default/rest/wlanconf")
    fi
    echo "$_HOMENET_WLAN_CACHE"
}

# Resolve friendly SSID name to wlan_id. $1 = name.
homenet_ssid_id() {
    local name="$1"
    homenet_wlans | jq -r --arg n "$name" '.data[] | select(.name == $n) | ._id' | head -n1
}

# Resolve wlan_id to friendly name
homenet_ssid_name() {
    local id="$1"
    homenet_wlans | jq -r --arg i "$id" '.data[] | select(._id == $i) | .name' | head -n1
}

# Full wlanconf entry for an SSID by name. stdout = JSON object.
homenet_wlan_by_name() {
    local name="$1"
    homenet_wlans | jq --arg n "$name" '.data[] | select(.name == $n)'
}

homenet_validate_mac() {
    local mac="$1"
    echo "$mac" | grep -qiE '^([0-9a-f]{2}:){5}[0-9a-f]{2}$' || _homenet_fail "invalid MAC: $mac (expected aa:bb:cc:dd:ee:ff)"
}

homenet_normalize_mac() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

homenet_require_dir() {
    [ -d "$HOMENET_DIR" ] || _homenet_fail "HomeNetwork dir missing: $HOMENET_DIR"
}

homenet_timestamp() {
    date +%Y-%m-%d-%H%M%S
}

homenet_log() {
    echo "[$(date +%H:%M:%S)] $*"
}
