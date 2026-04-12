# Design Rules

Non-negotiable rules enforced across all UI/UX work. Violations must be fixed before delivery.

## Color and Visual

1. **No pure black.** Use `#111111` or darker grays, never `#000000` for text or backgrounds. Pure black creates harsh contrast and feels artificial.
2. **No zero border-radius.** Minimum 4px on interactive elements. Sharp corners feel aggressive and dated.
3. **Minimum contrast 4.5:1** for normal text, 3:1 for large text (18px+) and UI elements. Test every text/background combination.
4. **No hardcoded colors.** All colors must use CSS custom properties or design tokens. No inline hex values in production components.
5. **Semantic color naming.** Use `primary`, `error`, `success`, `muted`, not `blue-500` or `red-400`. Colors describe purpose, not appearance.
6. **Dark mode parity.** If dark mode exists, it gets equal design attention. Not just inverted colors, but considered contrast, shadows, and emphasis.
7. **Disabled state opacity is 40%**, not 50%. Research-backed: 40% reads as clearly disabled without being invisible.

## Typography

8. **Avoid generic fonts.** Inter, Roboto, Arial, and system defaults are acceptable for apps but actively discouraged for marketing, landing pages, and portfolio work. Choose fonts with character.
9. **Minimum 16px body text.** 14px is acceptable only for secondary/caption text. HUD and dashboard elements may use 12px minimum.
10. **Line height 1.5 for body text.** Tighter (1.2-1.3) for headings, looser (1.6-1.7) for long-form reading.
11. **Letter-spacing -0.03em for display text (40px+).** Large text needs tighter tracking to look balanced.
12. **Maximum 2 font families per project.** One for headings, one for body. A monospace for code is the only exception.

## Layout and Spacing

13. **Touch targets minimum 44x44px** on all interactive elements. This applies to mobile, tablet, and any touch-capable device.
14. **8px spacing grid.** All spacing values should be multiples of 4 or 8: 4, 8, 12, 16, 24, 32, 48, 64, 96.
15. **Mobile-first responsive.** Start with the smallest viewport, enhance upward. Never desktop-down.
16. **No horizontal scroll on any viewport.** If content overflows horizontally, the layout is broken.
17. **Safe area insets** on mobile: `env(safe-area-inset-bottom)` padding for notched devices.
18. **Container queries for components.** Use media queries for page-level decisions only. Components should respond to their container, not the viewport.

## Interaction and States

19. **All 8 states implemented** for interactive elements: default, hover, focus, active, disabled, loading, error, empty. Missing states are bugs.
20. **Visible focus indicators.** Minimum 2px outline or equivalent visual change on `:focus-visible`. Never `outline: none` without a replacement.
21. **Keyboard navigation for all interactive elements.** Tab order must be logical. No keyboard traps.
22. **Animation only on `transform` and `opacity`.** These are GPU-accelerated. Never animate width, height, top, left, margin, padding.
23. **Animation duration 150-300ms** for micro-interactions. 300-500ms for transitions. Never exceed 500ms for UI feedback.
24. **Respect `prefers-reduced-motion`.** Disable animations, reduce motion, skip haptics when this preference is active.

## Code Quality

25. **Design tokens required.** All colors, spacing, typography, shadows, border-radius, and z-index values must come from a token system (CSS custom properties, Tailwind theme, or tokens.json).
26. **No `!important` in production CSS.** It breaks specificity and makes overrides impossible.
27. **No ID selectors for styling.** Classes only. IDs are for JS hooks and anchors.
28. **Maximum 2 levels of CSS nesting.** Deeper nesting indicates a specificity problem.
29. **No arbitrary Tailwind values in production.** `bg-[#abc123]` means a missing design token. Add it to the theme.
30. **No inline styles in production components.** All styling goes through the design system.

## Anti-Patterns (AI Slop Detection)

31. **If it looks like AI made it, it fails.** Generic purple-on-white gradients, perfectly symmetrical layouts, stock photo aesthetics, and cookie-cutter card grids all signal AI generation.
32. **No default shadows everywhere.** Shadows should create hierarchy, not decorate. Most elements need no shadow.
33. **No gratuitous animations.** Every animation must serve a purpose: guide attention, show state change, or provide feedback. Decorative animation is noise.
34. **No component soup.** A page full of equally-weighted cards with no visual hierarchy is a layout failure. Create clear reading paths.
35. **Production-ready delivery.** No placeholder text, no TODO comments, no lorem ipsum, no missing images. If it ships, it works.
