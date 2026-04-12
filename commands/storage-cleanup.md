---
platform: darwin
description: "Scan Mac storage, identify cleanup opportunities, and move safe files to external drive"
---

# /storage-cleanup - Mac Storage Optimization

Scan local storage utilization, identify opportunities to reclaim space, and optionally move safe files to an attached external drive.

## Arguments

- `scan` (default): Full analysis and recommendations only
- `execute`: Run scan and execute approved cleanup actions
- `quick`: Fast scan of top-level consumers only (no deep dive)

## Phase 1: Discovery (Parallel Scans)

Launch 3 parallel agents (model: haiku) to scan storage simultaneously:

### Agent 1: System Overview
Run these commands and collect results:
```bash
# Overall disk state
df -h / /System/Volumes/Data 2>/dev/null | tail -2

# External drives available
df -h | grep -i "/Volumes/" | grep -v "System\|Preboot\|Update\|xarts\|iSCPreboot\|Hardware\|home"

# Top-level home directory sizes
du -sh ~/Library ~/GitProjects ~/Downloads ~/Documents ~/Desktop ~/Movies ~/Music ~/Pictures 2>/dev/null | sort -rh

# Hidden directories consuming space
du -sh ~/.claude ~/.ollama ~/.docker ~/.npm ~/.pnpm-store ~/.cache ~/.local 2>/dev/null | sort -rh
```

### Agent 2: Library Deep Dive
Run these commands and collect results:
```bash
# Application Support breakdown (top 15)
du -sh ~/Library/Application\ Support/* 2>/dev/null | sort -rh | head -15

# Caches breakdown (top 15)
du -sh ~/Library/Caches/* 2>/dev/null | sort -rh | head -15

# Developer tools
du -sh ~/Library/Developer/* 2>/dev/null | sort -rh | head -10

# Containers (app sandboxes)
du -sh ~/Library/Containers/* 2>/dev/null | sort -rh | head -10

# Mail and Messages
du -sh ~/Library/Mail ~/Library/Messages ~/Library/Messages/Attachments 2>/dev/null | sort -rh

# Logs
find ~/Library/Logs -type f -size +10M 2>/dev/null -exec du -sh {} \; | sort -rh | head -10
```

### Agent 3: Developer Artifacts
Run these commands and collect results:
```bash
# node_modules directories (regeneratable)
find ~/GitProjects -name "node_modules" -type d -maxdepth 3 -exec du -sh {} \; 2>/dev/null | sort -rh

# .next build caches (regeneratable)
find ~/GitProjects -name ".next" -type d -maxdepth 3 -exec du -sh {} \; 2>/dev/null | sort -rh

# Git repo sizes
du -sh ~/GitProjects/* 2>/dev/null | sort -rh | head -15

# Xcode artifacts
du -sh ~/Library/Developer/Xcode/DerivedData ~/Library/Developer/Xcode/iOS\ DeviceSupport ~/Library/Developer/CoreSimulator/Devices 2>/dev/null | sort -rh

# Homebrew cache
du -sh "$(brew --cache)" 2>/dev/null

# Docker images/volumes
docker system df 2>/dev/null

# Playwright/Cypress browser caches
du -sh ~/Library/Caches/ms-playwright ~/Library/Caches/Cypress 2>/dev/null

# pip/pnpm/npm caches
du -sh ~/Library/Caches/pip ~/.pnpm-store ~/Library/Caches/pnpm ~/.npm 2>/dev/null | sort -rh
```

## Phase 2: Classification

After all agents return, classify each finding into one of four categories:

### Category A: Safely Deletable (Regeneratable)
Items that can be recreated with a simple command. No data loss risk.
- `.next` build caches (rebuild with `npm run build`)
- `node_modules` for inactive projects (reinstall with `npm install`)
- Xcode DerivedData (Xcode regenerates on next build)
- Homebrew cache (packages already installed)
- Playwright/Cypress browser caches (reinstall with CLI)
- pip/pnpm/npm caches (packages already installed)
- Old log files (informational only)

