# Perceptual Defaults

Research-backed values for typography, color, motion, and spacing. Use these as starting points, then adjust for context. Sources: Baymard Institute, Nielsen Norman Group, Material Design 3, Apple HIG.

## Typography Scale

| Role | Size | Weight | Line Height | Letter Spacing | Use Case |
|------|------|--------|-------------|---------------|----------|
| Display | 56-72px | 700-800 | 1.1 | -0.03em | Hero headlines |
| H1 | 36-48px | 700 | 1.2 | -0.02em | Page titles |
| H2 | 28-32px | 600-700 | 1.25 | -0.01em | Section headers |
| H3 | 22-24px | 600 | 1.3 | 0 | Subsection headers |
| H4 | 18-20px | 600 | 1.35 | 0 | Minor headers |
| Body Large | 18px | 400 | 1.6 | 0 | Long-form reading |
| Body | 16px | 400 | 1.5 | 0 | Default body text |
| Body Small | 14px | 400 | 1.5 | 0.01em | Secondary text, captions |
| Caption | 12px | 400 | 1.4 | 0.02em | Labels, metadata |
| Overline | 11-12px | 600 | 1.4 | 0.08em | Category labels, tags |

## Color Perception

| Property | Value | Notes |
|----------|-------|-------|
| Disabled opacity | 40% | Clearly disabled without invisible |
| Hover overlay | 8% opacity | Subtle but detectable |
| Active/pressed overlay | 12% opacity | Noticeably darker than hover |
| Focus ring | 2-3px, offset 2px | Visible without obscuring content |
| Shadow opacity (light mode) | 5-15% | Heavier shadows feel dated |
| Shadow opacity (dark mode) | 20-40% | Dark backgrounds need stronger shadows |
| Skeleton loading | 5-10% contrast from background | Subtle pulse, not jarring flash |
| Text on images | Use overlay (40-60% black) or text-shadow | Never place text directly on busy images |

## Motion Timing

| Category | Duration | Easing | Examples |
|----------|----------|--------|----------|
| Micro feedback | 100-150ms | ease-out | Button press, toggle, checkbox |
| State change | 200-300ms | ease-in-out | Dropdown open, tab switch, accordion |
| Entrance | 300-400ms | ease-out | Modal appear, page section reveal |
| Exit | 200-250ms | ease-in | Modal dismiss, toast disappear |
| Page transition | 300-500ms | ease-in-out | Route change, view transition |
| Loading indicator | 1000-1500ms loop | linear | Spinner, progress bar pulse |
| Stagger delay | 50-100ms per item | ease-out | List items appearing sequentially |

**Critical rule:** Exits are faster than entrances. Users want to dismiss things quickly.

## Spacing Scale (8px Grid)

| Token | Value | Use Case |
|-------|-------|----------|
| xs | 4px | Icon padding, tight gaps |
| sm | 8px | Inline element gaps, compact lists |
| md | 16px | Standard padding, card content |
| lg | 24px | Section padding, form field gaps |
| xl | 32px | Major section separation |
| 2xl | 48px | Page section margins |
| 3xl | 64px | Hero/feature section spacing |
| 4xl | 96px | Full-page section breaks |

## Touch and Interaction

| Property | Value | Source |
|----------|-------|--------|
| Touch target minimum | 44x44px | Apple HIG, WCAG 2.5.5 |
| Touch target spacing | 8px minimum between targets | Material Design 3 |
| Scroll snap threshold | 40px movement before snap | Common gesture libraries |
| Long press duration | 500ms | iOS/Android standard |
| Double-tap window | 300ms | Platform standard |
| Swipe velocity threshold | 0.5px/ms | Gesture recognition |

## Responsive Breakpoints

| Name | Width | Target |
|------|-------|--------|
| xs | 375px | Small phones (iPhone SE) |
| sm | 640px | Large phones |
| md | 768px | Tablets portrait |
| lg | 1024px | Tablets landscape, small laptops |
| xl | 1280px | Desktops |
| 2xl | 1536px | Large desktops |

**Container query equivalents:** Use `@container` with these same widths when components need to respond to their container rather than the viewport.

## Z-Index Scale

| Layer | Value | Use Case |
|-------|-------|----------|
| Base | 0 | Default content |
| Raised | 10 | Cards, elevated surfaces |
| Dropdown | 20 | Menus, selects, popovers |
| Sticky | 30 | Sticky headers, navigation |
| Overlay | 40 | Backdrop, dim layer |
| Modal | 50 | Dialogs, sheets |
| Toast | 60 | Notifications, snackbars |
| Tooltip | 70 | Tooltips, hover cards |
| Maximum | 9999 | Dev tools, debug overlays only |
