---
platform: portable
description: "Write a new blog post for cryptoflexllc.com: blog-pipeline workflow (writer, editor, voice, cover, inline images, diagrams, finalize) with CI-matched validation"
---

# /blog-post - Blog Post Production Pipeline

Single entry point for producing a cryptoflexllc.com blog post. This skill runs in the **main conversation**:
- It gathers the inputs and writes the source account.
- It calls the saved workflow `~/.claude/workflows/blog-pipeline.js`, which runs the specialist agents deterministically.
- It presents the result, then commits only after the user approves.

The workflow replaced the old blog-captain orchestrator (2026-09-27). That captain was spawned as a named teammate, so every subagent's report failed to hand back and had to be relayed manually.

Callable from ANY repo or directory. Resolve every path absolutely.

**Specialists** (registered agent types in `~/.claude/agents/`):

| Agent | Role |
|---|---|
| `blog-writer` | Drafts and revises the MDX. A PostToolUse hook runs `validate-mdx.sh` after every edit. |
| `blog-editor` | Scores, de-slop check, structural checks, and must/should/protect lists |
| `blog-voice` | Voice metrics, `validate_errors`, and post-publish profile proposals |
| `brand-graphics` | Cover infographic. Reads the draft; never edits the MDX in this pipeline. |
| `blog-inline-images` | Comparison and screenshot images from real assets |
| `blog-diagram-author` | Editorial SVG diagrams and all 3 registries |
| `blog-finalize` | Cover frontmatter, drift check, validate, content-security, build |

**Never spawn any of these with a `name`.** Agent teams are on, so a named spawn becomes a teammate whose subagents cannot hand back.

## Step 0: Repo Resolution

```bash
BLOG_REPO="$HOME/GitProjects/cryptoflexllc"
[[ -d "$BLOG_REPO" ]] || BLOG_REPO="$HOME/Github_Projects/cryptoflexllc"
```

If neither exists, stop and tell the user.

## Step 1: Post Inventory

```bash
bash ~/.claude/scripts/blog-inventory.sh --minimal
```

Each post in the output carries `series`, `seriesOrder`, `has_cover`, and `featured`. There's also a `series_summary` block (count and `max_order` per series). Series matching is quote-normalized by the script, so never grep frontmatter for series values yourself.

From the inventory, derive:
- the 3 most recently active series (for the question below)
- the next seriesOrder for the chosen series: `max_order + 1`, or 1 for a new series
- the 2 most recent post paths, which are the calibration posts

## Step 2: User Discovery

Use AskUserQuestion (one call, four questions):

1. **Destination**:
   - "Production": live after deploy, in `src/content/blog/`
   - "Backlog": a draft in `src/content/backlog/`, published later from the /backlog admin page
2. **Material**:
   - "This session"
   - "Today's work" (git logs since midnight)
   - "Last 24 hours"
   - "A specific feature or topic" (the user supplies specifics)
3. **Series**: the 3 most recently active series plus "None (standalone)". The user can name any other series through Other. If a series clearly fits the topic better than the recent ones (for example Quick Tips for a short fix), offer it in place of one of them.
4. **Tone**:
   - "Educational and friendly" (default)
   - "Witty and accessible"
   - "Technical reference"

If the topic is still ambiguous, ask a plain follow-up. Never guess at source material; the pipeline must not fabricate. If the user asked for a particular length ("short", "quick"), carry it as the `length` arg, for example `short: 900-1,400 words, 4-7 H2s, 4-6 callouts`.

## Step 3: Source Prep (main conversation)

1. Pick the slug (`[a-z0-9-]`, no dots) and a working title. Create the run dir inside the repo. It's gitignored, and keeping it inside the repo means pipeline agents don't hit permission prompts.
   ```bash
   RUN_DIR="$BLOG_REPO/content-assets/runs/<slug>"; mkdir -p "$RUN_DIR"
   ```
2. Write `$RUN_DIR/source.md`, the **only facts the pipeline may use**. Include:
   - what happened, in order
   - the real commands and their real output (verbatim)
   - errors and dead ends
   - numbers with their source
   - quotes from the user (verbatim)
   - absolute paths of any real image assets (screenshots, before and after files)

   How to gather it depends on the material:
   - **This session:** only the main conversation can see it, so write it yourself from the conversation.
   - **Today's work / Last 24 hours:** one unnamed Explore (haiku) agent runs `git log --since=... --stat` across `$BLOG_REPO`, `~/.claude`, `$HOME/GitProjects/CJClaude_1`, and `$HOME/GitProjects/cryptoflex-ops`. The last two are private: never link them. Summarize the output into `source.md`.
   - **Specific feature or topic:** read the actual source files, config, and history; quote real code only.
3. Voice inputs:
   ```bash
   cp ~/.claude/skills/blog-voice-profile.md "$RUN_DIR/voice-profile.md"
   awk '/^## AI-Slop Tells/{p=1} /^## Metric Baselines/{p=0} p' ~/.claude/skills/blog-voice-profile.md > "$RUN_DIR/deslop.md"
   { echo '{"calibration": ['; bash ~/.claude/scripts/blog-voice-diff.sh "<calibration-1>"; echo ','; bash ~/.claude/scripts/blog-voice-diff.sh "<calibration-2>"; echo ']}'; } > "$RUN_DIR/baseline.json"
   ```
4. Set `inlineImages: true` only when `source.md` lists real image assets.

## Step 4: Run the Workflow

