---
id: bash-macos-arrays
trigger: "when scripts fail on macOS with unbound variable errors after set -u"
confidence: 0.4
domain: "bash"
source: "session-archive-ingestion"
created: "2026-03-08"
---

# Bash 3.x Empty Array Handling on macOS

## Action
macOS ships bash 3.x which treats `"${empty_array[@]}"` as unbound variable when `set -u` is enabled. Use `"${array[@]:-}"` or check array length before iterating.

## Pattern
1. Initialize arrays with `ARRAY=()`
2. Before iterating: `if [ ${#ARRAY[@]} -gt 0 ]; then`
3. Or use default: `"${ARRAY[@]:-}"`
4. Use `+=` for appending instead of modern bash 4+ syntax

## Evidence
- 2026-03-06: wrap-up-survey.sh failed on macOS with unbound variable error on empty array with set -u enabled.
