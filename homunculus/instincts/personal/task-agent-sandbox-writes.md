---
id: task-agent-sandbox-writes
trigger: "when spawning Task agents that need to create files in restricted directories"
confidence: 0.5
domain: "claude-code"
source: "session-archive-ingestion"
created: "2026-03-14"
---

# Return File Drafts from Child Agents to Parent for Writing

## Action
When a child agent (spawned via the Agent/Task tool) needs to create files in restricted directories like `~/.claude/homunculus/instincts/personal/`, have it return the structured content (filename, content) as its output. The parent session then writes the files, since child agents have sandbox restrictions on file writes to certain paths.

## Pattern
1. In the agent prompt, ask it to "return the file content as structured output" rather than "write the file"
2. Agent returns: filename, content, and any metadata
3. Parent session receives the output and uses Write tool to create the files
4. This also applies to any path outside the project working directory

## Evidence
- 2026-02-15: Instinct file creation failed when delegated to child agents. The agent had full read access but restricted write permissions to `~/.claude/homunculus/instincts/personal/`. Returning drafts to the parent resolved the issue.
