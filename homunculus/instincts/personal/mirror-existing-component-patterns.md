---
id: mirror-existing-component-patterns
trigger: "when adding a new panel/card/table to an existing dashboard"
confidence: 0.7
domain: "frontend"
source: "session-observation"
created: "2026-02-15"
---

# Mirror Existing Component Patterns

## Action
When adding a new component to an existing dashboard, find the most similar existing component and mirror its structure exactly: same prop pattern, same styling classes, same table layout, same delete/action button pattern, same empty state messaging. Only deviate where the new component's data model requires it.

## Pattern
1. Identify the closest existing component (same section, similar data shape)
2. Copy its structure: header with badge, table with same class names, action buttons with same icon/loader pattern
3. Match the delete flow: confirm dialog, optimistic removal, same fetch pattern
4. Add only the new features needed (e.g., search bar, reaction icons)

## Evidence
- 2026-02-15: Built `comments-panel.tsx` by mirroring `subscriber-panel.tsx`. Same table structure, same Trash2/Loader2 delete button pattern, same empty state. Added search bar and reaction icons as comment-specific additions. Resulted in visually consistent dashboard with minimal code divergence.
