---
platform: portable
description: "Write a new blog post for cryptoflexllc.com: 5-agent captain pipeline with cover graphic, diagrams, voice QA, and CI-matched validation"
---

# /blog-post - Blog Post Production Pipeline

Single entry point for producing a cryptoflexllc.com blog post. Coordinates the Blog Captain (opus), which runs a specialist team: writer, voice agent, senior editor, UX agent, diagram author, and brand-graphics cover artist.

This skill is callable from ANY repo or directory. Never rely on the current working directory: resolve all paths absolutely.

## Step 0: Repo Resolution

```bash
BLOG_REPO="$HOME/GitProjects/cryptoflexllc"
[[ -d "$BLOG_REPO" ]] || BLOG_REPO="$HOME/Github_Projects/cryptoflexllc"
```

Every file operation in this pipeline uses absolute paths under `$BLOG_REPO` or `~/.claude/`. If neither repo path exists, stop and tell the user.

## Step 1: Post Inventory

```bash
bash ~/.claude/scripts/blog-inventory.sh --minimal
```

The output now includes `series`, `seriesOrder`, `coverImage`, and `featured` per post, plus a `series_summary` block with each series' post count and highest seriesOrder. Series matching is quote-normalized by the script; never grep frontmatter for series values yourself.

From the inventory, derive:
- The 3 most recently active series (for the series question below)
- The next seriesOrder for whichever series is chosen (`series_summary[].max_order + 1`)
- The 2 most recent post paths (calibration posts for the captain)

## Step 2: Voice Profile

Read `~/.claude/skills/blog-voice-profile.md` in full. Pass the complete text to the captain (subagents may not be able to read `~/.claude/skills/` themselves).

## Step 3: User Discovery

Use AskUserQuestion (one call, four questions):

1. **Destination** ("Destination"): "Production" (live after deploy, `src/content/blog/`) or "Backlog" (draft, `src/content/backlog/`, published later via the /backlog admin page).
2. **Source material** ("Material"): what the post is built from:
   - "This session": what was accomplished in the current Claude Code session
   - "Today's work": everything done today across repos (git logs since midnight)
   - "Last 24 hours": same sweep with `--since="24 hours ago"`
   - "A specific feature or topic": deep dive on a named skill, feature, incident, or subject (user supplies specifics via Other or a follow-up)
3. **Series** ("Series"): offer the 3 most recently active series from the inventory plus "None (standalone)". The user can type any other series name (including a brand-new one) via Other. When a series is chosen, use the next seriesOrder computed in Step 1; for a new series, seriesOrder is 1.
4. **Tone** ("Tone"): "Educational and friendly" (default voice), "Witty and accessible" (humor, GIFs, Info boxes for every concept; for general readers), or "Technical reference" (documentation style).

If the answers leave the topic ambiguous, ask a plain follow-up question before spawning the captain. Never guess at source material: the pipeline must not fabricate.

## Step 4: Research Recipes (pass to captain)

Repos for research, all absolute:
- `$BLOG_REPO` (the site)
- `$HOME/GitProjects/CJClaude_1`, `$HOME/GitProjects/cryptoflex-ops` (private; never linked in posts)
- `~/.claude` (claude-code-config)

By material type:
- **This session:** review the current conversation; identify the most educational moments, real commands, real errors.
- **Today's work / Last 24 hours:** parallel Explore agents (haiku) running `git log --since=... --stat` across the repos above, plus CHANGELOG/MEMORY updates.
- **Specific feature/topic:** read the actual source files, config, and history behind it. Quote real code only.

## Step 5: Spawn the Captain

Spawn ONE Task agent:
- **subagent_type:** general-purpose
- **model:** opus
- **name:** blog-captain

Pass it, in the prompt:
1. "You are the Blog Captain. Follow the instructions in ~/.claude/agents/blog-captain.md"
2. `BLOG_REPO` (resolved absolute path)
3. The inventory JSON from Step 1 and the 2 calibration post paths
4. The user's answers: destination, material, series + seriesOrder, tone
5. The full voice profile text
6. The applicable research recipes from Step 4
7. If destination is Backlog: "Write to src/content/backlog/. Commit prefix 'chore: add backlog draft'. Note the backlog runtime differences in your instructions."

The captain runs the full pipeline: research, draft, parallel review + diagram authoring, revision, cover graphic, build, and user approval. It returns a JSON report.

## Step 6: After the Captain Returns

1. Display the post details, scores, revision history, cover/diagram outputs, and any unresolved issues.
2. If the captain did not commit (approval pending), offer to commit and push. Production commits include the MDX, `public/blog/<slug>/`, and any new diagram/registry files.
3. Report the URL: `https://cryptoflexllc.com/blog/<slug>` (production) or "Draft saved to backlog; publish via the /backlog admin page."
4. Backlog publishes (user-triggered via the admin page) rename the file on the remote with 2 commits; after one, run `git pull --ff-only` in `$BLOG_REPO`.
5. Backlog drafts in a series carry the seriesOrder assigned at draft time, which goes stale as the series grows. When a draft with `series:` is about to be published, re-check the inventory and bump its `seriesOrder` to `max_order + 1` first.

## Known Gotchas

- **Diagram visual bar**: inline SVG diagrams follow the editorial diagram system, matching the cover-infographic aesthetic. Contract: `$BLOG_REPO/docs/editorial-diagram-standards.md`; primitives: `src/components/mdx/diagram-editorial.tsx`; exemplar: `ReviewPipelineDiagram` in `diagrams-security-review-round-two.tsx`. Plain outlined boxes joined by crossing diagonal lines are below the bar, and the diagram author must run the standards doc's screenshot verification loop before handing off.
- **Tailwind v4 dynamic class purging** (matters for diagram TSX): never interpolate class fragments (`bg-${accent}-600`). Use a static `as const` class map. Hit in TerminalPromo.tsx 2026-07-21.
- **MDX runtime traps** (caught by `~/.claude/scripts/validate-mdx.sh`, but know them): bare `<` before digits (`<100ms`) parses as a JSX tag and breaks at render with HTTP 200; nested double quotes inside JSX attribute values render as an error boundary with no build error; slugs are `[a-z0-9-]` only, no dots.
- **Series data**: quoting is normalized to unquoted in frontmatter (`series: Claude Code Workflow`). The inventory script is the only source of truth for seriesOrder.
