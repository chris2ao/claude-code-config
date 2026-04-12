---
platform: portable
description: "UI/UX design and quality system: aesthetic direction, component architecture, performance, and visual QA with a coordinated agent team"
---

# /ui-ux - UI/UX Design Studio

Orchestrates a team of UI/UX specialists to design, build, review, or audit frontend interfaces. Covers aesthetic direction, component architecture, performance optimization, and visual quality assurance.

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
   - **Full team** (Director + Visual Designer + Component Architect + Performance Reviewer + UX Reviewer) - recommended for Design and Audit
   - **Build team** (Director + Component Architect + UX Reviewer) - recommended for Build
   - **Review team** (Director + Performance Reviewer + UX Reviewer) - recommended for Review
   - **Minimal** (Director + one specialist) - recommended for Fix
   - **Custom** - pick specific roles

## Pre-Survey

If the project path exists, run this before spawning the director:

```bash
cd {PROJECT_PATH} && echo "=== Recent Commits ===" && git log -5 --oneline 2>/dev/null && echo "=== Source Structure ===" && ls -1 src/ 2>/dev/null && echo "=== Component Count ===" && find src -name "*.tsx" -o -name "*.jsx" 2>/dev/null | wc -l && echo "=== Design Tokens ===" && (cat tailwind.config.ts 2>/dev/null || cat tailwind.config.js 2>/dev/null || echo "No tailwind config found") | head -30 && echo "=== Client Components ===" && grep -rl '"use client"' src/ 2>/dev/null | wc -l && echo "=== Global Styles ===" && ls src/app/globals.css src/styles/ 2>/dev/null
```

## Available Tooling

- **Playwright MCP**: Browser automation for responsive testing, visual QA, and interactive state validation. The UX Reviewer uses this for screenshot-based quality checks at multiple viewports.
- **Context7**: Current API documentation for React, Next.js, Tailwind, and other frameworks.

## Knowledge Base

The following shared data files are available to all agents:
- `~/.claude/skills/ui-ux/data/design-rules.md`: 35 non-negotiable design rules
- `~/.claude/skills/ui-ux/data/perceptual-defaults.md`: Research-backed typography, color, spacing, motion values
- `~/.claude/skills/ui-ux/data/scaffold-templates.md`: 9 common layout patterns (dashboard, list, detail, marketing, modal, wizard, mobile, form, empty state)
- `~/.claude/skills/ui-ux/data/react-performance.md`: Priority-tiered React/Next.js performance rules (4 tiers, 20+ rules)

## Orchestration

After gathering answers and pre-survey data, spawn a Task agent:
- **subagent_type:** general-purpose
- **model:** sonnet
- **name:** ui-ux-director

Pass to the agent:
1. Pre-survey output (if available)
2. All user answers (project, mode, scope, tech stack, team composition)
3. The project path as the working directory
4. Instruction: "You are the UI/UX Director. Follow the instructions in ~/.claude/agents/ui-ux-director.md"
5. Include which team members to activate based on the user's team composition choice

## After Agent Returns

The director returns a structured report with phases completed, design decisions, files created/modified, quality scores, team reports, and next steps.

1. Display the summary and quality scores
2. Show design decisions and rationale
3. List files created and modified
4. If quality scores are available, display the heuristic and TASTE averages
5. Show the UX Review gate decision (PASS/CONDITIONAL/FAIL)
6. List recommended next steps
7. Ask if the user wants to commit the changes

## Integration with Other Skills

This skill's agents can be invoked by other orchestrators:

- **game-director**: Can spawn `ui-ux-reviewer.md` for Playwright QA on game UI
- **blog-captain**: Can spawn `ui-visual-designer.md` for blog design decisions
- **Any agent**: Can reference `~/.claude/skills/ui-ux/data/` for design rules and patterns

## Ad-Hoc Agent Usage

Individual agents can be spawned directly without the full skill workflow:

```
# Quick design system review
Agent: ui-visual-designer.md - "Review the color system in this project"

# Component architecture audit
Agent: ui-component-architect.md - "Audit the component structure in src/components/"

# Performance check
Agent: ui-performance-reviewer.md - "Run a performance audit on this Next.js app"

# Full QA pass
Agent: ui-ux-reviewer.md - "Run Playwright QA on http://localhost:3000"
```
