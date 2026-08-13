# Voice Profile: cryptoflexllc.com Blog

**Author:** Chris Johnson
**Last Updated:** 2026-08-12
**Posts Analyzed:** 84

---

## Core Identity

The voice is a **senior engineer explaining something interesting to a peer**. Not lecturing, not selling, not flexing. Just one builder sharing what they learned with another builder.

Key traits:
- First-person perspective throughout ("I", "my", "we" when including the reader)
- Author as guide/protagonist, not detached expert
- Honest about mistakes and dead ends (documents what went wrong, not just what worked)
- Metric-driven leads (commits, hours, percentages, email counts)
- Conversational but technically precise
- Educational without being condescending
- Frustrated-but-honest tone when things go wrong (dry wit, not drama)

## Opening Patterns

The blog consistently uses three opening techniques:

1. **Metric hook** (most common, ~60% of posts): Lead with a specific number that creates immediate context.
   - "I just cut my Claude Code context consumption by 90%..."
   - "7 Days, 117 Commits, and a whole lot of learning..."
   - "My inbox had 369 unread emails..."

2. **Problem-scenario opener** (~25% of posts): Drop the reader into a relatable situation.
   - "Picture this: It's a Tuesday afternoon..."
   - "I set up the Claude Code iMessage plugin as a proof of concept..."

3. **Contrast/surprise opener** (~15% of posts): Set up and subvert an expectation.
   - "Not a badge-of-honor 'I'm so busy' kind of 369. A shameful 'I've been ignoring these' kind of 369."

The opening paragraph typically runs 20-65 words. Shorter is better.

## Pacing Rhythm

- **Paragraph length:** 14-31 words average (varies by post type; narrative posts trend longer)
- **Sentence length:** 12-15 words average
- **Visual breaks:** Callouts, code blocks, or tables every 3-5 paragraphs
- **Section length:** 200-400 words per major section (H2), with H3 subsections of 100-200 words
- **Flow pattern:** Prose -> code example -> explanation -> callout -> prose (repeating)

## Tone Markers

- **Contractions:** 12-20 per 1000 words. Higher in narrative posts, lower in technical reference.
- **First-person pronouns:** 11-33 per 1000 words. Higher in journey/retrospective posts (~30), lower in technical guides (~12).
- **Questions:** 0-4 per 1000 words. Used to set up explanations, not rhetorically.
- **Humor:** Self-deprecating, observational. Never forced. Appears naturally at frustration points or breakthrough moments.
- **Em dashes:** Never. House rule. Use commas, colons, periods, or parentheses instead.

## Characteristic Phrases

Recurring language patterns (not forced, but appear naturally):

- "Here's what I learned" / "Here's what happened" / "Here's where things got spicy"
- "The thing about [X]..." (philosophical setup)
- "Why this matters"
- "The short version" / "The real answer"
- "And then the wheels came off." (failure pivot)
- "Lessons learned" (as a section header near the end)
- "Not [X], but [Y]" (contrast structure for emphasis)
- "[Thing] is [thing]" (direct, declarative statements)

**Caution:** several of these (especially "The thing about [X]...", "Not [X], but [Y]", "Here's what I learned", "The short version") are now overexposed as AI-writing tells. They are fine used once and naturally; they become a liability the moment they stack or turn formulaic. See the AI-Slop Tells check below before leaning on them.

## Section Headers

Descriptive and personality-forward, not generic:
- "What Actually Works" over "Configuration"
- "The Thing About X" over "Overview"
- "Here's What I Actually Changed" over "Changes"
- Outcome hints in numbered attempts: "Attempt Two: Route to a Code Task"

## Humor Style

- Self-deprecating frustration, not forced comedy
- Understatement rather than exaggeration ("This is not a normal permission")
- Sarcastic observation at pain points ("I tried to automate this step. It cannot be done.")
- Let tension speak through narrative structure, no explicit punchlines
- Casual asides that reveal personality ("Here is where things get interesting.")

## Technical Explanation Pattern

Consistent approach: always explain narratively first (the "why" and "what happened"), then formalize in callout boxes. Never lead with abstract definitions or schema.

1. **Show it**: Code block, command, or screenshot
2. **Explain it**: What's happening and how it works (inline narrative)
3. **Why it matters**: Practical impact, what changes because of this
4. **Formalize it**: Callout box for reference/recap

For non-technical readers: wrap explanations in `<Info>` callouts with "What is [concept]?" titles.

## Callout Usage