```
Workflow({ name: "blog-pipeline", args: {
  repo: "<BLOG_REPO>", slug: "<slug>", workingTitle: "<title>",
  destination: "backlog" | "production", series: "<name>" | null, seriesOrder: <n> | null,
  tone: "<tone>", date: "<YYYY-MM-DD, today>", runDir: "<RUN_DIR>",
  calibration: ["<abs path 1>", "<abs path 2>"], inlineImages: <bool>, diagrams: "auto",
  length: "<optional>"
}})
```

This skill's instructions are the opt-in for running this one saved workflow. The workflow runs in the background and returns a run ID immediately. **End the turn and wait for the completion notification.** Don't read the draft or the cover before it arrives. The user can watch progress with `/workflows`.

**Stages:**
- **Draft:** `blog-writer` writes the MDX; `blog-inline-images` runs alongside.
- **Assets:** once the draft exists, `brand-graphics` (cover) and `blog-diagram-author` (only when the writer flagged diagram ideas) run in the background.
- **Review:** `blog-editor` and `blog-voice` in parallel.
- **Revise:** fixes are routed as follows, for at most 2 cycles:
  - must-fix items always
  - all should-fix items when there are 3 or more, or when a pass is already running
  - placements for images and diagrams
- **Finalize:** `blog-finalize` inserts the cover frontmatter, checks cover drift (brand-graphics patches it if needed), then runs validate-mdx, the content-security test, and `npm run build`.

If the run dies partway, relaunch with `resumeFromRunId`; completed stages return from cache.

## Step 5: Present, Approve, Commit

If `status` is `failed` (bad args, or the draft never landed), report `stage` and `error`, fix the cause, and relaunch. Use `resumeFromRunId` when the args are unchanged.

1. Show:
   - `status` (`ready` or `needs-attention`)
   - title, word count, and editor and voice scores
   - revisions: applied and declined items, with reasons
   - `unresolved` items and `stage_errors`
   - `final` results

   Read the cover PNG to show it, and describe the diagrams and inline images.
2. If `final.errors` is not empty (for example a build failure), fix it with the user present, then re-run `validate-mdx.sh` and `npm run build`.
3. Ask for approval, including which branch to push to. The user usually pushes site work straight to `main`.
   ```bash
   cd "$BLOG_REPO" && git fetch -q origin && git add <post>.mdx public/blog/<slug>/ \
     src/components/mdx/diagrams-<slug>.tsx src/components/mdx/index.ts "src/app/blog/[slug]/page.tsx" "src/app/backlog/[slug]/page.tsx"  # diagram files only if created
   git diff --quiet HEAD -- docs/cover-graphics-standards.md || git add -p docs/cover-graphics-standards.md  # stage ONLY this post's register row if the file has other pending edits
   git commit -m "feat: add blog post '<title>'"      # backlog: chore: add backlog draft '<title>'
   git pull --rebase -q origin <branch> && git push origin <branch>
   ```
   `git add -p` is interactive. If you can't use it, check `git diff docs/cover-graphics-standards.md` first. When the only change is this post's register row, `git add` the file; otherwise ask the user.
   `content-assets/` (the run dir and cover HTML) is gitignored and stays local.
4. Report the URL:
   - Production: `https://cryptoflexllc.com/blog/<slug>`
   - Backlog: "Draft saved to backlog; publish via the /backlog admin page."

## Step 6: Voice Profile Update (production posts only)

Spawn one unnamed background `blog-voice` agent in post-publish mode, giving it the published path and the readable profile copy at `$RUN_DIR/voice-profile.md`. Subagents may not be able to read `~/.claude/skills/`, and main edits the canonical file. Show its `proposed_changes` to the user, and apply only the approved ones yourself. The changes are additive, timestamped, and gradual.

## Backlog Notes

- A backlog publish (from the admin page) renames the file on the remote with 2 commits. Afterwards, run `git pull --ff-only` in `$BLOG_REPO`.
- A backlog draft in a series keeps the seriesOrder it got at draft time, which goes stale. Before publishing, re-check the inventory and bump `seriesOrder` to `max_order + 1`.
- Backlog pages mirror the production layout (editorial header, cover hero, heading anchors, TOC, series nav). Backlog pages don't have CodePlayground, comments, related posts, or engagement widgets. The publish API rewrites `date` to the publish day.

## Known Gotchas

- **Agent definitions are snapshots.** A brand-new agent file (`name:` frontmatter) may take a while to register mid-session; until it does, the workflow fails fast with "agent type not found". Once registered, the definition is frozen for the session, so edits to an agent file take effect in the next session. Test agent edits in a fresh session.
- **Cover uniqueness bar:** every cover is a bespoke composition sharing branding only. The contract and composition register are in `$BLOG_REPO/docs/cover-graphics-standards.md`.
- **Diagram visual bar:** diagrams use the editorial diagram system. The contract is `$BLOG_REPO/docs/editorial-diagram-standards.md`, and the exemplar is `ReviewPipelineDiagram`. Never Mermaid, and never crossing diagonal lines.
- **Tailwind v4 dynamic class purging:** never interpolate class fragments (`bg-${accent}-600`); use static `as const` maps.
- **MDX runtime traps:**
  - a bare `<` before digits (`<100ms`) breaks at render
  - nested double quotes inside JSX attribute values do too
  - slugs are `[a-z0-9-]` only
  - `validate-mdx.sh` catches these, and the writer's hook runs it after every edit
- **Series data:** series values are unquoted in frontmatter. The inventory script is the only source of truth for seriesOrder.
