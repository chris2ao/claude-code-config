# Token and Secret Safety in AI Assistant Output

**Extracted:** 2026-02-08
**Context:** Preventing accidental exposure of secrets (API keys, PATs, OAuth tokens) when reading and displaying config files

## Problem
When reading configuration files like `~/.claude.json`, `~/.env`, or MCP server configs, the file contents may contain plaintext secrets (API keys, personal access tokens, OAuth tokens). Outputting these in responses creates exposure risk, especially in:
- Public repo conversation transcripts
- Session archives
- Shared screen recordings
- Copy-pasted chat logs

GitHub's secret scanning will auto-revoke tokens detected in public repos, but the exposure window still exists.

## Solution
When reading files that may contain secrets:
1. **Never echo full token values** in responses — redact to first 10-15 chars + `...`
2. **Flag the security issue** immediately when a plaintext secret is discovered
3. **Recommend rotation** as the first action, before any other fixes
4. **Use environment variables or secret managers** instead of hardcoded values

When configuring MCP servers or similar:
- Prefer `gh auth token` output over hardcoded PATs
- Use `apiKeyHelper` scripts that fetch tokens dynamically
- Never commit secrets to git — use `.env` files (gitignored) or OS keychains

## Example
```
# BAD - exposes full token
"GITHUB_PERSONAL_ACCESS_TOKEN": "github_pat_11AEEPIYQ0abc123..."

# GOOD - redacted in output
Found GitHub PAT in ~/.claude.json (github_pat_11AE...redacted)
This token should be rotated immediately.
```

## When to Use
- Reading any config file that might contain secrets (`~/.claude.json`, `.env`, MCP configs)
- Displaying file contents to the user
- Logging or archiving session data
- Any time a string matches common secret patterns (github_pat_, sk-, ghp_, gho_, etc.)