- **Target:** 3-25 per post (scales with length)
- **Mix:** Tip (best practices) > Warning (gotchas) > Info (context) > Stop (critical) > Security (when applicable)
- **Style:** Concise titles (2-6 words), substantive content (1-3 sentences)
- **Placement:** After a lesson learned, before a common mistake, when introducing an unfamiliar concept

## GIF Usage

- GIFs appear in narrative/witty posts, rarely in technical reference posts
- Placed at emotional peaks: frustration, breakthrough, surprise
- Target: 3-10 for narrative posts, 0-3 for technical posts
- Source: Giphy CDN format
- Every GIF has descriptive alt text

## Closing Style

Posts typically end with one of:
- **Zoom out**: Move from specific solution to broader system or philosophy
- **Mirror the opening**: Return to the scenario from the hook, but resolved ("I will be lying in bed... not even thinking about it. Because it will already be running.")
- **Lessons Learned section** as a short prose paragraph (NOT a stack of bolded callout cards, one per lesson, which is a recognizable AI artifact; see the de-slop check)
- **What's Next** section (forward-looking, brief)
- **Summary table** or checklist (for how-to posts)
- Always reference series, config repo, or forward reference to next post
- Never ends abruptly. Always has a closing thought or reflection.

## AI-Slop Tells: The De-Slop Check

This blog is read by people who can smell LLM-assisted writing. The technical content is almost never the problem; the scaffolding around it is. Run this check on every draft before it ships. It comes from a four-agent editorial review (a human-editor lens plus a skeptical-reader lens, per post) across three posts in June 2026. Fix the structure first, then the phrases.

**The tells, with the fix:**

1. **Fragment-triplet and staccato drama.** Stacked verbless fragments for effect ("105 conflicted files. 161 commits... One PR..."), or the mic-drop beat ("Done. Except it's not done.", "It had not worked. Nothing had changed."). Fix: lead with the situation in a real sentence and let one number land as the gut-punch. A short fragment is fine as an earned punchline after a real point, never as a manufactured beat.
2. **Hype-labeling your own points.** "the killer insight", "the killer command", "the win", "the satisfying part", "(The Most Important Insight)", "the part worth writing about", "worth naming". A model flags its own points as important; a person just states the point. Fix: delete the label, keep the point.
3. **Thesis announcement / over-signposting.** "This is the playbook.", "Here is the part I actually want to talk about", "This post is the whole arc", "the part nobody teaches you", "That is the trap.", "and it deserves its own callout.", "Here is the shape of the problem." The prose pointing at itself or previewing its own structure. Fix: cut the announcement and just make the move. The section header already does that job.
4. **Bolded-lead-in takeaway stacks.** Several parallel "**Bold claim.** Explanation." items in a row, especially a Lessons Learned section built as 4-6 callout cards that each restate an inline callout. This is the single most recognizable artifact. Fix: dissolve into varied prose, or cut entirely if the body already carries the lessons. A recap should be one short in-voice paragraph with varied sentence shapes. (Exception: a version-tagged or genuinely scannable list where the bold carries data, e.g. "**Auth reliability (0.6.14).**", can stay.)
5. **Tricolon overload.** Relentless parallels of exactly three, and balanced triptych closers ("The branch will merge. The history will be intact. The trunk will move forward."). One earned triple is fine; back-to-back triples and a triptych ending are the tell. Fix: break at least one into ordinary prose and vary the clause count.
6. **Too-clean antithesis.** "Not X, but Y" with abstract pairs. Allowed only when the contrast carries a concrete, specific image ("a closed issue with no note is a dead end with a green checkmark" earns it; an abstract "not the bug, but the process" does not). Fix: make it concrete or cut it.
7. **Fake precision.** Invented measurements doing rhetorical work ("the easy 20 percent / the other 80 percent"). Fix: use a real number (232 tests passed, three files, 0.5.25 to 0.7.2) or plain language ("the small part / the bigger part").
8. **Telling the reader how to feel.** "you will be grateful", "the satisfying part", "infinitely more useful", "maddening". Fix: state the fact and let the reader feel it.
9. **Grand-summary closers.** LinkedIn-aphorism endings: "That is the whole job of...", "turns a package upgrade into a capability upgrade", "That is the shape that worked." Fix: end on something concrete and specific to this story. The thesis should not appear for the third time at the close.
10. **Restatement across containers.** The same point in body prose, then a callout, then a Lessons bullet (2-4 times). Fix: state each lesson once, in its strongest container, and cut the echoes.

**The structural tell (most important).** Real war stories run uneven: the author goes long on the part that actually interested them, short on the parts that did not, and occasionally circles back or adds an aside they almost cut. AI-assisted drafts are metronomic: every section is problem -> insight -> callout, every section the same length. Before shipping, deliberately let one or two sections run uneven. Expand the part you genuinely found interesting; compress the boilerplate.

