# Scaffold Templates

9 common layout patterns with recommended structure. Use as starting points when building new pages or views.

## 1. Dashboard

```
┌─────────────────────────────────────────┐
│  Sidebar (240-280px)  │  Main Content   │
│  ├── Logo             │  ┌── Header Bar │
│  ├── Navigation       │  │   Search/Filter│
│  ├── Quick Actions    │  ├── Metrics Row │
│  └── User Menu        │  │   (4 cards)   │
│                       │  ├── Chart Area  │
│                       │  │   (2 columns) │
│                       │  └── Table/List  │
└─────────────────────────────────────────┘
```

**Key decisions:**
- Sidebar: collapsible on tablet, drawer on mobile
- Metrics row: 4 cards (desktop), 2x2 grid (tablet), stacked (mobile)
- Charts: side-by-side (desktop), stacked (tablet/mobile)
- Table: horizontal scroll on mobile, or convert to card list
- Header height: 56-64px
- Sidebar width: 240px expanded, 64px collapsed

## 2. List View

```
┌─────────────────────────────────┐
│  Header + Breadcrumbs           │
│  ┌─── Toolbar ───────────────┐  │
│  │ Search │ Filters │ Actions│  │
│  └────────────────────────────┘  │
│  ┌─── List ──────────────────┐  │
│  │  Item Row (avatar, text,  │  │
│  │    metadata, actions)     │  │
│  │  ─────────────────────    │  │
│  │  Item Row                 │  │
│  │  ─────────────────────    │  │
│  │  Item Row                 │  │
│  └────────────────────────────┘  │
│  Pagination / Load More          │
└─────────────────────────────────┘
```

**Key decisions:**
- Row height: 56-72px for comfortable click targets
- Actions: inline on desktop, overflow menu on mobile
- Search: always visible, not hidden behind icon
- Filters: collapsible panel on mobile
- Empty state: illustration + message + primary action
- Loading: skeleton rows matching item layout

## 3. Detail View

```
┌─────────────────────────────────┐
│  Back Navigation                │
│  ┌─── Hero/Header ───────────┐  │
│  │  Title, Status, Actions   │  │
│  └────────────────────────────┘  │
│  ┌─── Tab Bar ───────────────┐  │
│  │ Overview │ History │ Config│  │
│  └────────────────────────────┘  │
│  ┌─── Content ───────────────┐  │
│  │  Main (2/3)  │ Sidebar    │  │
│  │  Properties  │ Related    │  │
│  │  Activity    │ Metadata   │  │
│  └────────────────────────────┘  │
└─────────────────────────────────┘
```

**Key decisions:**
- Sidebar collapses below main on mobile
- Tab bar: scrollable on mobile if 4+ tabs
- Actions: primary visible, secondary in overflow
- Back navigation: always present, preserves list state

## 4. Marketing / Landing Page

```
┌─────────────────────────────────┐
│  Navigation Bar (sticky)        │
│  ┌─── Hero ──────────────────┐  │
│  │  Headline (H1)            │  │
│  │  Subheadline              │  │
│  │  CTA Button(s)            │  │
│  │  Social Proof              │  │
│  └────────────────────────────┘  │
│  ┌─── Features ─────────────┐  │
│  │  3-4 column grid          │  │
│  └────────────────────────────┘  │
│  ┌─── Social Proof ─────────┐  │
│  │  Testimonials / Logos     │  │
│  └────────────────────────────┘  │
│  ┌─── CTA Section ──────────┐  │
│  │  Repeat primary CTA       │  │
│  └────────────────────────────┘  │
│  Footer                         │
└─────────────────────────────────┘
```

**Key decisions:**
- Hero: full viewport height or near it
- CTA: repeated at least twice (hero + bottom)
- Features: 3 columns desktop, stacked mobile
- Max content width: 1200-1400px
- Section padding: 64-96px vertical

## 5. Modal / Dialog

