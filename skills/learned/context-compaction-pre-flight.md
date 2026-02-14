# Context Compaction Pre-Flight Pattern

**Extracted:** 2026-02-13
**Context:** Feb 12-13 sessions, pre-compaction API errors and graceful recovery

## Problem
Claude Code automatically compacts context when nearing token limits, but:
- No warning before compaction happens (hits at ~80-90% capacity)
- Pre-compaction API errors can occur (`Internal Server Error: 500`)
- User doesn't know if they're approaching compaction
- Massive sessions (900+ turns) risk loss if not planned carefully

## Pattern
Context compaction is **inevitable and graceful** when hooks + MEMORY.md are in place, but large deliverables benefit from strategic planning:

1. **Recognize compaction signals:**
   - Session has been running 2-4+ hours
   - Multiple large file reads/writes (cumulative token count grows)
   - Extensive agent exploration (90+ progress lines)
   - API errors occur mid-session (500 errors can indicate capacity pressure)

2. **Pre-compaction checklist:**
   - Save critical context to MEMORY.md (key decisions, file paths, patterns)
   - Commit in-progress work with descriptive messages
   - Note the current task phase in CHANGELOG.md
   - Prepare to resume from `git status` after compaction

3. **Post-compaction recovery:**
   - Run `git status` on all repos to reorient
   - Check MEMORY.md for preserved context
   - Review last commit message to understand where you left off
   - Continue work seamlessly (hooks preserved the transcript)

## Strategic Planning for Massive Sessions
For 900+ turn sessions (e.g., configuration overhaul, multi-file refactoring):

**Before starting:**
1. Estimate turn count (large file reads = ~50 turns, agent delegation = ~100-150 turns)
2. Break into phases if total > 800 turns
3. Start with fresh context (wrap up previous session completely)

**During execution:**
4. Monitor progress (if extensive agent work, approaching capacity)
5. Commit incrementally (each phase produces a commit, not just at the end)
6. Document as you go (update MEMORY.md with key insights, don't defer to end)

**If compaction occurs mid-session:**
7. Don't panic — hooks have archived the transcript
8. Resume from last commit with `git status`
9. Check `.claude/session_archive/` for the compacted session summary

## Example: Feb 13 Configuration Overhaul (941 turns, no compaction)
**Planning phase (193 turns):**
- Asked 5 planning questions
- Analyzed current state
- Designed 7-phase implementation

**Execution phase (748 turns):**
- Implemented 7 phases sequentially
- Committed after each phase
- Updated docs incrementally
- Stayed under compaction threshold

**Result:** Completed in one context window, zero loss.

## Anti-pattern
```
# DON'T: Start massive work with no plan, hope it fits
User: "Refactor the entire codebase"
Claude: (reads 50 files, 500 turns)
(compaction occurs mid-refactor, loses mental model)

# DO: Plan first, execute in phases
User: "Refactor the entire codebase"
Claude: (planning mode, 5 questions, 100 turns)
Claude: "This will take ~800 turns. I'll break into 3 phases:
  Phase 1: Core modules (300 turns)
  Phase 2: API layer (250 turns)
  Phase 3: Tests (250 turns)
  Each phase will commit independently."
(executes Phase 1, commits, continues)
```

## When to Use
- Planning sessions over 2 hours
- Large-scale refactoring (5+ files, complex logic)
- Configuration overhauls (many small edits across files)
- Multi-repo operations
- After seeing pre-compaction API errors in previous sessions
- When approaching 70-80% of typical compaction threshold (~2-3 hours of active work)
