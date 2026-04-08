#!/usr/bin/env bash
set -a
source ~/.claude/secrets/secrets.env
set +a
exec npx -y exa-mcp-server "$@"
