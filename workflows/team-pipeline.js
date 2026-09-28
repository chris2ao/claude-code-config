export const meta = {
  name: 'team-pipeline',
  description: 'Internal stage of /game-dev and /ui-ux: runs a specialist team (game or uiux) through plan, build, QA, integrate, and review for one mode. Needs args from the skill.',
  whenToUse: 'Only via the /game-dev or /ui-ux skill, which gathers the args. Never run directly.',
  phases: [
    { title: 'Plan', detail: 'design specs, architecture or brief, triage, investigation' },
    { title: 'Build', detail: 'specialists implement in parallel by file ownership' },
    { title: 'QA', detail: 'viewport QA (Playwright MCP where configured, else headless Chrome)' },
    { title: 'Integrate', detail: 'build and test, route failures to owners (max 3 rounds)' },
    { title: 'Review', detail: 'performance and UX review, gate loop (max 2 when iterate is on)' },
  ],
}
// platform: portable
// Replaces the game-director and ui-ux-director orchestrator agents (retired 2026-09-27). The team specs
// below are data; the stage shape is shared. Agents live in ~/.claude/agents/ and are registered by `name:`.

const TEAMS = {
  game: {
    lead: 'game-architect',
    modes: ['create', 'add', 'fix', 'debug'],
    viewports: '375x667 (mobile portrait), 667x375 (mobile landscape), 768x1024 (tablet), 1280x720 (desktop)',
    gates: 'controls visible and usable at every viewport; no overlapping UI on mobile portrait; every interactive element >= 44px touch target; accessible labels on every interactive element',
  },
  uiux: {
    lead: 'ui-ux-lead',
    modes: ['design', 'build', 'review', 'fix', 'audit'],
    viewports: '375x667, 667x375, 768x1024, 1280x720, 1536x864',
    gates: 'PASS: heuristic >= 3.5, TASTE >= 3.0, critical design rules pass, no AI-slop, responsive at all viewports. CONDITIONAL: minor rule violations, one or two heuristics < 3, TASTE 2.5-3.0. FAIL: critical rule violations, heuristic < 3.0, TASTE < 2.5, AI-slop, broken layout, missing critical states',
  },
}

const A = args || {}
const T = TEAMS[A.team]
if (!T || !T.modes.includes(A.mode) || !A.projectPath || !A.scope || !Array.isArray(A.roster)) {
  return { status: 'failed', stage: 'args', error: 'team-pipeline must be launched by /game-dev or /ui-ux with team, mode, projectPath, scope, roster[]' }
}
const on = (name) => A.roster.includes(name)
const CTX = `Project ${A.projectPath} (work there with absolute paths). Team ${A.team}, mode ${A.mode}. Stack: ${A.stack || 'see pre-survey'}. Scope: ${A.scope}. Pre-survey: ${A.survey || 'none'}.`

// ---- schemas ----
const O = (p) => ({ type: 'object', properties: p, required: Object.keys(p) })
const S = { type: 'string' }, N = { type: 'number' }, B = { type: 'boolean' }
const L = (i) => ({ type: 'array', items: i })
const OWNED = O({ agent: S, paths: L(S), task: S })
const FIX = O({ issue: S, file: S, owner: S, fix: S })
const FAILURE = O({ owner: S, file: S, error: S })
const SPEC = O({ spec: S, summary: S })
const ARCH = O({ ownership: L(OWNED), architecture_summary: S, files_created: L(S) })
const BRIEF = O({ brief: S, needs_visual_designer: B, ownership: L(OWNED), scaffold: S })
const ASSIGN = O({ assignments: L(O({ agent: S, task: S, files: L(S) })), diagnosis: S })
const WORK = O({ summary: S, files_created: L(S), files_modified: L(S), open_issues: L(S) })
const QA = O({ pass: B, issues: L(O({ viewport: S, issue: S, owner: S })), screenshots: L(S) })
const INTEG = O({ build_pass: B, tests_passed: N, tests_failed: N, coverage: S, failures: L(FAILURE), files_modified: L(S) })
const INVEST = O({ findings: L(S), root_cause: S, recommended_fix: S, needs_design_change: B })
const PERF = O({ summary: S, issues: L(O({ severity: S, file: S, issue: S, fix: S })), positive_findings: L(S) })
const GATE = { type: 'string', enum: ['PASS', 'CONDITIONAL', 'FAIL'] }
const UXREV = O({ heuristic_avg: N, taste_avg: N, design_rules_passed: N, gate: GATE, critical: L(FIX), recommendations: L(S), summary: S })
const SYNTH = O({ summary: S, critical: L(FIX), high: L(FIX), medium: L(FIX), recommendation: GATE })

