# Orchestrator Rebuild: hotfix, then a Workflow-based /blog-post, then the rest

## Context

The favicon Quick Tips post (2026-09-27) took 46 minutes of captain time and needed about five manual relays from the main session.

**Root cause** (verified in the transcripts and the docs):
- `~/.claude/settings.json` sets `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. With teams on, a named spawn from the main conversation becomes an in-process teammate, and `/blog-post` spawns `name: blog-captain`.
- Every subagent the teammate spawned failed `SubagentHandback` ("the agent that spawned you is no longer running"), retried it 4-5 times, and delivered its report to the main session instead. That's about 12 minutes lost.
- Unnamed subagents can nest 3 deep and wait for their children, so un-naming the spawns alone fixes the handback bug everywhere.

**Design waste on top of that:**
- The 11-minute cover ran only after revision.
- Four agents each re-read the 21 KB voice profile and two calibration posts.
- The pre-draft voice agent did what `blog-voice-diff.sh` does in seconds.
- The UX agent's build duplicates the final build.
- A redundant fact-check agent ran.

**Registration gap:** 37 of 38 files in `~/.claude/agents/` lack `name:`, so they aren't registered subagent types. Their `model`, `tools`, and `effort` are silently ignored, and every spawn is `general-purpose` + "Follow the instructions in …".

**Decisions (user):** keep agent teams on and stop naming spawns. Rebuild all five affected orchestrators. Blog upgrades: a writer self-check hook and an inline-image agent.

**Adjusted by the research:**
- multi-repo-orchestrator is dead code (nothing invokes it), so retire it instead of rebuilding it.
- /refine moves into main instead of becoming a workflow. Its captain's AskUserQuestion loop can't work in a subagent anyway.
- game-dev and ui-ux share one generic workflow.

**Target:** no handback failures, a deterministic and resumable blog pipeline, and a blog critical path of about 15-20 min (to be measured).

## Phase 0: Hotfix (minutes, fixes the handback bug for all pipelines)

Remove `name:` from every Agent spawn instruction:
- `skills/blog-post/skill.md:70`
- `skills/game-dev/SKILL.md:65`
- `skills/ui-ux/SKILL.md:78`
- `commands/refine.md:42`
- `skills/sync/SKILL.md:53,75`
- `skills/wrap-up/SKILL.md:25`
- `commands/evolve.md:75`
- `skills/brand-graphics/SKILL.md:33`
- `skills/notebooklm-content/SKILL.md:~99`
- `skills/homenet-document/SKILL.md:78`. Flag this one to the user: its `network-architect` agent file doesn't exist, so the skill is already broken.

Also add a gotcha to `skills/multi-agent-orchestration/SKILL.md`: with agent teams on, a named spawn is a teammate and its subagents can't hand back. Never name orchestrator spawns, and use saved Workflows for multi-stage pipelines.

## Phase 1: Infrastructure + smoke test

- **Tracking:**
  - Add `!workflows/`, `!workflows/*.js`, and `!hooks/*.sh` to both `~/.claude/.gitignore` and `~/GitProjects/claude-code-config/.gitignore` (both start with `*`).
  - In `scripts/sync-survey.sh:22`, add `workflows` (and `hooks`) to `SYNC_DIRS`, and `*.js` to the `find` at about line 91.
- **Permissions** (`settings.json`):
  - `Workflow(blog-pipeline)` and `Workflow(team-pipeline)`.
  - `additionalDirectories` for `~/GitProjects/cryptoflexllc`.
  - Bash allow rules for `validate-mdx.sh`, `blog-voice-diff.sh`, `npm run build`, `npx vitest run`, `npx tsc --noEmit`, `sips`, the Chrome binary, and `python3`.
- **Keep `platform: portable`** on every agent file. `sync-survey.sh:28-45` and `sync-orchestrator.md` route by it, and Claude Code ignores unknown keys.
- **Don't rename `skill.md` to `SKILL.md`.** `core.ignorecase=true` plus the sync `git rm` can delete the file, and it loads fine today.
- **Smoke-test workflow** (throwaway inline script) with one registered test agent. In a new session, confirm:
  - `agentType` resolves
  - `schema` works alongside a `tools` allowlist
  - `omitClaudeMd` drops `~/.claude/rules`
  - a `.catch()`ed floating `agent()` promise settles cleanly
  - an agent-frontmatter `PostToolUse` hook fires under a Workflow `agentType` (look for the hook entry in the agent transcript)
  - nothing pauses for permissions
  - main → unnamed general-purpose → Explore nesting shows no SubagentHandback errors while teams are on

## Phase 2: /blog-post → `~/.claude/workflows/blog-pipeline.js`

### Agent files (`~/.claude/agents/`)

Add `name:` to each. Use narrow descriptions ("Used by blog-pipeline only") so they aren't auto-delegated. Set `tools` without `Agent`, set `effort`, and omit `maxTurns` or set it to 100 or more, because hitting it kills the StructuredOutput. Use `omitClaudeMd: true` on blog agents only and restate what they need: no em dashes, and one canonical public-repo list, reconciled across `rules/content/blog-content.md`, `blog-writer.md:185`, and `validate-mdx.sh:207-212`.

| File | Change |
|---|---|
| `blog-writer.md` | `tools: [Read, Write, Edit, Grep, Glob]`, `effort: high`. Picks and returns `schemaType`. Returns `diagram_ideas[]`. Revision mode returns `applied[]` and `declined[{item, why}]`. Add a frontmatter `hooks.PostToolUse` (matcher `Write\|Edit`, timeout 60 seconds) that runs `~/.claude/hooks/blog-writer-validate.sh`. Absorb from the captain: markdown image syntax only (never raw `<img>`), no manual series-nav footer, and the backlog runtime differences. |
| `blog-editor.md` | Registered, read-only. Walks `deslop.md` explicitly and returns must, should, and protect lists. Absorbs the `blog-ux.md` structural checks that `validate-mdx` lacks: H1 in body, first content is prose, orphan headings, GIF placement, callout clusters and deserts, nested callouts, badges in headings, series name exists. |
| `blog-voice.md` | Drop pre-draft mode and remove `Write`. Main applies profile changes after user approval (this preserves the old "captain approves" gate). Post-draft mode runs `blog-voice-diff.sh` and `validate-mdx.sh`. A metric outside the profile's P10-P90 range is must-fix. Returns `validate_errors[]`. |
| `brand-graphics.md` | Registered. New inputs `Source: mdx\|brief` and `Frontmatter: edit\|skip`, so the standalone `/brand-graphics` still defaults to edit. Add patch mode (edit `cover.html` for drift, re-render, rerun the verification loop). Absorb the gradient-clip-text pitfall, the "compare against the 2-3 most recent covers; 2x2 grid retired" rule, and "NotebookLM only on explicit request". |
| `blog-inline-images.md` | **New.** Makes PNGs only from real assets listed in `source.md` into `public/blog/<slug>/`, never `infographic.png`, using `python3` + Pillow. Never edits the MDX. Returns `{images:[{path, alt, section}]}`. |
| `blog-diagram-author.md` | **New.** Carries the captain's Phase 3 diagram instructions verbatim: reuse first and restyle older diagrams, the editorial standards, all 3 registries, the screenshot loop, and deleting the gallery route plus stopping the dev server before returning. |
| `blog-finalize.md` | **New.** Haiku, low effort, `[Read, Edit, Bash, Grep, Glob]`, `omitClaudeMd`. Inserts the cover frontmatter, detects cover drift, and runs `sips`, the register row check, `validate-mdx`, the content-security vitest, and `npm run build`. |
| `blog-captain.md`, `blog-ux.md` | Delete once their rules have landed in the files above. |

**Hook script** `~/.claude/hooks/blog-writer-validate.sh`:
- Reads `.tool_input.file_path` with jq and matches `*/src/content/blog/*.mdx|*/src/content/backlog/*.mdx`. Brace globs don't expand in `case`.
- Runs `validate-mdx.sh`. It always exits 0, so parse `.summary.overall`.
- Exits 2 with the `.errors[]` on stderr only when the result is `FAIL`. Warnings would loop.
- It's advisory. The deterministic check is the voice agent's `validate_errors` routed to must-fix.
- If the Phase 1 probe shows frontmatter hooks don't fire under Workflow, move it to a `settings.json` PostToolUse hook filtered on `.agent_type == "blog-writer"`.

### Skill flow (`skills/blog-post/skill.md`, main conversation)
0-2. Repo resolution, `blog-inventory.sh --minimal`, and the same 4 discovery questions. Unchanged.
3. **Source prep:**
   - Create a run dir at `$BLOG_REPO/content-assets/runs/<slug>/` (gitignored and inside the repo, so there are no permission pauses).
   - Write `source.md` with real facts, commands, output, errors, and asset paths. For "This session" main writes it; for git-based material, run one unnamed Explore (haiku) sweep.
   - Copy `voice-profile.md`, extract `deslop.md` (profile lines ~124-170), and write `baseline.json` from `blog-voice-diff.sh` on the 2 calibration posts.
   - Choose the slug and a working title. Set `inlineImages` only if `source.md` lists real assets.
4. Call `Workflow({name:'blog-pipeline', args:{repo, slug, workingTitle, destination, series, seriesOrder, tone, date, runDir, calibration[], inlineImages, diagrams:'auto'}})`. It runs in the background, so **end the turn and wait for the completion notification.**
5. On completion:
   - Present the status, scores, revisions, and unresolved items. Read the cover PNG to show it.
   - Fix any build failures with the user present.
   - Ask for approval, then commit and push. Include the MDX, `public/blog/<slug>/`, diagram and registry files, and `docs/cover-graphics-standards.md`. The file list comes from the captain's old lines 139-142.
6. Production only: an unnamed background voice agent in post-publish mode proposes profile changes, which main applies only after user approval.

### Workflow shape
The full skeleton is in the Appendix.
- **Draft:** the writer starts first (it heads the resume chain). The inline-image agent runs concurrently as a `.catch()`ed floating promise.
- **Assets:** when the draft returns, start the cover (reads the MDX, `Frontmatter: skip`) and the diagram author (only for `diagram_ideas`) as floating promises. They overlap Review and Revise.
- **Review:** `parallel(editor, voice)`.
- **Revise:**
  - Must-fix: editor must, voice must, `validate_errors`, and voice should when the score is below 3.
  - A pass runs when there is any must-fix, or on cycle 1 when there are 3 or more should-fix items or any image or diagram placements. A pass that runs gets **all** should-fix items.
  - Max 2 cycles. Cycle 2 runs only if a low-effort editor recheck finds unresolved must-fix items.
- **Finalize:** await the cover, then `blog-finalize`. If the cover drifted, brand-graphics runs in patch mode.
- A `finally` block awaits every floating promise. The return is `{status, post, scores, revisions, assets, final, unresolved}`.
- An args guard at the top returns `failed` when the workflow is run as `/blog-pipeline` without args.

## Phase 3: /refine, moved into main (no workflow)

`commands/refine.md`:
- Keep the prep.
- Main fans out 3-4 **unnamed** `refine-reader` agents (registered, haiku) in one message.
- Main consolidates (dedupe, cap, sort by confidence), runs the AskUserQuestion approval loop with the same accept syntax (captain lines 66-72), then `refine-snapshot.sh`, then applies the approved `proposed_edit`s with Edit and re-verifies.
- Main writes the audit log (format from captain lines 90-97), drains the queue, touches `.last-refine-timestamp`, and saves a vector-memory summary.
- Preserve the captain's safety rules (lines 130-138): BLOCK and WARN double-confirm, rollback on a failed verify, never push, no frontmatter edits, and non-unique anchors downgrade.
- Delete `refine-captain.md`.

## Phase 4: Retire, register, docs

- **Retire `multi-repo-orchestrator.md`.** Nothing invokes it; `/multi-repo-status` uses `wrap-up-survey.sh`. Remove its doc references.
- **Register** `evolve-synthesizer`, `sync-orchestrator`, and `wrap-up-orchestrator` (narrow descriptions, tools audited), and have their skills spawn them by `subagent_type`. (`config-doc-updater` isn't an agent file.)
- **Docs:**
  - README (line 3 counts; rows 75/79/94/102/104/114)
  - COMPLETE-GUIDE (766/860/862)
  - `docs/ARCHITECTURE.md:263` and `docs/COMPONENT-REFERENCE.md:80`, plus a Workflows section in each
  - `skills/skill-catalog/SKILL.md:12` (list `workflows/*.js`)
  - `skills/claude-config-sync` (workflows count)
  - `skills/ui-ux/SKILL.md:99-123`
  - `agents/notebooklm-content.md:195,213,316`
  - `commands/ingest-sessions.md:116,153`
  - `$BLOG_REPO/docs/cover-graphics-standards.md:7`
- **Out of scope:** registering the other ~20 unregistered agents. Enforced `tools` and auto-delegation need a per-file audit.

## Phase 5: game-dev + ui-ux → one `~/.claude/workflows/team-pipeline.js`

Lowest usage (1 and 3 archived sessions, against 31 for blog), so it's last and deferrable. After Phase 0 both skills already work.

- **Team specs are constants inside the script** (`GAME`, `UIUX`), selected by `args.team`. Each spec holds: roster, ownership map, gate rule, viewports, and per-mode stage lists.
- **Shared stage shape:**
  - brief/design
  - architect (game) or visual→component (ui-ux)
  - implement in parallel by ownership
  - QA
  - build/test loop (max 3)
  - gate loop (max 2, only when `args.iterate`)
- **Modes:** create, add, fix (triage first), debug (read-only investigator), design, build, review, and audit.
- **QA uses headless-Chrome screenshots**, not Playwright: no Playwright MCP is installed, and `tools` allowlists drop MCP anyway. Each QA agent starts and stops its own dev server on its own port.
- **Agents:**
  - `game-director.md` becomes `game-architect.md`, keeping the gates (64-77), ownership (60-62), and constraints (131-136).
  - Delete `ui-ux-director.md` and move its design-system persistence (149-153) and constraints (157-162) into the brief stage prompt.
  - Register all specialists.
  - Remove `Agent` from `ui-ux-reviewer`'s tools.
  - No `omitClaudeMd`, because these agents need the coding, testing, and security rules.
- **Skills:** keep discovery and the pre-survey, call Workflow, wait for the notification, and surface `decisions_needed[]`. Offer iterate (a new run in fix or add mode) or commit.

## Publishing

Never push from `~/.claude`: it's 9 commits ahead and 13 behind `origin/master`, with 101 dirty files. Changes reach the public repo through `~/GitProjects/claude-code-config` via `/claude-config-sync`. Before that, scan the new files for secrets and private-repo links (bare repo names are fine).

Copy this plan to `~/GitProjects/claude-code-config/docs/plans/orchestrator-workflow-rebuild-plan.md` at implementation start. Save the gotcha and the pattern to vector memory as each phase lands.

## Verification

1. **Phase 0:** re-run a small `/blog-post` backlog draft through the old captain, now unnamed. Expect zero SubagentHandback errors and no relays. This proves the hotfix before any rebuild.
2. **Phase 1:** smoke-test probes (above). `git check-ignore` passes for `workflows/*.js` in both repos. `sync-survey.sh | jq .diff.vs_config` lists the workflow and hook files.
3. **Hook:** through a one-agent workflow with `agentType:'blog-writer'`:
   - an MDX containing an em dash and `<100ms` triggers the fix-and-retry
   - a warnings-only file does NOT loop
4. **Blog end to end** (backlog draft on a real small topic). Record main pre-work, workflow time, and post-work separately against the 46-min baseline (12 min of which was handback overhead). Pass criteria:
   - no nested `Agent` tool_use in the run's transcript dir (jq over `select(.type=="assistant")…name`)
   - the cover starts when the draft returns
   - finalize is green: `validate-mdx` not FAIL, content-security, build
5. **Failure paths:**
   - Force the draft to fail: the result is `failed` only after the floating agents settle.
   - Kill the run during Review and resume with `resumeFromRunId`: cached stages return instantly.
   - Cut a cover number during revision: `cover_drift` is set and the patch runs.
6. **Regressions:**
   - standalone `/brand-graphics` still edits frontmatter
   - `/sync` still routes by `platform:`
   - `/refine` in `dry_run` completes its approval loop in main
   - an explicit agent team still works (spot-check)

## Appendix: `blog-pipeline.js` skeleton (from design review; refine during Phase 2)

```js
export const meta = {
  name: 'blog-pipeline',
  description: 'Internal stage of /blog-post: draft, review, revise, assets, finalize. Needs args from the skill.',
  whenToUse: 'Only via /blog-post; never directly.',
  phases: [{ title: 'Draft' }, { title: 'Assets' }, { title: 'Review' }, { title: 'Revise' }, { title: 'Finalize' }],
}
const A = args || {}
if (!A.repo || !A.slug || !A.runDir || !A.date || !(A.calibration || []).length)
  return { status: 'failed', error: 'launch via /blog-post with full args' }
const POST = `${A.repo}/src/content/${A.destination === 'backlog' ? 'backlog' : 'blog'}/${A.slug}.mdx`
const CTX = `Repo ${A.repo}. Post ${POST}. Run dir ${A.runDir}: source.md (only facts allowed), voice-profile.md, deslop.md, baseline.json. Calibration: ${A.calibration.join(', ')}.`
const O = (p) => ({ type: 'object', properties: p, required: Object.keys(p) })
const S = { type: 'string' }, N = { type: 'number' }, B = { type: 'boolean' }, L = (i) => ({ type: 'array', items: i })
const ITEM = O({ where: S, issue: S, fix: S })
const VAL = { type: 'string', enum: ['PASS', 'PASS_WITH_WARNINGS', 'FAIL'] }
const WRITER = O({ title: S, schemaType: S, words: N, validate: VAL, diagram_ideas: L(O({ concept: S, section: S })), applied: L(S), declined: L(O({ item: S, why: S })) })
const EDITOR = O({ scores: O({ hook: N, pacing: N, entertainment: N, accuracy: N }), must: L(ITEM), should: L(ITEM), protect: L(S) })
const VOICE = O({ score: N, must: L(ITEM), should: L(ITEM), validate_errors: L(S) })
const COVER = O({ png: S, alt: S, concept: S, headline: S, numbers_used: L(S), register_row_added: B })
const IMAGES = O({ images: L(O({ path: S, alt: S, section: S })) })
const DIAGRAMS = O({ components: L(O({ name: S, section: S })), tsc_pass: B, cleaned_up: B })
const RECHECK = O({ unresolved: L(S) })
const FINAL = O({ frontmatter_ok: B, cover_ok: B, cover_drift: L(S), validate: VAL, content_security: B, build: B, errors: L(S) })
const pending = []
const bg = (p) => { const s = p.catch((e) => ({ error: String(e) })); pending.push(s); return s }
const ok = (r) => !!r && !r.error
try {
  phase('Draft')
  const draftP = bg(agent(`MODE draft. ${CTX} Destination ${A.destination}; series ${A.series || 'none'} #${A.seriesOrder || '-'}; tone ${A.tone}; date ${A.date}; working title "${A.workingTitle}". Write ${POST}. Pick schemaType. diagram_ideas only where prose cannot carry structure.`,
    { agentType: 'blog-writer', schema: WRITER, label: 'writer: draft' }))
  const imagesP = A.inlineImages ? bg(agent(`${CTX} Make PNGs only from real assets in source.md into ${A.repo}/public/blog/${A.slug}/. Never edit MDX.`,
    { agentType: 'blog-inline-images', schema: IMAGES, phase: 'Assets' })) : Promise.resolve({ images: [] })
  const draft = await draftP
  if (!ok(draft)) return { status: 'failed', stage: 'draft', error: draft && draft.error }
  const coverP = bg(agent(`Type cover. Source: ${POST} (read-only). Frontmatter: skip. Output mode: repo (${A.repo}).`,
    { agentType: 'brand-graphics', schema: COVER, phase: 'Assets' }))
  const diagP = A.diagrams !== 'off' && draft.diagram_ideas.length
    ? bg(agent(`${CTX} Candidates: ${JSON.stringify(draft.diagram_ideas)}. Reuse first; register in all 3 registries; stop dev server, delete gallery route. Never edit MDX.`,
      { agentType: 'blog-diagram-author', schema: DIAGRAMS, phase: 'Assets' })) : Promise.resolve(null)
  phase('Review')
  const [ed, vo] = await parallel([
    () => agent(`Review ${POST}. ${CTX} Walk deslop.md explicitly; return must/should/protect.`, { agentType: 'blog-editor', schema: EDITOR, phase: 'Review' }),
    () => agent(`MODE post-draft. ${CTX} Run blog-voice-diff.sh and validate-mdx.sh on ${POST}. Metric outside profile P10-P90 = must.`, { agentType: 'blog-voice', schema: VOICE, phase: 'Review' }),
  ])
  phase('Revise')
  const [imgs, diags] = await Promise.all([imagesP, diagP])
  const placements = [
    ...(ok(imgs) ? imgs.images.map((i) => `![${i.alt}](${i.path.replace(/^.*\/public/, '')}) near "${i.section}"`) : []),
    ...(ok(diags) ? diags.components.map((c) => `<${c.name} /> near "${c.section}"`) : []),
  ]
  let must = [...(ed ? ed.must : []), ...(vo ? vo.must : []), ...(vo && vo.score < 3 ? vo.should : []),
              ...(vo ? vo.validate_errors.map((e) => ({ where: 'validate-mdx', issue: e, fix: '' })) : [])]
  const should = [...(ed ? ed.should : []), ...(vo && vo.score >= 3 ? vo.should : [])]
  const revisions = []
  for (let cycle = 1; cycle <= 2; cycle++) {
    const first = cycle === 1
    if (!must.length && !(first && (should.length >= 3 || placements.length))) break
    const todo = { must, should: first ? should : [], placements: first ? placements : [] }
    const rev = await agent(`MODE revision ${cycle}. ${CTX} Apply to ${POST}: ${JSON.stringify(todo)}. Protect: ${JSON.stringify(ed ? ed.protect : [])}. Decline should-fix only with a reason.`,
      { agentType: 'blog-writer', schema: WRITER, label: `writer: rev ${cycle}` })
    revisions.push({ cycle, applied: rev ? rev.applied : [], declined: rev ? rev.declined : [], validate: rev ? rev.validate : 'unknown' })
    if (!must.length) break
    const chk = await agent(`Recheck ${POST} for these must-fix items only; list unresolved: ${JSON.stringify(must)}`,
      { agentType: 'blog-editor', schema: RECHECK, effort: 'low', label: `recheck ${cycle}` })
    must = chk ? chk.unresolved.map((u) => ({ where: '', issue: u, fix: '' })) : must
  }
  phase('Finalize')
  const cover = await coverP
  const fin = await agent(`${CTX} 1) ${ok(cover) ? `Insert coverImage: /blog/${A.slug}/infographic.png and coverImageAlt: ${JSON.stringify(cover.alt)} into ${POST}.` : 'No cover; skip.'} 2) cover_drift = which of ${JSON.stringify(ok(cover) ? [cover.headline, ...cover.numbers_used] : [])} no longer appear in the post. 3) sips = 2752x1536; register row for ${A.slug} in docs/cover-graphics-standards.md. 4) In ${A.repo}: validate-mdx.sh, npx vitest run src/__tests__/content-security.test.ts, npm run build. Quote errors verbatim.`,
    { agentType: 'blog-finalize', schema: FINAL })
  let coverOut = ok(cover) ? cover : null
  if (fin && coverOut && fin.cover_drift.length) {
    const p = await agent(`Patch mode: edit content-assets/covers/${A.slug}/cover.html so ${JSON.stringify(fin.cover_drift)} match ${POST}; re-render; rerun your verification loop. Never edit MDX.`,
      { agentType: 'brand-graphics', schema: COVER, phase: 'Finalize', label: 'cover: patch' })
    if (ok(p)) coverOut = p
  }
  return {
    status: fin && fin.build && fin.content_security && fin.validate !== 'FAIL' ? 'ready' : 'needs-attention',
    post: { path: POST, title: draft.title, schemaType: draft.schemaType, words: draft.words },
    scores: { editor: ed ? ed.scores : null, voice: vo ? vo.score : null },
    revisions, assets: { cover: coverOut, images: ok(imgs) ? imgs.images : [], diagrams: ok(diags) ? diags.components : [] },
    final: fin, unresolved: must.map((m) => m.issue),
  }
} finally {
  await Promise.all(pending)
}
```
