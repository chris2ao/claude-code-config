# Git Workflow

## Commit Message Format

```
<type>: <description>

<body>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

**Commit message body must be factual and concise.** The subject line follows conventional commit format. The body provides a clear, factual explanation of what changed and why. Focus on the technical details: what was added, modified, or removed, and the reasoning behind the change. No personas, no flair, just the facts.

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
