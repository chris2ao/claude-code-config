---
platform: macos
description: "cmux terminal CLI reference: workspaces, panes, browser automation, notifications, sidebar, and agent orchestration"
---

# /cmux - cmux Terminal CLI Reference

Complete CLI reference for cmux, the Ghostty-based macOS terminal built for AI coding agents.

## Prerequisites

cmux must be running and the CLI symlink must exist:
```bash
sudo ln -sf "/Applications/cmux.app/Contents/Resources/bin/cmux" /usr/local/bin/cmux
```

Verify with: `cmux ping`

## Environment Variables (Auto-Set Inside cmux)

| Variable | Purpose |
|----------|---------|
| `CMUX_WORKSPACE_ID` | Current workspace ID |
| `CMUX_SURFACE_ID` | Current surface/pane ID |
| `CMUX_SOCKET_PATH` | Override socket location |
| `CMUX_SOCKET_MODE` | Access mode: `off`, `cmuxOnly` (default), `allowAll` |
| `TERM_PROGRAM` | Set to `ghostty` |
| `TERM` | Set to `xterm-ghostty` |

## Detection

Check if running inside cmux before using commands:
```bash
if cmux ping 2>/dev/null; then
  echo "cmux is available"
else
  echo "Not running in cmux"
fi
```

---

## Workspace Commands

Workspaces are top-level containers (like tmux sessions). Each has its own set of panes.

| Command | Description |
|---------|-------------|
| `cmux list-workspaces` | List all open workspaces |
| `cmux new-workspace` | Create a new workspace |
| `cmux new-workspace --cwd ~/projects/app` | Create workspace in specific directory |
| `cmux current-workspace` | Get the active workspace ID |
| `cmux select-workspace <ID>` | Switch to a workspace |
| `cmux close-workspace` | Close the current workspace |
| `cmux close-workspace <ID>` | Close a specific workspace |

**Keyboard shortcuts:**
- `Cmd+N` - New workspace
- `Cmd+1` through `Cmd+8` - Jump to workspace 1-8
- `Cmd+9` - Jump to last workspace
- `Cmd+W` - Close workspace
- `Cmd+Shift+R` - Rename workspace

---

## Pane and Surface Commands

Surfaces are individual panes (terminal or browser) within a workspace.

| Command | Description |
|---------|-------------|
| `cmux list-surfaces` | List all surfaces in current workspace |
| `cmux focus-surface <ID>` | Focus a specific surface |
| `cmux new-split right` | Split pane to the right |
| `cmux new-split down` | Split pane downward |
| `cmux new-split left` | Split pane to the left |
| `cmux new-split up` | Split pane upward |
| `cmux new-pane --type terminal` | Add a terminal surface |
| `cmux new-pane --type browser` | Add a browser surface |
| `cmux new-pane --type browser --url <URL>` | Add browser surface at URL |
| `cmux close-surface --surface <ID>` | Close a specific pane |
| `cmux tree --all` | Inspect current layout structure |

**Keyboard shortcuts:**
- `Cmd+D` - Split right
- `Cmd+Shift+D` - Split down
- `Cmd+Option+Arrow` - Focus pane directionally
- `Cmd+Option+D` - Split browser right
- `Cmd+Option+Shift+D` - Split browser down
- `Cmd+T` - New surface
- `Cmd+[` / `Cmd+]` - Previous/next surface

---

## Input Commands

Send text and keystrokes to terminal panes. Essential for agent orchestration.

### Send Text
```bash
# Send to the currently focused terminal
cmux send "npm run dev"

# Send to a specific surface
cmux send --surface <SURFACE_ID> "npm run dev"
```

### Send Key Press
```bash
# Send to focused terminal
cmux send-key enter

# Send to a specific surface
cmux send-key --surface <SURFACE_ID> enter
```

**Supported keys:** `enter`, `tab`, `escape`, `backspace`, `delete`, `up`, `down`, `left`, `right`

### Read Screen Output
```bash
# Read current screen content
cmux read-screen --surface <SURFACE_ID>

# Read with scrollback history
cmux read-screen --surface <SURFACE_ID> --scrollback --lines 200
```

### Common Patterns

**Launch a process in another pane:**
```bash
cmux new-split right
cmux send --surface <NEW_SURFACE_ID> "cd ~/GitProjects/my-game && npm run dev"
cmux send-key --surface <NEW_SURFACE_ID> enter
```

**Send a command and wait for output:**
```bash
cmux send --surface <ID> "npm test"
cmux send-key --surface <ID> enter
sleep 5
cmux read-screen --surface <ID>
```

---

## Notification Commands

Desktop notifications with pane flash indicators. Critical for multi-agent attention routing.

