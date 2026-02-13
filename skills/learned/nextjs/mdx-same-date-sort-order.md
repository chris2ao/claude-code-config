# MDX Same-Date Sort Order Non-Determinism

**Extracted:** 2026-02-07
**Context:** File-based MDX blog systems (Next.js, Astro, etc.) where posts are sorted by date string parsed with `new Date()`

## Problem

When multiple MDX blog posts share the same date (e.g., `"2026-02-07"`), sorting by `new Date(date).getTime()` produces identical timestamps. The resulting sort order depends on `fs.readdirSync()` which is platform-dependent and not guaranteed. Posts may appear in different orders across builds, operating systems, or file system states.

This is common when you publish several posts in one day. The blog listing page shows posts in an unpredictable order.

## Solution

Add ISO timestamps to the date field in frontmatter to differentiate posts published on the same day:

```yaml
# Instead of:
date: "2026-02-07"

# Use:
date: "2026-02-07T08:00:00"
```

The sort function (`new Date(b.date).getTime() - new Date(a.date).getTime()`) works identically - no code changes needed. The timestamps just need to be different from each other to break the tie.

If the blog UI formats dates with `toLocaleDateString()` or similar, the time portion is ignored in display - readers still see "February 7, 2026".

## When to Use

- Multiple blog posts share the same date string
- Blog listing shows posts in unexpected/changing order
- File-based MDX blog with date-descending sort
- Any static site generator that sorts content by date
