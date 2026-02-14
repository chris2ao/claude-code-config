# Slug Path Traversal Guard for File-Based Routing

**Extracted:** 2026-02-07
**Context:** Any function that takes a URL slug parameter and uses it to construct a file path (e.g., `getPostBySlug`, `getPageBySlug`)

## Problem

When a slug from a URL parameter (like `/blog/[slug]`) is used directly in `path.join()` to read a file, a crafted slug like `../../etc/passwd` or `..\..\..\windows\system32\config\sam` can escape the intended directory.

```typescript
// Vulnerable:
export function getPostBySlug(slug: string) {
  const filePath = path.join(contentDir, `${slug}.mdx`);
  const content = fs.readFileSync(filePath, "utf8"); // reads arbitrary files
}
```

Even in SSG (static site generation) where `generateStaticParams` pre-builds known slugs, the function itself is still callable. If the site ever moves to SSR or the function is reused elsewhere, the vulnerability becomes exploitable.

## Solution

Reject slugs containing path separators or parent directory references before constructing the path:

```typescript
export function getPostBySlug(slug: string): BlogPost | undefined {
  if (slug.includes('/') || slug.includes('\\') || slug.includes('..')) {
    return undefined;
  }
  const filePath = path.join(contentDir, `${slug}.mdx`);
  if (!fs.existsSync(filePath)) return undefined;
  // ... safe to read
}
```

This is a defense-in-depth measure. The check is cheap and protects against future refactoring that might expose the function to untrusted input.

## When to Use

- Any function that builds a file path from a URL parameter
- File-based content systems (MDX blogs, documentation sites)
- Dynamic route handlers (`[slug]`, `[id]`, `[...path]`)
- Even in SSG contexts, as a guard against future SSR migration