| Command | Description |
|---------|-------------|
| `cmux notify --title "Title" --body "Message"` | Send a notification |
| `cmux notify --title "T" --body "M" --subtitle "Sub"` | Notification with subtitle |
| `cmux list-notifications` | List all notifications |
| `cmux clear-notifications` | Clear all notifications |
| `cmux trigger-flash --surface <ID>` | Visual blue border flash on a pane |

### OSC Escape Sequences (Alternative)

Send notifications via terminal escape sequences (works from any process):
```bash
# Simple notification (OSC 777)
printf '\033]777;notify;%s;%s\007' "Build Done" "All tests passed"

# Rich notification with ID (OSC 99)
printf '\033]99;i=%s;%s\007' "build-1" "subtitle=Build|body=Complete"
```

### Claude Code Hook Integration

Create a hook script to notify on agent completion:
```bash
#!/bin/bash
cmux notify --title "Claude Code" --body "Agent finished task"
```

**Keyboard shortcuts:**
- `Cmd+Shift+I` - Show notifications panel
- `Cmd+Shift+U` - Jump to latest unread notification

---

## Sidebar Metadata Commands

The sidebar shows contextual information per workspace: git branch, ports, progress, logs.

### Status Pills
```bash
# Set a status pill (use unique keys)
cmux set-status --key branch "main"
cmux set-status --key branch "main" --icon arrow.triangle.branch

# Clear a specific status
cmux clear-status --key branch

# List all status entries
cmux list-status
```

### Progress Bar
```bash
# Set progress (0.0 to 1.0)
cmux set-progress 0.5

# Clear progress
cmux clear-progress
```

### Log Entries
```bash
# Add log entry (levels: info, progress, success, warning, error)
cmux log --level info "Starting build..."
cmux log --level success "Build complete"
cmux log --level error "Test failed: combat.test.ts"
cmux log --level warning "Coverage below 80%"

# List and clear logs
cmux list-log
cmux clear-log
```

### Full Sidebar State
```bash
# Dump all sidebar metadata (cwd, git branch, ports, status, progress, logs)
cmux sidebar-state
```

---

## Browser Commands

cmux includes an embedded browser with full automation capabilities. Useful for testing web games, debugging local apps, and agent-driven web tasks.

### Opening and Navigation
```bash
# Open browser in a split pane
cmux new-pane --type browser --url https://localhost:3000

# Navigate existing browser surface
cmux browser navigate <SURFACE_ID> <URL>

# Open/close tabs
cmux browser new-tab <SURFACE_ID>
cmux browser close-tab <SURFACE_ID>
```

### Waiting for Content
```bash
# Wait for page load
cmux browser wait <SURFACE_ID> --load-state complete

# Wait for a CSS selector to appear
cmux browser wait <SURFACE_ID> --selector "button.start-game"

# Wait for text to appear
cmux browser wait <SURFACE_ID> --text "Game Over"

# Wait for URL change
cmux browser wait <SURFACE_ID> --url "*/level-2*"

# Wait with JavaScript condition
cmux browser wait <SURFACE_ID> --js "document.querySelector('.score').textContent !== '0'"
```

### DOM Interaction
```bash
# Click an element by CSS selector
cmux browser click <SURFACE_ID> --selector "button.start-game"

# Fill a form field
cmux browser fill <SURFACE_ID> --selector "input[name='player']" --text "Player1"

# Check a checkbox
cmux browser check <SURFACE_ID> --selector "input[type='checkbox']"

# Dismiss a dialog
cmux browser dismiss-dialog <SURFACE_ID>
```

### Snapshot and Inspection
```bash
# Get interactive DOM snapshot (returns element references like e10, e14)
cmux browser snapshot <SURFACE_ID> --interactive

# Get accessibility tree
cmux browser accessibility-tree <SURFACE_ID>

# Get text content of an element
cmux browser get-text <SURFACE_ID> --selector ".score"

# Get an attribute value
cmux browser get-attribute <SURFACE_ID> --selector "img.hero" src

# Take a screenshot
cmux browser screenshot <SURFACE_ID>

# Get full browser state
cmux browser get-state <SURFACE_ID>
```

### Element Reference Workflow

Snapshots assign unique IDs (e.g., `e10`, `e14`) to interactive elements:
```bash
# 1. Take snapshot to discover elements
cmux browser snapshot <SURFACE_ID> --interactive
# Returns: e10 = search input, e14 = submit button, etc.

# 2. Interact using element references
cmux browser type <SURFACE_ID> 'e10' 'search term'
cmux browser click <SURFACE_ID> 'e14'

# 3. Verify changes
cmux browser snapshot-after
```

### JavaScript Execution
```bash
# Run JavaScript in the browser context
cmux browser eval <SURFACE_ID> "document.title"
cmux browser eval <SURFACE_ID> "document.querySelector('.score').textContent"
cmux browser eval <SURFACE_ID> "localStorage.getItem('saveData')"
```

