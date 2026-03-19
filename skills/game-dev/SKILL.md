---
platform: portable
description: "Game development workflow: create, fix, debug, or enhance games with a coordinated team of specialists"
---

# /game-dev - Game Development Studio

Orchestrates a team of game development specialists to create, fix, debug, or enhance games.

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

5. **Team Composition:** Which specialists do you need?
   - **Full team** (Director + Designer + Artist + UX + Developer + Writer) - recommended for Create
   - **Core team** (Director + Designer + Developer) - recommended for Add
   - **Dev team** (Director + Developer + Artist) - good for visual features and fixes
   - **Minimal** (Director + Developer) - recommended for Debug and small fixes
   - **Custom** - pick specific roles from: Designer, Artist, UX/UI, Developer, Writer

## Pre-Survey

If the project path exists, run this before spawning the director:

```bash
cd {PROJECT_PATH} && echo "=== Recent Commits ===" && git log -5 --oneline 2>/dev/null && echo "=== Changed Files ===" && git diff --stat 2>/dev/null && echo "=== Source File Count ===" && find src -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.gd" -o -name "*.cs" \) 2>/dev/null | wc -l && echo "=== Project Structure ===" && ls -1 src/ 2>/dev/null
```

## Orchestration

After gathering answers and pre-survey data, spawn a Task agent:
- **subagent_type:** general-purpose
- **model:** sonnet
- **name:** game-director

Pass to the agent:
1. Pre-survey output (if available)
2. All user answers (project, mode, framework, scope, team composition)
3. The project path as the working directory
4. Instruction: "You are the Senior Game Director. Follow the instructions in ~/.claude/agents/game-director.md"
5. Include which team members to activate based on the user's team composition choice

## After Agent Returns

The director returns a structured report with phases completed, files created/modified, test results, team reports, and next steps.

1. Display the summary and individual team member reports
2. Show files created and modified
3. If tests were run, show pass/fail counts
4. List recommended next steps
5. Ask if the user wants to commit the changes
