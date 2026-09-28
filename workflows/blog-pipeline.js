export const meta = {
  name: 'blog-pipeline',
  description: 'Internal stage of /blog-post: draft, assets, review, revise, finalize a cryptoflexllc.com post. Needs args from the skill.',
  whenToUse: 'Only via the /blog-post skill, which gathers the args. Never run directly.',
  phases: [
    { title: 'Draft', detail: 'blog-writer drafts the MDX; inline images start in parallel' },
    { title: 'Assets', detail: 'cover, inline images, diagrams run in the background' },
    { title: 'Review', detail: 'blog-editor and blog-voice (metrics, validate-mdx, content-security) in parallel' },
    { title: 'Revise', detail: 'routed must/should fixes and placements, rechecked, max 2 cycles' },
    { title: 'Finalize', detail: 'drift check, cover patch if needed, cover frontmatter, validate, content-security, build' },
  ],
}
// platform: macos
// Called by ~/.claude/skills/blog-post/skill.md Step 4. Agents live in ~/.claude/agents/blog-*.md
// and brand-graphics.md (registered by their `name:` frontmatter). Replaces the old blog-captain
// orchestrator, whose nested subagents could not hand back reports when spawned as a teammate.

const A = args || {}
const SLUG_RE = /^[a-z0-9]+(-[a-z0-9]+)*$/
if (!A.repo || !A.slug || !SLUG_RE.test(A.slug) || !A.runDir || !A.date || !Array.isArray(A.calibration) || A.calibration.length < 1) {
  return { status: 'failed', stage: 'args', error: 'blog-pipeline must be launched by /blog-post with full args (repo, slug matching [a-z0-9-], runDir, date, calibration[])' }
}

const POST = `${A.repo}/src/content/${A.destination === 'production' ? 'blog' : 'backlog'}/${A.slug}.mdx`
const PUBLIC = `${A.repo}/public`
const LENGTH = A.length ? ` Length target (overrides corpus ranges): ${A.length}.` : ''
const SERIES = A.series ? ` Series "${A.series}" seriesOrder ${A.seriesOrder}${A.seriesOrder === 1 ? ' (new series)' : ''} are fixed inputs.` : ''
const CTX = `Repo ${A.repo}. Post ${POST}. Slug ${A.slug}. Run dir ${A.runDir}: source.md (the only facts allowed), voice-profile.md, deslop.md, baseline.json. Calibration posts: ${A.calibration.join(', ')}. Tone: ${A.tone || 'Educational and friendly'}.${LENGTH}${SERIES}`

// Schema helpers (root must be an object; required lists every property)
const O = (p) => ({ type: 'object', properties: p, required: Object.keys(p) })
const S = { type: 'string' }, N = { type: 'number' }, B = { type: 'boolean' }
const L = (i) => ({ type: 'array', items: i })
const ITEM = O({ where: S, issue: S, fix: S })
const VAL = { type: 'string', enum: ['PASS', 'PASS_WITH_WARNINGS', 'FAIL'] }
const WRITER = O({ title: S, schemaType: S, words: N, validate: VAL, diagram_ideas: L(O({ concept: S, section: S })), applied: L(S), declined: L(O({ item: S, why: S })) })
const EDITOR = O({ scores: O({ hook: N, pacing: N, entertainment: N, accuracy: N }), must: L(ITEM), should: L(ITEM), protect: L(S) })
const VOICE = O({ score: N, must: L(ITEM), should: L(ITEM), validate_errors: L(S), security_errors: L(S) })
const COVER = O({ png: S, alt: S, concept: S, headline: S, numbers_used: L(S), register_row_added: B })
const IMAGES = O({ images: L(O({ path: S, alt: S, section: S })) })
const DIAGRAMS = O({ components: L(O({ name: S, section: S })), tsc_pass: B, cleaned_up: B })
const RECHECK = O({ unresolved: L(N) })
const DRIFT = O({ cover_drift: L(S), placements_missing: L(S) })
const FINAL = O({ frontmatter_ok: B, cover_ok: B, validate: VAL, content_security: B, build: B, errors: L(S) })

