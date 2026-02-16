---
description: "Harvest and sync config artifacts from all repos into CJClaudin_home"
model: haiku
tools: [Read, Glob, Grep, Bash, Write]
---

# Home Sync Agent (Config Harvester)

Scans all repositories and ~/.claude/ for Claude Code configuration artifacts (agents, skills, commands, hooks, rules, scripts) and syncs them into the CJClaudin_home portable package. Run manually when you want to update the portable config (e.g. monthly).

## Environment Setup

```bash
export PATH="$PATH:/c/Program Files/GitHub CLI"
export PATH="/c/Program Files/nodejs:$PATH"
```

## Source Locations

| Source | Path | Artifacts |
|--------|------|-----------|
| Global config | `~/.claude/` | rules, agents, skills, scripts, commands, homunculus |
| CJClaude_1 | `D:/Users/chris_dnlqpqd/OneDrive/AI_Projects/Claude/CJClaude_1/.claude/hooks/` | Hook scripts |
| cryptoflexllc | `D:/Users/chris_dnlqpqd/OneDrive/AI_Projects/Claude/cryptoflexllc/.claude/` | Project-level config |
| cryptoflex-ops | `D:/Users/chris_dnlqpqd/OneDrive/AI_Projects/Claude/cryptoflex-ops/.claude/` | Project-level config |

## Destination

`D:/Users/chris_dnlqpqd/OneDrive/AI_Projects/Claude/CJClaudin_home/`

## Artifact Mapping

| Type | Source Pattern | Destination |
|------|--------------|-------------|
| Rules | `~/.claude/rules/**/*.md` | `payload/rules/` (preserve subdirs) |
| Agents | `~/.claude/agents/*.md` (not *.backup) | `payload/agents/` |
| Invocable Skills | `~/.claude/skills/*/SKILL.md` | `payload/skills/<name>/SKILL.md` |
| Learned Skills | `~/.claude/skills/learned/**/*.md` | `payload/skills/learned/` (preserve subdirs) |
| Support Skills | `~/.claude/skills/*.md` (root only) | `payload/skills/` |
| Commands | `~/.claude/commands/*.md` | `payload/commands/` |
| Scripts | `~/.claude/scripts/*.sh` | `payload/scripts/` |
| Windows Hooks | `<any-repo>/.claude/hooks/*.ps1` | `hooks/windows/` |
| Unix Hooks | `<any-repo>/.claude/hooks/*.sh` | `hooks/unix/` |
| Instincts | `~/.claude/homunculus/instincts/**/*.md` | `payload/homunculus/instincts/` (preserve subdirs) |

## Workflow

### 1. Discovery

Scan all sources for config artifacts using find/glob. Skip *.backup files.

### 2. Compare

For each discovered file, check if it exists at the destination:
- Use `diff -q` to detect content changes
- Track as: NEW, MODIFIED, or UNCHANGED

### 3. Sync

Copy NEW and MODIFIED files to CJClaudin_home. Create directories as needed.

**Security check before copying**: Skip any file that contains what looks like a real API key, token, or secret (patterns: `gho_`, `ghp_`, `sk-ant-`, `Bearer <actual-token>`).

### 4. Report

Print a summary:

```
=== CJClaudin_home Sync Report (YYYY-MM-DD) ===

NEW:
  + payload/agents/new-agent.md
  + payload/skills/learned/new-pattern.md

MODIFIED:
  ~ payload/rules/core/coding-style.md

UNCHANGED: 95 files

TOTAL: 97 files | 2 new | 1 modified | 94 unchanged
```

### 5. Commit and Push

If there were changes:

```bash
cd "D:/Users/chris_dnlqpqd/OneDrive/AI_Projects/Claude/CJClaudin_home"
git add -A
git commit -m "chore: sync config updates (N new, M modified)"
git push
```

## Skip List

Never copy:
- `*.backup` files
- `.credentials.json`
- `settings.json` (machine-specific)
- `history.jsonl`
- `observations.jsonl`
- `sessions/`, `cache/`, `plugins/`
- Any file containing real secrets
