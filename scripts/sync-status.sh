#!/usr/bin/env bash
# sync-status.sh - Check Syncthing sync status before switching workstations
# Usage: ~/.claude/scripts/sync-status.sh

set -uo pipefail

SYNCTHING_API="http://127.0.0.1:8384/rest"
# Platform-specific Syncthing config path
if [[ "$OSTYPE" == darwin* ]]; then
    CONFIG_FILE="$HOME/Library/Application Support/Syncthing/config.xml"
elif [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then
    CONFIG_FILE="$LOCALAPPDATA/Syncthing/config.xml"
else
    CONFIG_FILE="$HOME/.config/syncthing/config.xml"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Syncthing Sync Status ==="
echo ""

# Check if Syncthing is running
if ! pgrep -q syncthing; then
    echo -e "${RED}Syncthing is NOT running${NC}"
    echo "Start it with: brew services start syncthing"
    exit 1
fi
echo -e "${GREEN}Syncthing is running${NC}"

# Try to get API key from config
API_KEY=""
if [ -f "$CONFIG_FILE" ]; then
    API_KEY=$(sed -n 's/.*<apikey>\([^<]*\)<\/apikey>.*/\1/p' "$CONFIG_FILE" 2>/dev/null || true)
fi

if [ -z "$API_KEY" ]; then
    echo -e "${YELLOW}Could not read API key from config. Checking basic connectivity only.${NC}"
    if curl -s -o /dev/null -w "%{http_code}" "$SYNCTHING_API/system/ping" | grep -q "403\|401"; then
        echo -e "${GREEN}Syncthing API is responding (auth required)${NC}"
    elif curl -s "$SYNCTHING_API/system/ping" | grep -q "pong"; then
        echo -e "${GREEN}Syncthing API is responding${NC}"
    else
        echo -e "${RED}Syncthing API is not responding${NC}"
    fi
    echo ""
    echo "For full status, set API key or check Web UI: http://127.0.0.1:8384"
    exit 0
fi

AUTH_HEADER="X-API-Key: $API_KEY"

# Get system status
echo ""
echo "--- System ---"
SYS_STATUS=$(curl -s -H "$AUTH_HEADER" "$SYNCTHING_API/system/status" 2>/dev/null)
if [ -n "$SYS_STATUS" ]; then
    MY_ID=$(echo "$SYS_STATUS" | jq -r '.myID // "unknown"' 2>/dev/null)
    UPTIME=$(echo "$SYS_STATUS" | jq -r '.uptime // 0' 2>/dev/null)
    UPTIME_HRS=$((UPTIME / 3600))
    UPTIME_MIN=$(((UPTIME % 3600) / 60))
    echo "Device ID: ${MY_ID:0:12}..."
    echo "Uptime: ${UPTIME_HRS}h ${UPTIME_MIN}m"
fi

# Get connections
echo ""
echo "--- Connections ---"
CONNECTIONS=$(curl -s -H "$AUTH_HEADER" "$SYNCTHING_API/system/connections" 2>/dev/null)
if [ -n "$CONNECTIONS" ]; then
    CONNECTED=$(echo "$CONNECTIONS" | jq '[.connections | to_entries[] | select(.value.connected == true)] | length' 2>/dev/null || echo "0")
    TOTAL=$(echo "$CONNECTIONS" | jq '[.connections | to_entries[]] | length' 2>/dev/null || echo "0")
    if [ "$CONNECTED" -gt 0 ]; then
        echo -e "${GREEN}$CONNECTED of $TOTAL devices connected${NC}"
    elif [ "$TOTAL" -gt 0 ]; then
        echo -e "${YELLOW}0 of $TOTAL devices connected (other machine may be off)${NC}"
    else
        echo -e "${YELLOW}No remote devices configured yet${NC}"
    fi
fi

# Get folder statuses
echo ""
echo "--- Folders ---"
FOLDERS=$(curl -s -H "$AUTH_HEADER" "$SYNCTHING_API/system/config" 2>/dev/null | jq -r '.folders[]?.id' 2>/dev/null)
if [ -n "$FOLDERS" ]; then
    while IFS= read -r folder_id; do
        FOLDER_STATUS=$(curl -s -H "$AUTH_HEADER" "$SYNCTHING_API/db/status?folder=$folder_id" 2>/dev/null)
        STATE=$(echo "$FOLDER_STATUS" | jq -r '.state // "unknown"' 2>/dev/null)
        NEED_FILES=$(echo "$FOLDER_STATUS" | jq -r '.needFiles // 0' 2>/dev/null)
        ERRORS=$(echo "$FOLDER_STATUS" | jq -r '.pullErrors // 0' 2>/dev/null)

        if [ "$STATE" = "idle" ] && [ "$NEED_FILES" = "0" ]; then
            echo -e "  ${GREEN}$folder_id: in sync${NC}"
        elif [ "$STATE" = "syncing" ]; then
            echo -e "  ${YELLOW}$folder_id: syncing ($NEED_FILES files needed)${NC}"
        else
            echo -e "  ${YELLOW}$folder_id: $STATE (need: $NEED_FILES, errors: $ERRORS)${NC}"
        fi
    done <<< "$FOLDERS"
else
    echo -e "  ${YELLOW}No folders configured yet${NC}"
fi

# Check for conflict files
echo ""
echo "--- Conflict Files ---"
CONFLICTS=0
for dir in "$HOME/.claude"; do
    if [ -d "$dir" ]; then
        COUNT=$(find "$dir" -name "*.sync-conflict-*" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$COUNT" -gt 0 ]; then
            echo -e "  ${RED}$dir: $COUNT conflict file(s)${NC}"
            find "$dir" -name "*.sync-conflict-*" 2>/dev/null | head -5 | while read -r f; do
                echo "    $f"
            done
            CONFLICTS=$((CONFLICTS + COUNT))
        fi
    fi
done
if [ "$CONFLICTS" -eq 0 ]; then
    echo -e "  ${GREEN}No conflicts found${NC}"
fi

echo ""
echo "Web UI: http://127.0.0.1:8384"
