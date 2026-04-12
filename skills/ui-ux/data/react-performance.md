# React/Next.js Performance Rules

Priority-tiered performance rules for React and Next.js applications. Rules are ranked by real-world impact. Sources: Vercel agent-skills, Next.js documentation, React core team guidance.

## Tier 1: CRITICAL (Fix These First)

### Eliminating Waterfalls

**W1. Check cheap conditions before expensive operations.**
```tsx
// Bad: always fetches, then checks
const data = await fetchExpensiveData();
if (!user.hasPermission) return null;

// Good: check first, fetch only if needed
if (!user.hasPermission) return null;
const data = await fetchExpensiveData();
```

**W2. Parallel data fetching with Promise.all.**
```tsx
// Bad: sequential waterfalls
const user = await getUser(id);
const posts = await getPosts(id);
const comments = await getComments(id);

// Good: parallel fetching
const [user, posts, comments] = await Promise.all([
  getUser(id),
  getPosts(id),
  getComments(id),
]);
```

**W3. Use Suspense boundaries to stream independent sections.**
```tsx
export default async function Page() {
  return (
    <>
      <Header />  {/* renders immediately */}
      <Suspense fallback={<MetricsSkeleton />}>
        <MetricsRow />  {/* streams when ready */}
      </Suspense>
      <Suspense fallback={<TableSkeleton />}>
        <DataTable />  {/* streams independently */}
      </Suspense>
    </>
  );
}
```

**W4. Defer non-critical awaits.**
If a promise result is not needed for initial render, defer it with `React.use()` or pass it as a prop to a Suspense-wrapped child.

### Bundle Size Optimization

**B1. Direct imports, not barrel files.**
```tsx
// Bad: imports entire library through barrel
import { Button, Input } from '@/components';

// Good: direct path imports
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
```

**B2. Dynamic imports for heavy components.**
```tsx
// Bad: always loaded
import { HeavyChart } from '@/components/Chart';

// Good: loaded on demand
const HeavyChart = dynamic(() => import('@/components/Chart'), {
  loading: () => <ChartSkeleton />,
});
```

**B3. Defer third-party scripts.**
```tsx
// Bad: blocks page load
<Script src="https://analytics.example.com/script.js" />

// Good: loads after page is interactive
<Script src="https://analytics.example.com/script.js" strategy="lazyOnload" />
```

**B4. Preload on hover for navigation.**
```tsx
// Preload route data when user hovers a link
<Link href="/dashboard" prefetch={true}>Dashboard</Link>
```

## Tier 2: HIGH (Address After Critical)

### Server-Side Performance

**S1. Default to Server Components.** Only add `"use client"` when the component needs state, effects, event handlers, or browser APIs. 80-90% of components should be Server Components.

**S2. Use `React.cache()` for request deduplication.**
```tsx
const getUser = React.cache(async (id: string) => {
  return db.user.findUnique({ where: { id } });
});
// Called in multiple server components, only executes once per request
```

**S3. Fetch in parallel at the page level.**
```tsx
// Good: page-level parallel fetch, passed as props
export default async function Page({ params }: Props) {
  const [user, settings] = await Promise.all([
    getUser(params.id),
    getSettings(params.id),
  ]);
  return <UserDashboard user={user} settings={settings} />;
}
```

**S4. Use `<Image>` component for all images.**
- Always provide `width` and `height` (or `fill`)
- Use `sizes` prop for responsive images
- Lazy loading and AVIF format applied automatically
- Never use raw `<img>` tags

### Layout and Rendering

**L1. Keep client components small (islands pattern).**
```tsx
// Good: server component wraps minimal client island
export default async function ProductPage() {
  const product = await getProduct(id);
  return (
    <ProductLayout product={product}>
      <AddToCartButton productId={product.id} />  {/* tiny client island */}
    </ProductLayout>
  );
}
```

**L2. Use `content-visibility: auto` for long lists.**
```css
.list-item {
  content-visibility: auto;
  contain-intrinsic-size: auto 72px;
}
```

**L3. Hoist static JSX outside render functions.**
```tsx
// Bad: recreated every render
function Page() {
  const footer = <Footer />;
  return <div>{children}{footer}</div>;
}

// Good: created once
const footer = <Footer />;
function Page() {
  return <div>{children}{footer}</div>;
}
```

## Tier 3: MEDIUM (Guidelines, Not Hard Rules)

### Re-render Optimization

**R1. Split large contexts.** If a context updates frequently, split it into separate providers (one for frequently-changing data, one for stable data).

**R2. Use `useTransition` for non-urgent updates.** Keeps the UI responsive during expensive re-renders.

**R3. Memoize expensive computations with `useMemo`.** Only when the computation is genuinely expensive (sorting large arrays, complex calculations), not for trivial operations.

**R4. Use `useRef` for transient values.** Values that change frequently but don't need to trigger re-renders (scroll position, timer IDs, previous values).

### Animation Performance

**A1. Animate only `transform` and `opacity`.** These are GPU-composited. Animating layout properties (width, height, top, left) causes layout thrashing.

**A2. Use `will-change` sparingly.** Apply to elements about to animate, remove after animation completes. Never set `will-change` globally.

**A3. Prefer CSS transitions over JS animation libraries for simple state changes.** Zero bundle cost, GPU-accelerated by default.

**A4. View Transitions API for page transitions** (React 19+, ~85% browser support).
```tsx
<ViewTransition>
  <Component key={pageState} />
</ViewTransition>
```

## Tier 4: LOW (Nice to Have)

### JavaScript Performance

**J1. Use `Map` for frequent key lookups** instead of object property access on large datasets.

**J2. Combine array iterations.** `array.filter().map()` iterates twice. Use `array.reduce()` or a single `for` loop for performance-critical paths.

**J3. Batch DOM reads and writes.** Reading layout properties (offsetHeight, getBoundingClientRect) forces synchronous layout. Batch reads, then batch writes.

## Quick Reference: Performance Budget

| Metric | Target | Tool |
|--------|--------|------|
| First Contentful Paint (FCP) | < 1.8s | Lighthouse |
| Largest Contentful Paint (LCP) | < 2.5s | Lighthouse |
| Cumulative Layout Shift (CLS) | < 0.1 | Lighthouse |
| Interaction to Next Paint (INP) | < 200ms | Lighthouse |
| Total Bundle Size (JS) | < 200KB gzipped | bundlesize/size-limit |
| Client Components | < 20% of tree | Manual audit |
