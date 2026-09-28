---
platform: portable
description: "Game development workflow: create, fix, debug, or enhance games with a coordinated team of specialists"
---

# /game-dev - Game Development Studio

Runs a team of game development specialists to create, fix, debug, or enhance games. This skill runs in the main conversation: it gathers inputs, calls the saved workflow `~/.claude/workflows/team-pipeline.js` (team `game`), and handles decisions and commits. There is no director agent anymore. The `game-architect` agent holds the architecture, triage, investigation, and integration judgment, and the workflow script does the orchestration.

## User Discovery

Ask the user these questions (use AskUserQuestion, one at a time):

1. **Project:** Which game project are you working on?
   - Provide the project name and path (e.g., `~/GitProjects/Third-Conflict`)
   - If creating a new game, ask for the desired project name and location

2. **Mode:** What do you need help with?
   - **Create** - Build a new game from scratch
   - **Fix** - Something is broken and needs to be fixed
   - **Debug** - Investigate unexpected behavior
   - **Add** - Add a new feature or enhancement

3. **Engine/Framework:** What tech stack are you using (or want to use)?
   - Next.js + Canvas 2D + Zustand (established pattern for web games)
   - Phaser 3
   - PixiJS
   - Three.js / WebGL
   - Godot (GDScript)
   - Unity (C#)
   - Custom / Other (describe)

4. **Scope:** What specifically do you need? (adapt to mode)
   - Create: "Describe the game concept in 2-3 sentences"
   - Fix: "Describe the bug. What happens vs. what should happen?"
   - Debug: "What behavior are you investigating?"
   - Add: "Describe the feature you want to add"

5. **Team Composition:** Which specialists do you need? The architect is always included.
   - **Full team** (Designer + Artist + UX + Developer + Writer): recommended for Create
   - **Core team** (Designer + Developer): recommended for Add
   - **Dev team** (Developer + Artist): good for visual and audio features and fixes
   - **UX team** (Developer + UX): good for UI, responsive, and mobile fixes
   - **Minimal** (Developer): recommended for Debug and small fixes
   - **Custom**: pick specific roles from Designer, Artist/Audio, UX/UI, Developer, Writer

   Map the answer to a `roster` of agent names: `game-designer`, `game-artist`, `game-ux`, `game-developer`, `game-writer`.

## Pre-Survey

If the project path exists, run this before starting the workflow:

```bash
cd {PROJECT_PATH} && echo "=== Recent Commits ===" && git log -5 --oneline 2>/dev/null && echo "=== Changed Files ===" && git diff --stat 2>/dev/null && echo "=== Source File Count ===" && find src -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.gd" -o -name "*.cs" \) 2>/dev/null | wc -l && echo "=== Project Structure ===" && ls -1 src/ 2>/dev/null
```

## Available Tooling

- **Playwright MCP**: configured per project (Cann-Cann has it). When it's available, game-ux uses it for viewport QA. Otherwise game-ux falls back to headless Chrome screenshots plus code inspection for keyboard and aria checks.
- **Context7**: Current API documentation for frameworks (React, Next.js, Tailwind, etc.)

## Orchestration

1. **Working directory:** workflow agents write into the game project. If the project isn't the session's working directory, ask the user to run `/add-dir <project-path>` first, or restart the session from the project directory, so agents don't stall on permission prompts.
2. Run the workflow. This skill's instructions are the opt-in for this one saved workflow.
   ```
   Workflow({ name: "team-pipeline", args: {
     team: "game", mode: "create" | "add" | "fix" | "debug",
     projectPath: "<abs path>", stack: "<framework>", scope: "<user's scope text>",
     roster: ["game-developer", ...], survey: "<pre-survey output>"
   }})
   ```
3. The workflow runs in the background. **End the turn and wait for the completion notification.** The user can watch progress with `/workflows`.

**Stages by mode:**
- **create and add:**
  - design spec (game-designer, plus game-writer for create)
  - `game-architect` MODE architect: skeleton and a disjoint file-ownership map
  - parallel implementation, each specialist in its owned paths
  - visual QA by game-ux at 4 viewports, when UX is on the roster (QA gate failures route back to their owners once)
  - integrate: build and test, with failures routed back to their owners, for up to 3 rounds
- **fix:** `game-architect` MODE triage, then the assigned specialists, then integrate.
- **debug:** `game-architect` MODE investigate only. It changes no code.

## After the Workflow Completes

The result includes `status` (`ready` or `needs-attention`), the plan (architecture and ownership, or triage), per-specialist `reports`, `tests` (passed, failed, coverage, build_pass), `files_created`, `files_modified`, and `decisions_needed`.

1. Display the summary and each specialist's report.
2. Show the files created and modified, and the test results.
3. Put each entry in `decisions_needed` to the user with AskUserQuestion (for example, a design conflict or failures no roster member owns).
4. Offer the next step. Iterating means a new run in fix or add mode with a revised scope, which is how play-testing loops work.
5. Ask whether the user wants to commit the changes.
6. For debug mode, present the investigation and offer a follow-up fix run.
