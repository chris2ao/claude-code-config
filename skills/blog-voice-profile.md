# Voice Profile: cryptoflexllc.com Blog

**Author:** Chris Johnson
**Last Updated:** 2026-06-14
**Posts Analyzed:** 46

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

## Metric Baselines (from 4-post sample, 2026-03-29)

| Metric | Range | Notes |
|--------|-------|-------|
| Total words | 2,700-6,700 | Scales with post type |
| Avg paragraph length | 14-31 words | Narrative: higher; technical: lower |
| Avg sentence length | 12-15 words | Consistent across types |
| Contractions per 1000 | 12-20 | Higher in narrative posts |
| First-person per 1000 | 11-33 | Higher in journey posts |
| Questions per 1000 | 0-4 | Used sparingly |
| Callouts per post | 3-25 | Scales with length |
| Headings (H2) per post | 10-28 | More in longer posts |
| Headings (H3) per post | 8-35 | Used for subsections |

## Evolution Log

- **2026-03-29 (initial)**: Profile seeded from analysis of 46 posts. Baseline metrics established from 4-post sample (iMessage channels, Gmail agent, 90% context, First 24 hours). No GIFs detected in recent posts (may have shifted away from GIF usage in newer content).
- **2026-06-14 (AI-slop check)**: Added the "AI-Slop Tells: The De-Slop Check" section after reader feedback that posts felt AI-generated. Derived from a four-agent editorial review (human-editor + skeptical-reader lenses) across three June 2026 backlog drafts (squash-vs-granular-trap, from-bug-report-to-release, keep-your-mcps-updated). Reconciled the conflict where "Characteristic Phrases" and "Closing Style" previously encoded patterns (formulaic "The thing about X", bolded Lessons-callout stacks) that now read as tells. Net guidance: the deepest tell is structural evenness, not any single phrase; let sections run uneven and protect the confessional/specific lines.