### Category B: Safe to Move to External (No operational impact if disconnected)
Items that are archival, reference-only, or recreatable by download.
- Claude session archives (historical transcripts)
- Xcode iOS DeviceSupport (Xcode re-downloads as needed)
- CoreSimulator Devices (recreatable from Xcode)
- iMessage Attachments (local cache if Messages in iCloud enabled)
- Inactive git repositories (clone from remote if needed)
- Old Downloads (user can retrieve from source)
- Large media files not actively used

### Category C: Reducible via Settings
Items that require app-level configuration changes.
- iMessage: "Keep Messages" duration setting
- Mail: re-download preferences
- Photos: "Optimize Mac Storage" toggle
- Docker: prune unused images/volumes

### Category D: Active/Required (Do Not Touch)
Items needed for daily operations.
- Active project node_modules and .next caches
- Application Support for running apps
- Homebrew installation itself
- Active git repos
- System caches for running apps

## Phase 3: Report

Present findings in this format:

```markdown
## Storage Cleanup Report
*Scanned: [date] | Internal: [used]/[total] ([%]) | Free: [free]*
*External: [drive name] at [mount point] ([used]/[total])*

### Category A: Safely Deletable (Regeneratable)
| Item | Size | Delete Command |
|------|------|----------------|
| ... | ... | ... |
**Subtotal: [X] GB reclaimable**

### Category B: Safe to Move to External Drive
| Item | Size | Notes |
|------|------|-------|
| ... | ... | ... |
**Subtotal: [X] GB movable**

### Category C: Reducible via Settings
| Item | Size | Recommendation |
|------|------|----------------|
| ... | ... | ... |
**Potential savings: [X] GB**

### Summary
| Action | Space Freed |
|--------|-------------|
| Delete regeneratable (A) | X GB |
| Move to external (B) | X GB |
| Settings changes (C) | X GB |
| **Total potential** | **X GB** |
```

## Phase 4: Execution (only if `execute` argument passed)

If the user passed `execute` or approves actions after seeing the report:

1. **Confirm external drive is mounted** before any move operations
2. **Category A items**: Delete without further confirmation (they're regeneratable)
3. **Category B items**: 
   - Create timestamped backup directory: `/Volumes/[ExternalDrive]/MacBackup/[YYYY-MM-DD]/`
   - Use `rsync -a` to copy, then verify sizes match before deleting originals
   - Log all moves to `/Volumes/[ExternalDrive]/MacBackup/manifest.md`
4. **Category C items**: Present settings instructions to user (cannot be automated)
5. **Final verification**: Run `df -h` and report before/after comparison

## Phase 5: Manifest

After any execution, create or update a manifest on the external drive:

```markdown
# MacBackup Manifest
*Last updated: [date]*

## Contents
| Item | Original Path | Size | Date Moved | Restore Command |
|------|---------------|------|------------|-----------------|
| ... | ... | ... | ... | `rsync -a "/Volumes/.../item" "~/original/path/"` |
```

## Safety Rules

1. **NEVER delete** without confirming a copy exists (for Category B items)
2. **NEVER modify** iMessage/Mail databases (only attachment caches)
3. **NEVER delete** active project files (check git status first)
4. **NEVER remove** Homebrew itself, only its download cache
5. **Always verify** external drive is writable before moves: `touch /Volumes/[drive]/test && rm /Volumes/[drive]/test`
6. **Skip** any item where `du` reports Permission denied (SIP-protected)
7. **Verify rsync** completed successfully (compare source/dest sizes) before removing originals
8. **Preserve directory structure** when moving (don't flatten hierarchies)

## External Drive Detection

Auto-detect external drives by filtering `df -h` output:
- Exclude system volumes: VM, Preboot, Update, xarts, iSCPreboot, Hardware, Data/home
- Exclude the boot volume itself
- If multiple external drives found, ask user which to use
- If no external drive found, skip Category B and note it in the report

## Scheduling Note

This command is designed to run ad-hoc whenever the user feels storage pressure. For automated monitoring, consider a cron trigger that alerts when free space drops below 15%.