// Background stages: catch at creation (no unhandled rejection), settle all in finally (no orphans)
const pending = []
const bg = (p) => { const s = p.catch((e) => ({ error: String(e) })); pending.push(s); return s }
const ok = (r) => !!r && !r.error
// agent() can throw (schema retries exhausted, budget); awaited stages degrade to {error} instead of killing the run
const safe = (p) => p.catch((e) => ({ error: String(e) }))
const stageErrors = []
const need = (r, name) => { if (!r) stageErrors.push(`${name} returned nothing`); else if (r.error) stageErrors.push(`${name}: ${r.error}`); return ok(r) }
const toPublicUrl = (p) => (p.startsWith(PUBLIC + '/') ? p.slice(PUBLIC.length) : p)

try {
  // ---------------- Draft ----------------
  phase('Draft')
  // Writer starts first: it heads the resume chain, so a cover failure never forces a redraft.
  const draftP = bg(agent(
    `MODE draft. ${CTX} Destination ${A.destination || 'backlog'}; date ${A.date}; working title "${A.workingTitle || ''}". Write the complete post to ${POST}.`,
    { agentType: 'blog-writer', schema: WRITER, label: 'writer: draft', phase: 'Draft' }))

  const imagesP = A.inlineImages
    ? bg(agent(
        `${CTX} Build inline images for this post from the real assets listed in source.md, into ${PUBLIC}/blog/${A.slug}/. Never write infographic.png. Never edit the MDX.`,
        { agentType: 'blog-inline-images', schema: IMAGES, label: 'inline images', phase: 'Assets' }))
    : Promise.resolve({ images: [] })

  const draft = await draftP
  if (!ok(draft)) return { status: 'failed', stage: 'draft', error: draft ? draft.error : 'writer returned nothing' }

  // ---------------- Assets (background) ----------------
  const coverP = bg(agent(
    `Type: cover. Source: ${POST} (read-only; never edit it). Frontmatter: skip. Output mode: repo (${A.repo}). Slug ${A.slug}.`,
    { agentType: 'brand-graphics', schema: COVER, label: 'cover', phase: 'Assets' }))

  const wantDiagrams = A.diagrams !== 'off' && draft.diagram_ideas && draft.diagram_ideas.length > 0
  const diagP = wantDiagrams
    ? bg(agent(
        `${CTX} Diagram candidates from the writer: ${JSON.stringify(draft.diagram_ideas)}. Reuse an existing component first; otherwise author ${A.repo}/src/components/mdx/diagrams-${A.slug}.tsx and register it in all 3 registries. Stop your dev server and delete the gallery route before returning. Never edit the MDX.`,
        { agentType: 'blog-diagram-author', schema: DIAGRAMS, label: 'diagrams', phase: 'Assets' }))
    : Promise.resolve(null)

  // ---------------- Review ----------------
  phase('Review')
  const [ed, vo] = await parallel([
    () => agent(`Review ${POST}. ${CTX} Walk deslop.md explicitly and run the structural checks; return must/should/protect.`,
      { agentType: 'blog-editor', schema: EDITOR, label: 'editor', phase: 'Review' }),
    () => agent(`MODE post-draft. ${CTX} Run blog-voice-diff.sh, validate-mdx.sh, and the content-security test on ${POST}. A metric outside the profile's P10-P90 or TARGET range (after the length override) is must.`,
      { agentType: 'blog-voice', schema: VOICE, label: 'voice', phase: 'Review' }),
  ])
  need(ed, 'editor')
  need(vo, 'voice')

  // ---------------- Revise ----------------
  phase('Revise')
  const [imgs, diags] = await Promise.all([imagesP, diagP])
  if (A.inlineImages) need(imgs, 'inline images')
  if (wantDiagrams) need(diags, 'diagrams')
  const placements = [
    ...(ok(imgs) ? imgs.images.map((i) => ({ token: toPublicUrl(i.path), line: `![${i.alt}](${toPublicUrl(i.path)})`, section: i.section })) : []),
    ...(ok(diags) ? diags.components.map((c) => ({ token: `<${c.name}`, line: `<${c.name} />`, section: c.section })) : []),
  ]
  // Every must item carries its origin so the right reviewer rechecks it.
  let must = [
    ...(ed ? ed.must.map((m) => ({ ...m, src: 'editor' })) : []),
    ...(vo ? vo.must.map((m) => ({ ...m, src: 'voice' })) : []),
    ...(vo && vo.score < 3 ? vo.should.map((m) => ({ ...m, src: 'voice' })) : []),
    ...(vo ? vo.validate_errors.map((e) => ({ where: 'validate-mdx', issue: e, fix: 'resolve the validator error', src: 'voice' })) : []),
    ...(vo ? vo.security_errors.map((e) => ({ where: 'content-security test', issue: e, fix: 'remove the flagged private name, username, or secret', src: 'voice' })) : []),
  ]
  const should = [...(ed ? ed.should : []), ...(vo && vo.score >= 3 ? vo.should : [])]
  const revisions = []
  for (let cycle = 1; cycle <= 2; cycle++) {
    const first = cycle === 1
    // A pass runs on any must-fix, or on cycle 1 when should-fix reaches 3+ or there is anything to place.
    // A pass that runs carries ALL should-fix items (3+ is only the trigger).
    if (!must.length && !(first && (should.length >= 3 || placements.length))) break
    const todo = {
      must: must.map(({ where, issue, fix }) => ({ where, issue, fix })),
      should: first ? should : [],
      placements: first ? placements.map((p) => `${p.line} near section "${p.section}"`) : [],
    }
    const rev = await safe(agent(
      `MODE revision ${cycle}. ${CTX} Apply this work list to ${POST}: ${JSON.stringify(todo)}. Protect these lines: ${JSON.stringify(ed ? ed.protect : [])}. Decline a should-fix item only with a reason.`,
      { agentType: 'blog-writer', schema: WRITER, label: `writer: revision ${cycle}`, phase: 'Revise' }))
    revisions.push({ cycle, applied: ok(rev) ? rev.applied : [], declined: ok(rev) ? rev.declined : [], validate: ok(rev) ? rev.validate : 'unknown' })
    if (!need(rev, `writer revision ${cycle}`)) break
    if (rev.validate === 'FAIL') must.push({ where: 'validate-mdx', issue: 'writer reports validate-mdx still FAILs after revision', fix: 'resolve the validator errors', src: 'voice' })
    if (!must.length) break

    // Recheck each must item with the reviewer that can verify it; results are indices into its sublist.
    const edItems = must.filter((m) => m.src === 'editor')
    const voItems = must.filter((m) => m.src !== 'editor')
    const numbered = (items) => items.map((m, i) => `${i}. [${m.where}] ${m.issue}`).join('\n')
    const [edChk, voChk] = await parallel([
      () => edItems.length ? agent(`Recheck. ${CTX} Numbered must-fix items:\n${numbered(edItems)}`,
        { agentType: 'blog-editor', schema: RECHECK, effort: 'low', label: `recheck editor ${cycle}`, phase: 'Revise' }) : Promise.resolve({ unresolved: [] }),
      () => voItems.length ? agent(`MODE recheck. ${CTX} Numbered must-fix items:\n${numbered(voItems)}`,
        { agentType: 'blog-voice', schema: RECHECK, effort: 'low', label: `recheck voice ${cycle}`, phase: 'Revise' }) : Promise.resolve({ unresolved: [] }),
    ])
    const keep = (items, chk) => (chk ? items.filter((_, i) => chk.unresolved.includes(i)) : items)
    must = [...keep(edItems, edChk), ...keep(voItems, voChk)]
    if (!must.length) break
  }

  // ---------------- Finalize ----------------
  phase('Finalize')
  const cover = await coverP
  need(cover, 'cover')
  let coverOut = ok(cover) ? cover : null

  // 1) read-only drift + placement check on the body (before any frontmatter write)
  const drift = await safe(agent(
    `MODE drift. Post ${POST}. Cover strings: ${JSON.stringify(coverOut ? coverOut.numbers_used : [])}. Placement tokens: ${JSON.stringify(placements.map((p) => p.token))}.`,
    { agentType: 'blog-finalize', schema: DRIFT, label: 'drift check', phase: 'Finalize' }))
  const driftOk = need(drift, 'drift check')
  let driftLeft = driftOk ? drift.cover_drift : []

  // 2) patch the cover if its numbers drifted from the final draft
  if (coverOut && driftLeft.length) {
    log(`Cover drifted from the final draft (${driftLeft.join(', ')}); patching.`)
    const patched = await safe(agent(
      `Patch mode. Source: ${POST} (read-only). Frontmatter: skip. Output mode: repo (${A.repo}). Slug ${A.slug}. Drifted strings: ${JSON.stringify(driftLeft)}. Edit ${A.repo}/content-assets/covers/${A.slug}/cover.html so they match the post, re-render, rerun the verification loop.`,
      { agentType: 'brand-graphics', schema: COVER, label: 'cover: patch', phase: 'Finalize' }))
    if (need(patched, 'cover patch')) { coverOut = patched; driftLeft = [] }
  }

  // 3) frontmatter with the final alt, then the gates
  const finR = await safe(agent(
    `MODE finalize. Repo ${A.repo}. Post ${POST}. Slug ${A.slug}. ${coverOut ? `Alt text: ${JSON.stringify(coverOut.alt)}.` : 'No cover was produced: skip the frontmatter step (frontmatter_ok false) and report cover_ok false.'}`,
    { agentType: 'blog-finalize', schema: FINAL, label: 'finalize', phase: 'Finalize' }))
  const fin = need(finR, 'finalize') ? finR : null

  const placementsMissing = driftOk ? drift.placements_missing : placements.map((p) => p.token)
  const diagramsClean = !wantDiagrams || (ok(diags) && diags.tsc_pass && diags.cleaned_up)
  if (ok(diags) && !(diags.tsc_pass && diags.cleaned_up)) stageErrors.push('diagram author reported tsc failure or an uncleaned dev server/gallery route')

  // "ready" only when every gate is green and nothing is left for a human to resolve.
  const green = !!fin && fin.build && fin.content_security && fin.validate !== 'FAIL' && fin.frontmatter_ok && fin.cover_ok
    && !!coverOut && !driftLeft.length && !must.length && !!ed && !!vo && revisions.every((r) => r.validate !== 'unknown')
    && diagramsClean && !placementsMissing.length && !stageErrors.length

  return {
    status: green ? 'ready' : 'needs-attention',
    post: { path: POST, slug: A.slug, destination: A.destination || 'backlog', title: draft.title, schemaType: draft.schemaType, words: draft.words },
    scores: { editor: ed ? ed.scores : null, voice: vo ? vo.score : null },
    revisions,
    assets: { cover: coverOut, images: ok(imgs) ? imgs.images : [], diagrams: ok(diags) ? diags : null },
    final: fin,
    unresolved: [
      ...must.map((m) => `${m.where}: ${m.issue}`),
      ...driftLeft.map((d) => `cover still shows "${d}", which is no longer in the post`),
      ...placementsMissing.map((t) => `placement not found in the post: ${t}`),
    ],
    stage_errors: stageErrors,
  }
} finally {
  await Promise.all(pending)
}