// ---- shared helpers ----
const reports = {}
const filesCreated = new Set()
const filesModified = new Set()
const decisions = []
const track = (r) => {
  if (!r) return r
  ;(r.files_created || []).forEach((f) => filesCreated.add(f))
  ;(r.files_modified || []).forEach((f) => filesModified.add(f))
  ;(r.open_issues || []).forEach((i) => decisions.push(i))
  return r
}
const work = (agentType, task, extra, label) => agent(
  `${CTX} Your task: ${task} ${extra || ''} Stay inside the paths you own; never spawn agents. Return your summary as structured output.`,
  { agentType, schema: WORK, label: label || agentType, phase: 'Build' }).then(track)

// Parallel implement over [{agent, task, paths|files}], only for roster members.
async function implement(items, context) {
  const mine = items.filter((i) => on(i.agent))
  const skipped = items.filter((i) => !on(i.agent)).map((i) => i.agent)
  if (skipped.length) log(`Not on roster, skipped: ${skipped.join(', ')}`)
  const out = await parallel(mine.map((i) => () =>
    work(i.agent, i.task, `Owned paths/files: ${JSON.stringify(i.paths || i.files || [])}. ${context || ''}`, `${i.agent}: build`)))
  mine.forEach((i, k) => { reports[i.agent] = out[k] })
  return out
}

// Route failures back to their owners (one agent per owner), then re-run the check. Max `rounds`.
async function fixLoop(check, rounds, label) {
  let result = await check(0)
  for (let r = 1; r <= rounds && result && result.failures && result.failures.length; r++) {
    const byOwner = {}
    result.failures.forEach((f) => { (byOwner[f.owner] = byOwner[f.owner] || []).push(f) })
    const owners = Object.keys(byOwner).filter(on)
    if (!owners.length) { log(`No roster member owns the remaining ${label} failures; stopping the fix loop.`); break }
    await parallel(owners.map((owner) => () =>
      work(owner, `Fix these ${label} failures in your files: ${JSON.stringify(byOwner[owner])}`, '', `${owner}: fix ${r}`)))
    result = await check(r)
  }
  return result
}

const integrate = () => fixLoop((r) => agent(
  `MODE integrate. ${CTX} Implementer reports: ${JSON.stringify(reports)}. Wire the pieces, run build and tests, fix only glue; route real defects as failures with owners.`,
  { agentType: T.lead, schema: INTEG, label: `integrate ${r}`, phase: 'Integrate' }).then(track), 3, 'build/test')

const qa = (who) => agent(
  `${CTX} QA stage: validate the running app at viewports ${T.viewports}. Gates: ${T.gates}. Attribute each issue to an owner. Stop any dev server you start.`,
  { agentType: who, schema: QA, label: 'visual QA', phase: 'QA' })

