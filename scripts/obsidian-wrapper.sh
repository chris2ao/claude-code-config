#!/usr/bin/env bash
set -a
source "$HOME/.claude/secrets/secrets.env"
set +a
exec /Users/chris2ao/.openclaw/.obsidian/plugins/mcp-tools/bin/mcp-server "$@"
