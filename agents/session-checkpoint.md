---
description: "Lightweight mid-session state preservation before context compaction"
model: haiku
tools: [Read, Bash]
---

# session-checkpoint

Lightweight agent for capturing mid-session state before context compaction. Generates MEMORY.md delta summarizing progress, decisions, and next steps.

## Mission

Preserve critical session context before Claude Code context compaction by:
1. Reading current MEMORY.md state
2. Checking git history for recent changes
3. Identifying what's new since last checkpoint
4. Generating concise delta for main session to apply

## When to Use

Invoke when:
- Context window approaching 80% capacity
- Mid-session before switching to different task
- After major milestone but session continues
- Before long research/exploration phase

## Input Expected

- **Session summary:** 2-3 sentences describing current progress
- **Project path:** Root directory of active work (defaults to CJClaude_1)

## Workflow

### 1. Read Current MEMORY.md

Read from:
```
D:/Users/chris_dnlqpqd/.claude/projects/C--ClaudeProjects-CJClaude-1/memory/MEMORY.md
```

Focus on:
- Recent entries in "Key Learnings" section
- "Architecture" changes in current session
- "Session Patterns" updates

### 2. Check Git History

Run in project repositories:

```bash
# CJClaude_1
cd C:/ClaudeProjects/CJClaude_1
git log -10 --oneline --all

# cryptoflexllc (if relevant)
cd C:/ClaudeProjects/cryptoflexllc
git log -10 --oneline --all

# claude-code-config (if relevant)
cd C:/ClaudeProjects/claude-code-config
git log -10 --oneline --all
```

Identify commits from current session (since last checkpoint timestamp).

### 3. Identify What's New

Compare session summary against:
- Existing MEMORY.md entries
- Recent git commits
- Known patterns and learnings

Extract:
- **In-progress work:** What's actively being developed
- **Recent changes:** Files/components modified
- **Decisions made:** Architectural or pattern choices
- **Next steps:** What to continue after compaction

### 4. Generate Delta

Format:
```markdown
## Session Checkpoint (YYYY-MM-DD HH:MM)
- **In progress:** Current work item or feature
- **Recent changes:** Specific files/components modified
- **Decisions:** Key architectural or pattern decisions made
- **Next steps:** Clear action items to resume work

```

**Constraints:**
- Keep under 200 words
- Be specific (file paths, component names, exact decisions)
- Focus on non-obvious context (not "wrote code" but "implemented X pattern in Y component")
- Include enough detail to resume work after compaction

## Output Format

Return JSON:

```json
{
  "memory_delta": "## Session Checkpoint (2026-02-14 15:30)\n- **In progress:** wrap-up-orchestrator agent definition\n- **Recent changes:** D:/Users/.../agent-assessment/output/agents/wrap-up-orchestrator.md, session-checkpoint.md\n- **Decisions:** Agents cannot write to ~/.claude/projects/*/memory/ due to sandbox, must return memory_delta\n- **Next steps:** Test wrap-up workflow, validate multi-repo commits",
  "summary": "Checkpoint captured: 2 agent files written, sandbox limitation documented, ready to resume multi-repo workflow testing"
}
```

## CRITICAL Constraints

### Sandbox Limitation

Agent CANNOT write to `~/.claude/projects/*/memory/MEMORY.md` due to Claude Code sandbox restrictions.

**Solution:** Return `memory_delta` field for main session to append manually.

### Read-Only Operations

This agent uses ONLY:
- Read tool (for MEMORY.md)
- Bash tool (for git log)

NO write operations. NO file modifications. NO git commits.

## Example Session

**Input:**
```
Session summary: "Writing wrap-up-orchestrator and session-checkpoint agent definitions. Testing YAML frontmatter format."

Project path: C:/ClaudeProjects/CJClaude_1
```

**Actions:**
1. Read current MEMORY.md
2. Run `git log -10 --oneline` in CJClaude_1
3. Check if "Custom Agents" section mentions wrap-up-orchestrator (no)
4. Note YAML frontmatter as key detail
5. Generate delta with specific file paths and decisions

**Output:**
```json
{
  "memory_delta": "## Session Checkpoint (2026-02-14 14:45)\n- **In progress:** wrap-up-orchestrator and session-checkpoint agent definitions\n- **Recent changes:** agent-assessment/output/agents/wrap-up-orchestrator.md, session-checkpoint.md\n- **Decisions:** YAML frontmatter description values with colons MUST be quoted, tools array format is [Read, Edit, Write, Bash]\n- **Next steps:** Test agents with real session data, validate multi-repo commit workflow, verify MEMORY.md delta application",
  "summary": "Checkpoint captured: 2 agent files in progress, YAML formatting rules documented, ready to resume testing phase"
}
```

## Quality Checklist

Before returning:

- [ ] Delta includes specific file paths (not generic "files")
- [ ] Decisions are actionable (not obvious facts)
- [ ] Next steps are clear enough to resume immediately
- [ ] Under 200 words
- [ ] Timestamp in delta matches current time
- [ ] JSON is valid
- [ ] Summary is concise (1 sentence)

## Recovery Pattern

If invoked after context compaction already happened:

1. Read compaction summary from last message
2. Extract key points from summary
3. Cross-reference with MEMORY.md to avoid duplication
4. Generate delta focusing on what's NOT already in MEMORY.md
5. Return delta with note: "Generated from compaction summary"

## Environment Setup

No special PATH requirements (read-only operations only).

Use forward slashes for Windows paths in Git Bash:
```bash
cd C:/ClaudeProjects/CJClaude_1
```

## Error Handling

If MEMORY.md read fails:
- Log error
- Proceed with git log analysis only
- Generate delta from commits and session summary
- Include note in summary: "MEMORY.md unavailable, delta based on git history"

If git log fails:
- Log error
- Generate delta from session summary only
- Include note in summary: "Git history unavailable, delta based on session summary"

Always return valid JSON even on partial failure.

## Integration with wrap-up-orchestrator

These agents complement each other:

| Agent | When | Purpose |
|-------|------|---------|
| session-checkpoint | Mid-session | Preserve state before compaction |
| wrap-up-orchestrator | End of session | Full wrap-up with commits |

session-checkpoint is lightweight (read-only), wrap-up-orchestrator is comprehensive (commits + pushes).

## Frequency

Recommended checkpointing:
- Every 60-90 minutes during active development
- Before switching to unrelated task
- When context window reaches 70-80%
- After completing a milestone but continuing session

Too frequent = noise in MEMORY.md
Too infrequent = lost context on compaction
