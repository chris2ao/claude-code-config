#!/usr/bin/env bash
# Wrapper to run notebooklm CLI from its dedicated venv
# Installed at: ~/.notebooklm-venv (Python 3.14, uv-managed)
# Account: chrisjohnson@cryptoflexllc.com
exec "$HOME/.notebooklm-venv/bin/notebooklm" "$@"