**Protect these (do NOT sand off in a de-slop pass).** The lines that read human are the confessional and the specific: "I get this wrong half the time," incidental remembered details (a stray `argMax` bug fix, the exact line numbers for a splice), unhedged tool-preference opinions ("`sed` is the right tool for this, `awk` for that"), dry asides ("most of which was `make format` actually running"), and concrete images. A de-slop pass removes scaffolding, never personality. When in doubt, keep the messy, specific, first-person line.

**Pre-ship checklist:**
- [ ] No hype-labels ("killer", "the win", "worth writing about", "worth naming").
- [ ] No thesis-announcement or "This is the playbook"-style buttons.
- [ ] Lessons/recap is prose or one short paragraph, not a stack of bolded cards.
- [ ] No point stated more than twice across body + callouts.
- [ ] No triptych closer; the final line is concrete, not a thesis restatement.
- [ ] At least one section runs deliberately longer or shorter than the rest.
- [ ] The confessional and specific lines survived the edit.

## Things to NEVER Do

- Use em dashes
- Use marketing language ("revolutionary", "game-changing", "seamless")
- Link to private GitHub repositories
- Write vague statements without specifics
- Put markdown formatting inside code fences
- Start with lengthy background before the hook
- Use jargon without explanation
- Announce the post's own structure or thesis ("This is the playbook.", "Here is the part I actually want to talk about")
- Hype-label your own points ("the killer insight", "the win", "worth writing about")
- End a Lessons Learned section as a stack of bolded callout cards (use prose; see the de-slop check)
- Close on a grand-summary aphorism that restates the thesis a third time

## Metric Baselines (84-post corpus, 2026-07-22; ranges are P10-P90)

| Metric | Range | Notes |
|--------|-------|-------|
| Total words | 2,029-5,500 | Recent-15 median: 3,556 |
| Avg paragraph length | 23-50 words | Recent-15 median: 40 words, up sharply from the 2026-03-29 baseline (14-31). Prefer the lower half of the range; long uniform paragraphs read as drift, not style |
| Avg sentence length | 14-18 words | Recent-15 median: 16 words |
| Contractions per 1000 | TARGET: 10-20 | Corpus P10-P90 is 0-18 and the recent-15 median is 0. That zero is DRIFT toward AI-monotone, not the voice. Drafts with near-zero contractions fail voice review; write like the 2026-03-29 baseline (12-20) |
| First-person per 1000 | 4-21 | Recent-15 median: 10 |
| Questions per 1000 | TARGET: 1-4 | Recent-15 median of 0 is the same declarative drift. Use questions to set up explanations, as the profile has always specified |
| Callouts per post | 4-19 | Recent-15 median: 8 |
| Headings (H2) per post | 8-17 | Recent-15 median: 9 |
| Headings (H3) per post | 0-21 | Recent-15 median: 3. Bimodal: a few deeply nested technical posts run 10-14 while most run 0-6 |

## Evolution Log

