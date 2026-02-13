# Next.js Client Component Metadata Workaround

**Extracted:** 2026-02-07
**Context:** Next.js App Router pages that need both `"use client"` (for interactivity) and `export const metadata` (for SEO)

## Problem

In Next.js 15+ App Router, you cannot export `metadata` from a client component. If a page uses `"use client"` (e.g., for `useState`, `useEffect`, form handling), adding `export const metadata` causes a build error or is silently ignored.

This is a common issue for pages like Contact (form state) or any interactive page that also needs SEO metadata.

## Solution

Create a separate `layout.tsx` in the same route folder that acts as a server component wrapper. The layout exports the metadata; the page handles the interactivity.

```
app/contact/
  layout.tsx   # Server component — exports metadata
  page.tsx     # Client component — uses useState, etc.
```

**layout.tsx** (server component):

```tsx
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Contact",
  description: "Get in touch.",
};

export default function ContactLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
```

**page.tsx** (client component):

```tsx
"use client";
import { useState } from "react";

export default function ContactPage() {
  const [submitted, setSubmitted] = useState(false);
  // ... interactive form
}
```

The layout is a passthrough — it does nothing except provide metadata. Next.js renders the layout (server) wrapping the page (client), and both metadata and interactivity work.

## When to Use

- A page needs `"use client"` AND SEO metadata (`title`, `description`, Open Graph)
- Build errors or missing metadata on client component pages
- Any App Router page that combines interactivity with SEO requirements
