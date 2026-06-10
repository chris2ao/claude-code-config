---
platform: portable
---

# MDX Frontmatter: Prose Values with `: ` Break YAML Parsing

**Extracted:** 2026-06-10
**Context:** Writing or editing `.mdx` blog post frontmatter (cryptoflexllc.com or any gray-matter-based blog)

## Problem

A frontmatter field whose unquoted value contains `: ` (colon-space) sequences causes gray-matter to throw `incomplete explicit mapping pair` and the post page renders broken or blank.

```yaml
# BROKEN: gray-matter misreads each ": " as a new key
coverImageAlt: Bug 1: readonly-pool 500. Bug 2: poll crash loop. Meta-lesson: one SELECT count()
```

YAML treats `: ` as a key-value separator. Any prose, caption, or alt-text field that names multiple items (`Bug 1: ...`, `Closes with the meta-lesson: ...`) silently corrupts the frontmatter parse.

## Why `npm run build` Doesn't Catch It

If the route declaring the post uses `export const dynamic = "force-dynamic"` (common in `/backlog/[slug]/page.tsx`), the build skips per-request rendering and reports "Compiled successfully" even with broken frontmatter. The error only surfaces at runtime when the page is actually requested.

## Fix

Use a YAML folded scalar (`>-`) for any long prose value or any value that might contain colon-space:

```yaml
# CORRECT: folded scalar, any ": " inside is treated as literal text
coverImageAlt: >-
  Bug 1: readonly-pool 500 error on read-only DB pool.
  Bug 2: poll crash loop from tz-naive datetime subtraction.
  Meta-lesson: one SELECT count() per time window, not N.
```

The `>-` form folds newlines into spaces and strips the trailing newline. Semantically identical to a long inline string for the consuming component.

## When to Apply

- `coverImageAlt`, `description`, `excerpt`, or any prose field with `: ` in the value
- Blog post captions that enumerate numbered items ("Step 1: ..., Step 2: ...")
- Any frontmatter written by an LLM that generates prose values without YAML awareness

## Evidence

Session aa78a3bf (2026-05-29): "The `coverImageAlt` value in the LOG LAKE frontmatter was an unquoted YAML scalar containing multiple `: ` (colon-space) sequences... YAML treats `: ` as a key separator. gray-matter threw `incomplete explicit mapping pair` at line 35 col 401."
