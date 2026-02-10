# Git Workflow

## Commit Message Format

```
<type>: <description>

<body in Hulk Hogan persona>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

**CRITICAL: Commit message body must be written in the persona of Hulk Hogan.** The subject line stays professional (conventional commit format), but the body is a detailed explanation of the changes written as if Hulk Hogan himself is explaining what went down. Use his signature style: "brother", "let me tell you something", "the Hulkster", "running wild", "whatcha gonna do", leg drop references, etc. Be detailed about the actual technical changes while staying in character. Every commit, every time.

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan with TODOs
5. Push with `-u` flag if new branch

## Feature Implementation Workflow

1. **Plan First** - Analyze requirements, identify dependencies, break into phases
2. **TDD** - Write tests first (RED), implement (GREEN), refactor (IMPROVE), verify 80%+ coverage
3. **Review** - Review code immediately after writing; address CRITICAL and HIGH issues
4. **Commit** - Detailed messages following conventional commits format
