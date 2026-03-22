# Troubleshooting

This document covers common issues and their solutions for CJClaudin_Mac on macOS.

## Table of Contents

1. [MCP Servers Not Connecting](#mcp-servers-not-connecting)
2. [Hooks Not Firing](#hooks-not-firing)
3. [project-tools MCP Server Issues](#project-tools-mcp-server-issues)
4. [Context Window Exhaustion](#context-window-exhaustion)
5. [Plugin Not Loading](#plugin-not-loading)
6. [Claude Code Freezing](#claude-code-freezing)
7. [HEREDOC Permission Pollution](#heredoc-permission-pollution)
8. [Homebrew Tool Not Found](#homebrew-tool-not-found)
9. [Spotlight Indexing Performance](#spotlight-indexing-performance)
10. [Shallow Fetch + Force Push Failures](#shallow-fetch-force-push-failures)

## MCP Servers Not Connecting

### Symptom
MCP servers configured in your settings don't appear when Claude Code starts. Tools from MCP servers (like GitHub operations, Context7 docs) are unavailable.

### Root Cause
**Wrong config location**. Claude Code reads MCP server configuration from `~/.claude.json`, NOT `~/.claude/mcp-servers.json` or any other location.

### Fix

1. **Check your current config location**:
   ```bash
   ls -la ~/.claude*.json
   ```

2. **Verify the config structure**:
   ```json
   {
     "mcpServers": {
       "github": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-github"],
         "env": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_..."
         }
       }
     }
   }
   ```

3. **Restart Claude Code** to reload the configuration.

### Verification
Run a simple test to confirm MCP tools are available:
- For GitHub: try `gh pr list` via Bash
- For Context7: search for documentation on a library

## Hooks Not Firing

### Symptom
Per-project hooks defined in `.claude/settings.local.json` don't execute when expected.

### Fix

1. **Validate settings JSON**:
   ```bash
   python3 -m json.tool .claude/settings.local.json
   ```

2. **Check hook script permissions**:
   ```bash
   ls -la .claude/hooks/
   chmod +x .claude/hooks/*.sh
   ```

3. **Add debug logging**:
   ```bash
   #!/usr/bin/env bash
   echo "[$(date)] Hook fired" >> /tmp/hook-debug.log
   INPUT=$(cat)
   echo "$INPUT" >> /tmp/hook-debug.log
   ```

## project-tools MCP Server Issues

### Symptom
The project-tools MCP server fails to start or tools return errors.

### Fix

1. **Check dependencies are installed**:
   ```bash
   cd ~/GitProjects/CJClaudin_Mac/mcp-servers/project-tools
   npm install
   ```

2. **Test the server directly**:
   ```bash
   node ~/GitProjects/CJClaudin_Mac/mcp-servers/project-tools/index.js
   ```
   It should start without errors and wait for stdin input.

3. **Verify registration in ~/.claude.json**:
   ```json
   "project-tools": {
     "type": "stdio",
     "command": "node",
     "args": ["/Users/chris2ao/GitProjects/CJClaudin_Mac/mcp-servers/project-tools/index.js"],
     "env": {
       "PROJECT_ROOT": "/Users/chris2ao/GitProjects",
       "CLAUDE_CONFIG": "/Users/chris2ao/.claude"
     }
   }
   ```

4. **Check that repo directories exist**:
   ```bash
   ls -d ~/GitProjects/CJClaude_1 ~/GitProjects/cryptoflexllc ~/GitProjects/cryptoflex-ops
   ```

## Context Window Exhaustion

### Symptom
Claude Code slows down, responses become less accurate, or you get warnings about approaching context limits.

### Fix

#### Proactive Monitoring
```bash
bash ~/.claude/scripts/context-health.sh
```

#### Trigger Compaction
When reaching 80%, preserve critical context to MEMORY.md, then start a new session or trigger compaction.

#### Session Strategy
For large projects, break work into focused sessions:
1. **Research session**: Explore codebase, identify files
2. **Implementation session**: Make changes (start fresh)
3. **Review session**: Run tests, review code (start fresh)

## Plugin Not Loading

### Symptom
Plugins like `everything-claude-code` don't appear. Agent types fail.

### Fix

1. **Locate your Claude Code settings**:
   - macOS: `~/Library/Application Support/Code/User/settings.json`

2. **Install the plugin**:
   ```bash
   code --install-extension affaan-m.everything-claude-code
   ```

3. **Reload VS Code window**: `Cmd+Shift+P` > "Reload Window"

## Claude Code Freezing

### Symptom
Claude Code hangs indefinitely during interactive prompts or long-running operations.

### Fix

1. **Send interrupt**: Press `Ctrl+C`

2. **Kill the process**:
   ```bash
   ps aux | grep claude
   kill -9 <process-id>
   ```

3. **Check for zombie MCP processes**:
   ```bash
   ps aux | grep -E 'node|npx'
   pkill -f 'npx.*mcp'
   ```

4. **Clear git locks**:
   ```bash
   rm -f .git/index.lock
   ```

## HEREDOC Permission Pollution

### Symptom
After using HEREDOC for git commit messages, auto-approved permissions suddenly include unexpected tools.

### Fix
Avoid parentheses in HEREDOC commit message bodies, or use file-based commits:

```bash
cat > /tmp/commit-msg.txt <<'EOF'
feat: add feature

Description of the feature with (parenthetical notes).

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF

git commit -F /tmp/commit-msg.txt
rm /tmp/commit-msg.txt
```

## Homebrew Tool Not Found

### Symptom
Commands like `node`, `npm`, `gh`, or `jq` fail with "command not found" even though they're installed via Homebrew.

### Root Cause
Shell profile hasn't loaded Homebrew's PATH. Apple Silicon Macs use `/opt/homebrew/bin/` which isn't on the default system PATH.

### Fix

1. **Check Homebrew is installed**:
   ```bash
   /opt/homebrew/bin/brew --version
   ```

2. **Add to your shell profile** (`~/.zshrc`):
   ```bash
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

3. **Reload your shell**:
   ```bash
   source ~/.zshrc
   ```

4. **Verify**:
   ```bash
   which node npm gh
   ```

## Spotlight Indexing Performance

### Symptom
Disk I/O spikes during development. Build processes slow down unexpectedly. `node_modules` or `.next` directories cause Spotlight to consume resources.

### Fix

1. **Exclude development directories from Spotlight**:
   - System Settings > Siri & Spotlight > Spotlight Privacy
   - Add `~/GitProjects` to the exclusion list

2. **Or use terminal**:
   ```bash
   sudo mdutil -i off ~/GitProjects
   ```

3. **For individual projects**, add `.metadata_never_index` file:
   ```bash
   touch ~/GitProjects/cryptoflexllc/node_modules/.metadata_never_index
   ```

## Shallow Fetch + Force Push Failures

### Symptom
After cloning a repo with `--depth=1`, force-pushing fails or causes history loss.

### Fix

1. **Unshallow the repo**:
   ```bash
   git fetch --unshallow
   ```

2. **Never force-push shallow clones**. Only use `--depth=1` for read-only CI builds.

3. **Check if shallow**:
   ```bash
   git rev-parse --is-shallow-repository
   ```

## Getting More Help

If you encounter issues not covered here:

1. **Check the learned skills**: `~/.claude/skills/learned/` contains patterns extracted from past sessions
2. **Search session transcripts**: `~/.claude/projects/` may have similar issues solved before
3. **Check Claude Code logs**: `~/.claude/logs/` for error messages
4. **Ask the skill-extractor agent**: Spawn the agent and ask it to search for similar patterns
