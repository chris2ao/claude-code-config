# MCP Server Configuration

This document covers the 7 MCP servers configured for Claude Code. Each server extends Claude's capabilities with specialized tools.

## Server Overview

| Server | Package/Source | Purpose | Required? |
|--------|---------------|---------|-----------|
| memory | `@modelcontextprotocol/server-memory` | Knowledge graph for entity relationships | Required |
| context7 | `@upstash/context7-mcp` | Library documentation lookup | Optional |
| sequential-thinking | `@modelcontextprotocol/server-sequential-thinking` | Structured reasoning chains | Optional |
| github | `@modelcontextprotocol/server-github` | GitHub API (issues, PRs, repos) | Required |
| project-tools | Custom (local Node.js) | Repo status, blog tools, session artifacts | Required |
| vector-memory | `mcp-memory-service` (Python) | Vector + keyword search for long-term memory | Required |
| obsidian | Obsidian MCP plugin binary | Read/write Obsidian vault files | Optional |

## Installation

### 1. memory (Knowledge Graph)

Stores entities and relationships. Used for modeling service dependencies, data flows, and team structures.

```json
"memory": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-memory"],
  "env": {}
}
```

No additional setup needed. Data is stored locally.

### 2. context7 (Library Docs)

Fetches up-to-date documentation for libraries and frameworks directly into context.

```json
"context7": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@upstash/context7-mcp@latest"],
  "env": {}
}
```

No API key required. Pulls from the Context7 public index.

### 3. sequential-thinking

Provides a structured reasoning tool for complex multi-step problems.

```json
"sequential-thinking": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"],
  "env": {}
}
```

No API key required.

### 4. github

Full GitHub API access: issues, pull requests, repositories, code search, and more.

```json
"github": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_TOKEN_HERE"
  }
}
```

**Setup:** Create a GitHub Personal Access Token at https://github.com/settings/tokens with `repo`, `read:org`, and `read:user` scopes.

### 5. project-tools (Custom)

Custom MCP server providing project-specific tools: multi-repo git status, blog post inventory, style guide retrieval, blog post validation, and session artifact summary.

```json
"project-tools": {
  "type": "stdio",
  "command": "node",
  "args": ["YOUR_CONFIG_REPO_PATH/mcp-servers/project-tools/index.js"],
  "env": {
    "PROJECT_ROOT": "YOUR_PROJECTS_DIR",
    "CLAUDE_CONFIG": "YOUR_CLAUDE_HOME"
  }
}
```

**Setup:**
1. Install dependencies: `cd mcp-servers/project-tools && npm install`
2. Update the `args` path to point to your local copy of `index.js`
3. Set `PROJECT_ROOT` to the directory containing your git repositories
4. Set `CLAUDE_CONFIG` to your `~/.claude` directory

**Tools provided:**
- `repo_status`: Cached git status across all project repos (30s TTL)
- `blog_posts`: Blog post inventory with frontmatter metadata (invalidated by file watcher)
- `style_guide`: Blog style guide and MDX reference (5 min TTL)
- `validate_blog_post`: Validates blog posts against style rules (em-dashes, frontmatter, word count, alt text, code blocks)
- `session_artifacts`: Counts and summarizes transcripts, todos, activity logs

### 6. vector-memory (Python)

Hybrid vector + keyword search for long-term memory storage. Uses Ollama for local embeddings and sqlite-vec for storage.

```json
"vector-memory": {
  "type": "stdio",
  "command": "YOUR_PYTHON_PATH",
  "args": ["-m", "mcp_memory_service.server"],
  "env": {
    "MCP_MEMORY_STORAGE_BACKEND": "sqlite_vec"
  }
}
```

**Setup:**
1. Install Ollama: https://ollama.com
2. Pull the embedding model: `ollama pull nomic-embed-text`
3. Install the Python package: `pip install mcp-memory-service`
4. Set `command` to your Python 3.11+ path (e.g., `/opt/homebrew/bin/python3.11` on macOS with Homebrew)

**Tools provided:**
- `memory_store`: Save a memory with tags
- `memory_search`: Hybrid vector + keyword search
- `memory_list`: List all stored memories
- `memory_delete`: Delete a specific memory
- `memory_update`: Update an existing memory
- `memory_stats`: Storage statistics
- `memory_health`: System health check
- `memory_quality`: Memory quality metrics
- `memory_graph`: Relationship graph between memories
- `memory_cleanup`: Remove old or low-quality memories
- `memory_ingest`: Bulk import memories

### 7. obsidian

Read and write files in an Obsidian vault. Requires the Obsidian MCP Tools community plugin.

```json
"obsidian": {
  "type": "stdio",
  "command": "YOUR_OBSIDIAN_MCP_BINARY_PATH",
  "args": [],
  "env": {
    "OBSIDIAN_API_KEY": "YOUR_OBSIDIAN_API_KEY_HERE",
    "OBSIDIAN_USE_HTTP": "true"
  }
}
```

**Setup:**
1. Install the "MCP Tools" community plugin in Obsidian
2. Enable it and copy the API key from the plugin settings
3. Set `command` to the plugin's `mcp-server` binary path
4. Set `OBSIDIAN_API_KEY` to the key from step 2

## Full Configuration Template

See `templates/claude.json.template` for a complete configuration example with all servers. Copy it to `~/.claude.json` and fill in your paths and tokens.

## Notes

- All `npx`-based servers auto-install on first run (the `-y` flag accepts prompts automatically)
- The `project-tools` server requires `npm install` in its directory before first use
- The `vector-memory` server requires Ollama running locally for embeddings
- On Windows, wrap `npx` calls with `cmd /c npx` to avoid MSYS2 path mangling (see `rules/operations/windows-platform.md`)