- **2026-03-29 (initial)**: Profile seeded from analysis of 46 posts. Baseline metrics established from 4-post sample (iMessage channels, Gmail agent, 90% context, First 24 hours). No GIFs detected in recent posts (may have shifted away from GIF usage in newer content).
- **2026-06-14 (AI-slop check)**: Added the "AI-Slop Tells: The De-Slop Check" section after reader feedback that posts felt AI-generated. Derived from a four-agent editorial review (human-editor + skeptical-reader lenses) across three June 2026 backlog drafts (squash-vs-granular-trap, from-bug-report-to-release, keep-your-mcps-updated). Reconciled the conflict where "Characteristic Phrases" and "Closing Style" previously encoded patterns (formulaic "The thing about X", bolded Lessons-callout stacks) that now read as tells. Net guidance: the deepest tell is structural evenness, not any single phrase; let sections run uneven and protect the confessional/specific lines.
- **2026-07-22 (full-corpus re-baseline)**: Ran `blog-voice-diff.sh` against all 84 published posts in `src/content/blog/` (all 84 parsed cleanly, no failures). Computed P10-P90 and median across the full corpus, plus a separate median across the 15 most recent posts by frontmatter date (2026-05-14 through 2026-07-19), since the old 4-post baseline from 2026-03-29 was too small and too narrative-skewed to represent current output. Two real drifts stand out. First, paragraph length has grown well past the old 14-31 word range: the full corpus now runs 23-50 words (P10-P90), and the recent-15 median is 40 words, driven by the longer technical/homelab series (custom SIEM, Wazuh, Mission Control dashboard). Second, contraction use has fallen off: the old baseline was 12-20 per 1000 words, but the recent-15 median is 0, with 8 of the last 15 posts registering zero contractions. Questions per 1000 show the same pattern, dropping from the old 0-4 range to a recent-15 median of 0. Sentence length ticked up slightly (12-15 old vs. 14-18 full corpus, 16 recent median). Total word count now spans a much wider range (2,029-5,500 P10-P90) than the original narrow 4-post sample (2,700-6,700), simply because the corpus has grown far beyond that initial set. Worth flagging: the contraction and question drift may be an unintended side effect of the technical/homelab series leaning more declarative, not a deliberate voice choice, so it is worth a manual read-through rather than treating the new lower numbers as the new target.
- **2026-08-12 (Ledgerly part 2, backlog draft, not published)**: Reviewed `ledgerly-mcp-tool-calling-chat.mdx` in `src/content/backlog/`, not `src/content/blog/`. This is a completed draft awaiting publication, not a published post, so **Posts Analyzed stays at 84**; the published corpus has not changed. Part 2 of the Ledgerly series (part 1: `building-ledgerly-v1.mdx`, published 2026-08-10). Went through the full pipeline: pre-draft voice brief, draft, editor + voice + UX review in parallel, one revision cycle, cover graphic, final build. Editor scored 4.25/5 (hook 4, pacing 4, entertainment 4, accuracy 5); voice scored the pre-revision draft 4/5.

  Ran `blog-voice-diff.sh` against the final file directly rather than trusting the session's informally-reported numbers, since this is exactly the kind of check that should not skip verification. Two figures came back different from what was reported going into this review: contractions measured 57 (14/1000), not the ~88 (~19/1000) reported, because the informal session count included possessive `'s` forms ("CLI's", "user's", "SQLite's", "one's") that the script's contraction regex correctly excludes as not being contractions at all; sentence length measured 23 words average, not the ~21 reported. Everything else matched: 4,617 words, 11 H2 / 0 H3, 8 callouts (Tip 3, Warning 2, Info 2, Security 1), first-person 52 (12/1000), 4 questions, avg paragraph 34 words, 0 em dashes. Section word counts (H2-to-H2, code included) ranged 121-962, confirming sections ran deliberately uneven, consistent with the structural-tell guidance below.

  **Confirms existing guidance, no change:** the explicit 10-20/1000 contraction target in the pre-draft brief is working. Both this draft (14/1000, verified) and `building-ledgerly-v1.mdx` (13/1000, verified) land inside the target range, supporting the 2026-07-22 conclusion that the recent-15 median of 0 was drift toward AI-monotone, not the voice, and that stating an explicit numeric target in the brief is an effective fix.

  **Observation to watch, table not changed:** sentence length keeps landing above the stated 14-18 word range on Ledgerly/technical-narrative posts. This draft verified at 23 words/sentence, part 1 (`building-ledgerly-v1.mdx`) verified at 24. Two prior calibration posts were reported during this session (not independently re-verified here) at 24 and 18. That is three of the last four technical-narrative posts above the top of the range. The 2026-07-22 full-corpus re-baseline found the recent-15 median at 16, inside range, so this may be specific to long technical-narrative posts rather than a corpus-wide drift. Per the no-re-baseline-from-one-draft rule, the 14-18 table entry is unchanged; worth a full re-check once more posts of this subtype accumulate, to see whether 14-18 is stale for technical-narrative specifically or whether this is drift to correct in editing.

  **Observation, ten tells not changed:** "worth naming" (already on the banned hype-label list) had to be cut from this draft's first pass. That makes three sightings of the same underlying "N are/is worth [X]" construction across the series: "worth naming" here, "each worth a paragraph" in part 1, "worth writing about" in the tryhackme post. Per the instruction to leave the de-slop check's ten tells unmodified, tell #2 is not being edited on this run. Flagging for a future refinement pass to consider generalizing tell #2 from the single banned phrase to the construction, once more sightings accumulate.

  **Process observation, not a profile change:** this draft's first pass measured first-person at roughly 8/1000 (per the session's account; not independently re-verifiable now since only the final file remains), under the profile's own "~12 for technical guides" note, and needed a deliberate revision pass to reach the verified 12/1000. Technical-heavy posts appear to under-produce first-person by default the same way they under-produce contractions. A pre-draft brief that states an explicit first-person target, the way it already does for contractions, may avoid needing a dedicated revision pass for it on the next technical post.
