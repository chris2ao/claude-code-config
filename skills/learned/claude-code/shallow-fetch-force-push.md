# Shallow Fetch Breaks Force Push

**Extracted:** 2026-02-11
**Context:** When replacing a repo's contents via upstream remote + force push

## Problem
`git fetch upstream --depth=1` followed by `git reset --hard upstream/main` and `git push --force` fails with:
```
remote: fatal: did not receive expected object <sha>
error: remote unpack failed: index-pack failed
```
The shallow clone doesn't have all the objects the remote needs to process the push.

## Solution
Use a full fetch (no `--depth` flag) before force pushing:
```bash
git fetch upstream          # full fetch, not --depth=1
git reset --hard upstream/main
git push origin main --force
```
If you already did a shallow fetch, deepen it:
```bash
git fetch upstream --unshallow
```

## When to Use
- Replacing repo contents with upstream via force push
- Any workflow combining shallow clones with push operations