```
┌─── Backdrop (dim overlay) ──────┐
│                                  │
│   ┌─── Modal ─────────────┐     │
│   │  Header + Close Button │     │
│   │  ─────────────────     │     │
│   │  Content Area          │     │
│   │  (scrollable if long)  │     │
│   │  ─────────────────     │     │
│   │  Footer: Cancel + Save │     │
│   └────────────────────────┘     │
│                                  │
└──────────────────────────────────┘
```

**Key decisions:**
- Width: 480-640px (small), 720-960px (large)
- Mobile: full-screen sheet sliding up from bottom
- Close: X button + ESC key + backdrop click
- Focus trap: tab cycles within modal only
- Scroll: content area scrolls, header/footer fixed
- Entry: fade + scale-up (200ms), exit: fade (150ms)

## 6. Wizard / Multi-Step Form

```
┌─────────────────────────────────┐
│  Step Indicator (1 of 4)        │
│  ○────●────○────○               │
│  ┌─── Step Content ──────────┐  │
│  │                            │  │
│  │  Form fields for this step │  │
│  │                            │  │
│  └────────────────────────────┘  │
│  ┌─── Navigation ────────────┐  │
│  │  ← Back         Next →    │  │
│  └────────────────────────────┘  │
└─────────────────────────────────┘
```

**Key decisions:**
- Step indicator: horizontal (desktop), vertical or simplified (mobile)
- Validate per step, not at the end
- Back button never destroys entered data
- Final step shows summary before submit
- Max 5-7 steps (beyond that, reconsider the flow)

## 7. Mobile App Layout

```
┌─────────────────────┐
│  Status Bar          │
│  ┌── Header ──────┐  │
│  │  Title + Actions│  │
│  └─────────────────┘  │
│  ┌── Content ─────┐  │
│  │                 │  │
│  │  Scrollable     │  │
│  │  Content Area   │  │
│  │                 │  │
│  └─────────────────┘  │
│  ┌── Tab Bar ─────┐  │
│  │ 🏠  📋  ➕  👤 │  │
│  └─────────────────┘  │
└─────────────────────┘
```

**Key decisions:**
- Bottom tab bar: max 5 items
- Header height: 44px (iOS) / 56px (Android)
- Tab bar height: 49px (iOS) / 56px (Android)
- Safe area insets on all edges
- Pull-to-refresh on scrollable content
- FAB (floating action button) if primary action exists

## 8. Form Layout

```
┌─────────────────────────────────┐
│  Form Title                     │
│  Description text               │
│  ┌─── Form Fields ──────────┐  │
│  │  Label                    │  │
│  │  [Input Field           ] │  │
│  │  Helper text              │  │
│  │                           │  │
│  │  Label                    │  │
│  │  [Input Field           ] │  │
│  │  Error message (if any)   │  │
│  │                           │  │
│  │  Label                    │  │
│  │  [Select ▼              ] │  │
│  └────────────────────────────┘  │
│  ┌─── Actions ───────────────┐  │
│  │  Cancel          Submit   │  │
│  └────────────────────────────┘  │
└─────────────────────────────────┘
```

**Key decisions:**
- Single column for most forms (multi-column only for related short fields like City/State/Zip)
- Labels above inputs (not placeholder-only, not inline)
- Max width: 560-640px for single-column forms
- Error messages below the field, not in tooltips
- Required indicator: asterisk (*) on label
- Group related fields with fieldset + legend
- Submit button right-aligned or full-width on mobile

## 9. Empty State

```
┌─────────────────────────────────┐
│                                  │
│         ┌──────────┐            │
│         │          │            │
│         │  Visual  │            │
│         │          │            │
│         └──────────┘            │
│                                  │
│      Primary Message             │
│      Secondary explanation       │
│                                  │
│      [ Primary Action ]          │
│      Secondary action link       │
│                                  │
└─────────────────────────────────┘
```

**Key decisions:**
- Centered vertically and horizontally
- Visual: illustration, icon, or subtle graphic (not a sad face)
- Primary message: what happened or what's missing
- Secondary: what to do about it
- Always include at least one action
- Match the visual tone of the product (playful app = playful empty state)