### Cookies and Session
```bash
# Get cookies
cmux browser get-cookies <SURFACE_ID>

# Set cookies (restore session)
cmux browser set-cookies <SURFACE_ID> --cookies '<JSON>'
```

### Downloads
```bash
# Wait for a download to complete
cmux browser wait-for-download <SURFACE_ID>
```

**Keyboard shortcuts:**
- `Cmd+Shift+B` - Open browser surface
- `Cmd+L` - Focus address bar
- `Cmd+R` - Reload
- `Cmd+Option+I` - Developer Tools

---

## Utility Commands

| Command | Description |
|---------|-------------|
| `cmux ping` | Check if cmux is running and responsive |
| `cmux capabilities` | List available socket methods and access mode |
| `cmux identify` | Show focused window/workspace/pane/surface context |

---

## Unix Socket API

For advanced automation, send JSON directly to the socket.

**Socket paths:**
- Release: `~/.cmux/socket`
- Debug: `~/.cmux/debug.socket`
- Override: `CMUX_SOCKET_PATH` env var

**Request format** (newline-terminated JSON):
```json
{"method": "list-workspaces", "params": {}}
{"method": "new-split", "params": {"direction": "right"}}
{"method": "send", "params": {"surface": "surface:1", "text": "ls -la"}}
```

**Access modes:**
- `off` - Socket disabled (most secure)
- `cmuxOnly` - Only processes spawned inside cmux (default)
- `allowAll` - Any local process (set via `CMUX_SOCKET_MODE=allowAll`)

---

## Configuration

Config files are checked in this order:
1. `$CMUX_CONFIG_PATH`
2. `~/.config/cmux/config`
3. `~/.config/ghostty/config`
4. `~/.ghostty`

Key settings: `font-family`, `background`, `foreground`, `scrollback-lines`, `working-directory`

App settings (cmux > Settings): theme mode, automation mode, browser link behavior, HTTP host allowlist, custom notification command.

---

## Common Agent Workflows

### Launch a Game and Test It
```bash
# Split pane and start the game
cmux new-split right
GAME_PANE=$(cmux list-surfaces --json | jq -r '.[-1].id')
cmux send --surface $GAME_PANE "cd ~/GitProjects/my-game && npm run dev"
cmux send-key --surface $GAME_PANE enter

# Open browser to view the game
cmux new-pane --type browser --url http://localhost:3000

# Monitor game output
cmux read-screen --surface $GAME_PANE
```

### Multi-Agent Orchestration
```bash
# Create panes for parallel agents
cmux new-split right
AGENT1=$(cmux list-surfaces --json | jq -r '.[-1].id')
cmux new-split down
AGENT2=$(cmux list-surfaces --json | jq -r '.[-1].id')

# Send tasks to each agent
cmux send --surface $AGENT1 "claude 'analyze the combat system'"
cmux send-key --surface $AGENT1 enter
cmux send --surface $AGENT2 "claude 'review the rendering pipeline'"
cmux send-key --surface $AGENT2 enter

# Notify when done
cmux notify --title "Agents Launched" --body "2 agents working in parallel"

# Read results later
cmux read-screen --surface $AGENT1 --scrollback --lines 200
cmux read-screen --surface $AGENT2 --scrollback --lines 200

# Clean up
cmux close-surface --surface $AGENT1
cmux close-surface --surface $AGENT2
```

### Progress Tracking During Builds
```bash
cmux set-progress 0.0
cmux log --level info "Phase 1: Design..."
# ... work ...
cmux set-progress 0.25
cmux log --level success "Phase 1 complete"
cmux log --level info "Phase 2: Implementation..."
# ... work ...
cmux set-progress 0.75
cmux log --level success "Phase 2 complete"
cmux set-progress 1.0
cmux log --level success "All phases complete"
cmux notify --title "Build Done" --body "All phases completed successfully"
```

### Browser Testing for Web Games
```bash
# Open game in browser pane
cmux new-pane --type browser --url http://localhost:3000

BROWSER=$(cmux list-surfaces --json | jq -r '.[-1].id')

# Wait for game to load
cmux browser wait $BROWSER --load-state complete

# Interact with game UI
cmux browser click $BROWSER --selector "button.start-game"
cmux browser wait $BROWSER --text "Level 1"

# Read game state via JavaScript
cmux browser eval $BROWSER "JSON.stringify(window.__GAME_STATE__)"

# Take screenshot for visual verification
cmux browser screenshot $BROWSER
```

## Session Restore

After relaunch, cmux restores:
- Window, workspace, and pane layout
- Working directories
- Terminal scrollback (best effort)
- Browser URL and navigation history

Does NOT restore live process state. Running processes (Claude Code, npm dev, etc.) must be restarted.
