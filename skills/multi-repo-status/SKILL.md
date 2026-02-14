---
description: "Quick dashboard showing git status across all project repos"
---

# /multi-repo-status - Repository Dashboard

Run `git status`, `git log -1 --oneline`, and branch info across all 4 repos in parallel. Return a formatted status table.

## Repository Map

| Repo | Local Path | Remote | Default Branch |
|------|-----------|--------|----------------|
| CJClaude_1 | `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\CJClaude_1` | `chris2ao/CJClaude_1` | main |
| cryptoflexllc | `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\cryptoflexllc` | `chris2ao/cryptoflexllc` | main |
| cryptoflex-ops | `D:\Users\chris_dnlqpqd\OneDrive\AI_Projects\Claude\cryptoflex-ops` | `chris2ao/cryptoflex-ops` | main |
| claude-code-config | `D:\Users\chris_dnlqpqd\.claude` | `chris2ao/claude-code-config` | master |

## Execution

Run these commands in parallel (one per repo):
```bash
cd "<path>" && git status --short && git log -1 --oneline && git rev-parse --abbrev-ref HEAD
```

## Output Format

Present results as:

```
| Repo | Branch | Clean? | Last Commit | Changes |
|------|--------|--------|-------------|---------|
```

Where Changes shows: M=modified, U=untracked, A=added, D=deleted with counts.

## Notes
- claude-code-config uses `master` branch, not `main`
- Always `export PATH="$PATH:/c/Program Files/GitHub CLI"` before any push operations
