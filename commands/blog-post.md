---
platform: portable
description: "Write a new blog post for cryptoflexllc.com using the multi-agent production team"
---

# /blog-post - Multi-Agent Blog Post Production

This command is now handled by the `/blog-post` skill (`~/.claude/skills/blog-post/skill.md`), which orchestrates a five-agent production team.

## Architecture

```
Skill (discovery + user questions)
  -> Blog Captain (opus, orchestrator)
    -> Blog Writer (sonnet, drafts MDX)
    -> Blog Voice (sonnet, voice consistency)
    -> Blog Editor (sonnet, quality review)
    -> Blog UX (haiku, build + structure)
```

## Agent Files

| Agent | File | Purpose |
|-------|------|---------|
| Captain | `~/.claude/agents/blog-captain.md` | Orchestrates 6-phase pipeline, triages feedback, manages revisions |
| Writer | `~/.claude/agents/blog-writer.md` | Drafts and revises MDX posts with embedded style guide |
| Voice | `~/.claude/agents/blog-voice.md` | Maintains voice profile, produces briefs, reviews consistency |
| Editor | `~/.claude/agents/blog-editor.md` | Read-only reviewer: hooks, pacing, entertainment, accuracy |
| UX | `~/.claude/agents/blog-ux.md` | Build verification, structural analysis |

## Pipeline Phases

1. **Research**: Parallel Explore agents + voice agent produces voice brief
2. **Draft**: Writer agent creates full MDX post
3. **Review**: Editor + Voice + UX + validate-mdx.sh run in parallel
4. **Revision**: Captain triages feedback, writer revises (max 2 cycles)
5. **Publish**: Final build, user approval, commit, voice profile update

## Supporting Files

| File | Purpose |
|------|---------|
| `~/.claude/skills/blog-voice-profile.md` | Living voice profile document |
| `~/.claude/scripts/validate-mdx.sh` | Automated MDX validation (frontmatter, em dashes, GIFs, headings, callouts) |
| `~/.claude/scripts/blog-voice-diff.sh` | Voice metrics extraction (paragraph length, pronoun density, etc.) |
| `~/.claude/scripts/blog-inventory.sh` | Post inventory and metadata |

## Important Notes

- **Never fabricate.** Only write about things that actually happened.
- **Code examples must be real.** Read actual files and quote from them.
- **Blog directory:** `src/content/blog/` (production) or `src/content/backlog/` (drafts) in the cryptoflexllc repo.
- NEVER link to private GitHub repositories. Only safe to link: `chris2ao/cryptoflexllc`, `chris2ao/claude-code-config`.
