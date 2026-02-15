---
description: "Quick dashboard showing git status across all project repos"
---

# /multi-repo-status - Repository Dashboard

Quick status overview of all 4 project repositories.

## Survey

!`bash ~/.claude/scripts/wrap-up-survey.sh`

## Display

Format the survey JSON as a status table:

| Repo | Branch | Clean? | Last Commit | Ahead/Behind |
|------|--------|--------|-------------|--------------|

For each repo in the JSON:
- Show branch name
- Show clean (true/false based on modified_files + untracked_files being empty)
- Show last_commit (truncated to 60 chars)
- Show commits_ahead/commits_behind

Also show session artifacts summary (transcript count, todo count, activity log lines).

Flag any repos that need push (commits_ahead > 0) or pull (commits_behind > 0).
