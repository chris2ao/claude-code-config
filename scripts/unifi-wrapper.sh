#!/usr/bin/env bash
set -a
source ~/.claude/secrets/secrets.env
set +a
exec uv run --directory /Users/chris2ao/GitProjects/chris2ao-unifi-mcp python -m unifi_mcp "$@"