{
  // =============================== GAME ===============================
  if (A.team === 'game') {
    phase('Plan')
    if (A.mode === 'debug') {
      const inv = await agent(`MODE investigate. ${CTX}`, { agentType: T.lead, schema: INVEST, label: 'investigate', phase: 'Plan' })
      if (inv && inv.needs_design_change) decisions.push('Investigation suggests a design change; consider /game-dev in add mode with game-designer.')
      return { status: inv ? 'ready' : 'failed', team: A.team, mode: A.mode, investigation: inv, decisions_needed: decisions, next_steps: inv ? [inv.recommended_fix] : [] }
    }

    let spec = null
    let plan = null
    if (A.mode === 'fix') {
      plan = await agent(`MODE triage. ${CTX} Roster: ${A.roster.join(', ')}.`, { agentType: T.lead, schema: ASSIGN, label: 'triage', phase: 'Plan' })
      if (!plan) return { status: 'failed', stage: 'triage', team: A.team, mode: A.mode }
      phase('Build')
      await implement(plan.assignments, `Diagnosis: ${plan.diagnosis}`)
    } else {
      // create | add: design specs, then architecture with a disjoint ownership map
      const [design, story] = await parallel([
        () => on('game-designer') ? agent(`${CTX} Produce the design spec: core loop, mechanics, systems, data types, balance, progression.`, { agentType: 'game-designer', schema: SPEC, label: 'design', phase: 'Plan' }) : Promise.resolve(null),
        () => on('game-writer') && A.mode === 'create' ? agent(`${CTX} Produce world, story, characters, and dialogue as a spec (typed data comes later).`, { agentType: 'game-writer', schema: SPEC, label: 'story', phase: 'Plan' }) : Promise.resolve(null),
      ])
      spec = { design, story }
      reports['game-designer'] = design
      plan = await agent(`MODE architect. ${CTX} Roster: ${A.roster.join(', ')}. Design: ${JSON.stringify(spec)}`,
        { agentType: T.lead, schema: ARCH, label: 'architect', phase: 'Plan' }).then(track)
      if (!plan) return { status: 'failed', stage: 'architect', team: A.team, mode: A.mode }
      phase('Build')
      await implement(plan.ownership, `Design spec: ${JSON.stringify(spec)}. Architecture: ${plan.architecture_summary}`)

      if (on('game-ux')) {
        phase('QA')
        const q = await qa('game-ux')
        reports.qa = q
        if (q && !q.pass && q.issues.length) {
          const byOwner = {}
          q.issues.forEach((i) => { (byOwner[i.owner] = byOwner[i.owner] || []).push(i) })
          await parallel(Object.keys(byOwner).filter(on).map((owner) => () =>
            work(owner, `Fix these QA gate failures: ${JSON.stringify(byOwner[owner])}`, '', `${owner}: QA fix`)))
        }
      }
    }

    phase('Integrate')
    const integ = await integrate()
    const unresolved = integ ? integ.failures : ['integration stage returned nothing']
    return {
      status: integ && integ.build_pass && !integ.tests_failed && !integ.failures.length ? 'ready' : 'needs-attention',
      team: A.team, mode: A.mode,
      plan, reports,
      tests: integ ? { passed: integ.tests_passed, failed: integ.tests_failed, coverage: integ.coverage, build_pass: integ.build_pass } : null,
      files_created: [...filesCreated], files_modified: [...filesModified],
      decisions_needed: [...decisions, ...unresolved.map((f) => (typeof f === 'string' ? f : `${f.owner}: ${f.file}: ${f.error}`))],
    }
  }

  // =============================== UI/UX ===============================
  const review = async (label) => {
    const [perf, ux] = await parallel([
      () => on('ui-performance-reviewer') ? agent(`${CTX} Performance audit (Tier 1 and 2 first). Read-only.`, { agentType: 'ui-performance-reviewer', schema: PERF, label: `perf ${label}`, phase: 'Review' }) : Promise.resolve(null),
      () => on('ui-ux-reviewer') ? agent(`${CTX} Full review: heuristics, TASTE, 35 design rules, viewport QA at ${T.viewports}. Gate criteria: ${T.gates}. Attribute each critical issue to an owner (ui-visual-designer or ui-component-architect).`, { agentType: 'ui-ux-reviewer', schema: UXREV, label: `ux ${label}`, phase: 'Review' }) : Promise.resolve(null),
    ])
    reports['ui-performance-reviewer'] = perf || reports['ui-performance-reviewer']
    reports['ui-ux-reviewer'] = ux || reports['ui-ux-reviewer']
    return { perf, ux }
  }
  const gateLoop = async (first) => {
    let ux = first.ux
    for (let c = 1; c <= 2 && A.iterate && ux && ux.gate !== 'PASS'; c++) {
      const byOwner = {}
      ux.critical.forEach((i) => { (byOwner[i.owner] = byOwner[i.owner] || []).push(i) })
      await parallel(Object.keys(byOwner).filter(on).map((owner) => () =>
        work(owner, `Fix these review findings: ${JSON.stringify(byOwner[owner])}`, '', `${owner}: gate fix ${c}`)))
      ux = (await review(`recheck ${c}`)).ux
    }
    return ux
  }

  phase('Plan')
  if (A.mode === 'review' || A.mode === 'audit') {
    const audit = A.mode === 'audit'
    const scans = await parallel([
      () => audit && on('ui-visual-designer') ? agent(`${CTX} Audit design-system consistency and token drift. Do not modify files.`, { agentType: 'ui-visual-designer', schema: WORK, label: 'visual audit', phase: 'Review' }).then(track) : Promise.resolve(null),
      () => audit && on('ui-component-architect') ? agent(`${CTX} Audit component quality: semantic HTML, accessibility, responsive, 8 states. Do not modify files.`, { agentType: 'ui-component-architect', schema: WORK, label: 'component audit', phase: 'Review' }).then(track) : Promise.resolve(null),
      () => review(audit ? 'audit' : 'scan'),
    ])
    const synth = await agent(`MODE synthesize. ${CTX} Findings: ${JSON.stringify({ visual: scans[0], components: scans[1], review: scans[2] })}`,
      { agentType: T.lead, schema: SYNTH, label: 'synthesize', phase: 'Review' })
    const r = scans[2] || {}
    return {
      status: synth ? 'ready' : 'needs-attention', team: A.team, mode: A.mode, synthesis: synth, reports,
      quality: r.ux ? { heuristic_avg: r.ux.heuristic_avg, taste_avg: r.ux.taste_avg, design_rules_passed: r.ux.design_rules_passed, gate: r.ux.gate } : null,
      decisions_needed: decisions,
    }
  }

  if (A.mode === 'fix') {
    const plan = await agent(`MODE triage. ${CTX} Roster: ${A.roster.join(', ')}.`, { agentType: T.lead, schema: ASSIGN, label: 'triage', phase: 'Plan' })
    if (!plan) return { status: 'failed', stage: 'triage', team: A.team, mode: A.mode }
    phase('Build')
    await implement(plan.assignments, `Diagnosis: ${plan.diagnosis}`)
    phase('Review')
    const ux = on('ui-ux-reviewer') ? (await review('verify')).ux : null
    return {
      status: !ux || ux.gate !== 'FAIL' ? 'ready' : 'needs-attention', team: A.team, mode: A.mode, plan, reports,
      quality: ux ? { heuristic_avg: ux.heuristic_avg, taste_avg: ux.taste_avg, design_rules_passed: ux.design_rules_passed, gate: ux.gate } : null,
      files_created: [...filesCreated], files_modified: [...filesModified], decisions_needed: decisions,
    }
  }

  // design | build
  const brief = await agent(`MODE brief. ${CTX} Roster: ${A.roster.join(', ')}.`, { agentType: T.lead, schema: BRIEF, label: 'brief', phase: 'Plan' })
  if (!brief) return { status: 'failed', stage: 'brief', team: A.team, mode: A.mode }
  phase('Build')
  const byAgent = (name) => brief.ownership.find((o) => o.agent === name) || { agent: name, paths: [], task: brief.brief }
  if (A.mode === 'design') {
    // sequential: the architect builds on the visual system
    if (on('ui-visual-designer')) reports['ui-visual-designer'] = await work('ui-visual-designer', byAgent('ui-visual-designer').task, `Brief: ${brief.brief}`)
    if (on('ui-component-architect')) reports['ui-component-architect'] = await work('ui-component-architect', byAgent('ui-component-architect').task, `Brief: ${brief.brief}. Visual system: ${JSON.stringify(reports['ui-visual-designer'] || null)}`)
  } else {
    const items = [byAgent('ui-component-architect')]
    if (brief.needs_visual_designer) items.unshift(byAgent('ui-visual-designer'))
    await implement(items, `Brief: ${brief.brief}. Scaffold: ${brief.scaffold}`)
    phase('Integrate')
    reports.integration = await integrate()
  }
  phase('Review')
  const first = await review('gate')
  const ux = await gateLoop(first)
  const integ = reports.integration
  const buildOk = A.mode === 'design' || (integ && integ.build_pass && !integ.failures.length)
  return {
    status: buildOk && (!ux || ux.gate === 'PASS') ? 'ready' : 'needs-attention',
    team: A.team, mode: A.mode, brief, reports,
    quality: ux ? { heuristic_avg: ux.heuristic_avg, taste_avg: ux.taste_avg, design_rules_passed: ux.design_rules_passed, gate: ux.gate } : null,
    files_created: [...filesCreated], files_modified: [...filesModified],
    decisions_needed: [...decisions, ...(ux && ux.gate !== 'PASS' && !A.iterate ? ['UX gate is not PASS; run /ui-ux fix or re-run with iterate on'] : [])],
  }
}
