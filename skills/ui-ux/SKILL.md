---
platform: portable
description: "UI/UX design and quality system: aesthetic direction, component architecture, performance, and visual QA with a coordinated agent team"
---

# /ui-ux - UI/UX Design Studio

Runs a team of UI/UX specialists to design, build, review, fix, or audit frontend interfaces. This skill runs in the main conversation: it gathers inputs, calls the saved workflow `~/.claude/workflows/team-pipeline.js` (team `uiux`), and handles decisions and commits. There is no director agent anymore. The `ui-ux-lead` agent holds the brief, triage, integration, and synthesis judgment, and the workflow script does the orchestration.

## When to Activate

- User asks to design, build, or improve any UI or frontend
- User asks for a design system, color palette, typography selection
- User asks to review or audit existing UI quality
- User says "make it look good", "fix the UI", "design review", or "visual QA"
- Any work involving React components, layouts, styling, or responsive design
- Pre-launch quality checks for frontend code

## User Discovery

Ask the user these questions (use AskUserQuestion, one at a time):

1. **Project:** Which project are you working on?
   - Provide the project name and path
   - If creating new UI, what is the product and who uses it?

2. **Mode:** What do you need?
   - **Design** - Create a new design system or major visual direction
   - **Build** - Build new pages, features, or components with design guidance
   - **Review** - Audit existing UI for quality, usability, and performance
   - **Fix** - Fix specific UI/UX issues
   - **Audit** - Full pre-launch quality check (all agents engaged)

3. **Scope:** What specifically do you need? (adapt to mode)
   - Design: "Describe the product and the feeling you want it to evoke"
   - Build: "Describe the feature or page you want to build"
   - Review: "What pages or components should be reviewed?"
   - Fix: "Describe the UI issue. What happens vs. what should happen?"
   - Audit: "Which pages are launch-critical?"

4. **Tech Stack:** (if not already known from the project)
   - React + Next.js + Tailwind (default for most projects)
   - Other: specify framework, CSS approach, component library

5. **Team Composition:** Which specialists do you need?
   - **Full team** (Visual Designer + Component Architect + Performance Reviewer + UX Reviewer): recommended for Design and Audit
   - **Build team** (Component Architect + UX Reviewer): recommended for Build
   - **Review team** (Performance Reviewer + UX Reviewer): recommended for Review
   - **Minimal** (one specialist): recommended for Fix
   - **Custom**: pick specific roles

   The lead is always included. Map the answer to a `roster` of agent names: `ui-visual-designer`, `ui-component-architect`, `ui-performance-reviewer`, `ui-ux-reviewer`.

6. **Iterate (Design and Build only):** If the UX gate comes back CONDITIONAL or FAIL, should the team fix the findings and re-review automatically (up to 2 cycles)? This sets `iterate`.

## Pre-Survey

If the project path exists, run this before starting the workflow:

```bash
cd {PROJECT_PATH} && echo "=== Recent Commits ===" && git log -5 --oneline 2>/dev/null && echo "=== Source Structure ===" && ls -1 src/ 2>/dev/null && echo "=== Component Count ===" && find src -name "*.tsx" -o -name "*.jsx" 2>/dev/null | wc -l && echo "=== Design Tokens ===" && (cat tailwind.config.ts 2>/dev/null || cat tailwind.config.js 2>/dev/null || echo "No tailwind config found") | head -30 && echo "=== Client Components ===" && grep -rl '"use client"' src/ 2>/dev/null | wc -l && echo "=== Global Styles ===" && ls src/app/globals.css src/styles/ 2>/dev/null
```

## Available Tooling

- **Playwright MCP**: configured per project. When it's available, the UX Reviewer uses it. Otherwise the reviewer falls back to headless Chrome screenshots at each viewport, plus code inspection for keyboard and state checks.
- **Context7**: Current API documentation for React, Next.js, Tailwind, and other frameworks.

## Knowledge Base

The following shared data files are available to all agents:
- `~/.claude/skills/ui-ux/data/design-rules.md`: 35 non-negotiable design rules
- `~/.claude/skills/ui-ux/data/perceptual-defaults.md`: Research-backed typography, color, spacing, motion values
- `~/.claude/skills/ui-ux/data/scaffold-templates.md`: 9 common layout patterns (dashboard, list, detail, marketing, modal, wizard, mobile, form, empty state)
- `~/.claude/skills/ui-ux/data/react-performance.md`: Priority-tiered React/Next.js performance rules (4 tiers, 20+ rules)

## Orchestration

1. **Working directory:** workflow agents write into the project. If it isn't the session's working directory, ask the user to run `/add-dir <project-path>` first.
2. Run the workflow. This skill's instructions are the opt-in for this one saved workflow.
   ```
   Workflow({ name: "team-pipeline", args: {
     team: "uiux", mode: "design" | "build" | "review" | "fix" | "audit",
     projectPath: "<abs path>", stack: "<tech stack>", scope: "<user's scope text>",
     roster: ["ui-component-architect", ...], survey: "<pre-survey output>", iterate: <bool>
   }})
   ```
3. The workflow runs in the background. **End the turn and wait for the completion notification.**

**Stages by mode:**
- **design:**
  - `ui-ux-lead` brief
  - visual designer, then component architect, in sequence
  - review: performance and UX in parallel
  - gate loop, only when `iterate` is on
- **build:**
  - brief
  - parallel implementation (the visual designer only when new tokens are needed)
  - integrate (build and test, failures routed to their owners)
  - review
  - gate loop
- **review:** performance and UX reviewers in parallel, then lead synthesis.
- **fix:** lead triage, then the owning specialist, then UX reviewer verification.
- **audit:** all four specialists audit in parallel (read-only), then lead synthesis (launch-blocking vs post-launch).

## After the Workflow Completes

1. Display the summary and `quality`: heuristic and TASTE averages, design rules passed out of 35, and the gate.
2. Show the brief or synthesis, the files created and modified, and each specialist's report.
3. Put each entry in `decisions_needed` to the user. If the gate isn't PASS and iterate was off, offer a fix run.
4. List the recommended next steps, then ask whether the user wants to commit.

## Integration with Other Skills

This skill's agents can be invoked by other orchestrators:

- **team-pipeline (game)**: game-ux follows the same viewport QA method; `ui-ux-reviewer` can also be spawned directly on a game UI
- **blog-pipeline** (workflow behind /blog-post): its cover and diagram stages follow the same design rules via `docs/cover-graphics-standards.md` and `docs/editorial-diagram-standards.md`
- **Any agent**: Can reference `~/.claude/skills/ui-ux/data/` for design rules and patterns

## Ad-Hoc Agent Usage

Individual agents can be spawned directly without the full skill workflow:

```
# Registered agent types: spawn by subagent_type, never with a name
Agent(subagent_type="ui-visual-designer", prompt="Review the color system in this project")
Agent(subagent_type="ui-component-architect", prompt="Audit the component structure in src/components/")
Agent(subagent_type="ui-performance-reviewer", prompt="Run a performance audit on this Next.js app")
Agent(subagent_type="ui-ux-reviewer", prompt="Run viewport QA on http://localhost:3000")
```
