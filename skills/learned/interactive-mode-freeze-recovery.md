# Interactive Mode Freeze Recovery

**Extracted:** 2026-02-13
**Context:** Multiple instances of Claude Code opening but not accepting keyboard input

## Problem
Claude Code launches and displays the TUI interface, but:
- Keyboard input is ignored (typing does nothing)
- Ctrl+C doesn't work (can't exit)
- `claude --print "msg"` works fine (bypasses TUI)
- The issue persists across terminal restarts

This indicates stale global state corruption, not a TUI rendering issue.

## Root Cause
The project's entry in `~/.claude.json` under `"projects"` and `"githubRepoPaths"` contains stale or corrupted metadata. Claude Code loads this state at startup and enters an invalid state where the TUI renders but input handling is broken.

The project state directory at `~/.claude/projects/<encoded-path>/` contains:
- Conversation transcripts (`.jsonl` files)
- Cached context
- Session state

When this becomes corrupted, Claude Code can't properly initialize the interactive session.

## Solution
**Step 1: Verify the issue**
```bash
# This should work (bypasses TUI)
claude --print "say hello"

# This should freeze (TUI opens but no input)
claude
# (keyboard input ignored, Ctrl+C doesn't work)
```

**Step 2: Clean global state**
```bash
# 1. Kill any hanging Claude Code processes
taskkill /F /IM claude.exe  # Windows
# OR
pkill -9 claude  # Linux/Mac

# 2. Edit ~/.claude.json
# Remove the project entry from both:
#   - "projects": { "<path>": {...} }
#   - "githubRepoPaths": { "<repo>": "<path>" }
# Leave other projects intact

# 3. Rename the project state directory (don't delete yet)
cd ~/.claude/projects/
mv <encoded-path> <encoded-path>.old
```

**Step 3: Restart Claude Code**
```bash
claude
# Should rebuild fresh project state and accept input normally
```

**Step 4: Verify recovery**
- Keyboard input should work
- Ctrl+C should exit cleanly
- Session should resume with fresh context

**Step 5: Clean up old state (optional)**
```bash
# After verifying recovery, delete the old state
rm -rf ~/.claude/projects/<encoded-path>.old
```

## Prevention
This corruption typically happens after:
- Multiple rapid restarts during debugging
- Forcibly killing Claude Code processes mid-session
- Filesystem errors during transcript writes
- OneDrive sync conflicts (if `~/.claude/` is in OneDrive)

**Mitigation:** Don't keep `~/.claude/` in cloud-synced directories. Move it to local disk.

## When to Use
- Claude Code TUI renders but keyboard input is ignored
- Ctrl+C doesn't exit the session
- `claude --print` works but interactive mode doesn't
- After multiple force-kills or crashes
- After moving the project directory or changing git repo URL
