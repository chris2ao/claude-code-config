---
id: deep-link-admin-to-public
trigger: "when building admin/moderation panels that reference public-facing content"
confidence: 0.5
domain: "frontend"
source: "session-observation"
created: "2026-02-15"
---

# Deep-Link Admin Panels to Public Content

## Action
When building admin or moderation views that display items visible on public pages (comments, posts, reviews), make the item a hyperlink to the actual public URL. If the public component lacks anchor IDs for fragment navigation, add `id` attributes first so `#fragment` links resolve correctly.

## Pattern
1. Check if the public-facing component has `id` attributes on individual items
2. If not, add `id="item-type-{id}"` (e.g., `id="comment-{id}"`)
3. In the admin panel, render the item text as an `<a>` linking to `https://domain/path#item-type-{id}`
4. Open in new tab (`target="_blank" rel="noopener noreferrer"`) so the admin doesn't lose their place

## Evidence
- 2026-02-15: Built comments moderation panel in analytics dashboard. Initially rendered comment text as plain text. User requested it link to the actual comment on the production blog post. Required adding `id="comment-{id}"` anchors to `blog-comments.tsx` before the deep links could work.
