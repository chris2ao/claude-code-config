# Cookie Auth Over Query Strings

## Problem
Using `?secret=X` query parameters for API authentication leaks secrets in:
- Browser history and address bar
- Server access logs
- HTTP Referer headers sent to external sites
- Bookmark URLs

## Solution
Use httpOnly cookies with HMAC-derived tokens:

1. **Login endpoint** accepts the secret via POST body, generates HMAC-SHA256 token, sets httpOnly cookie
2. **API routes** verify the cookie token using `timingSafeEqual` for constant-time comparison
3. **Server components** read cookie from `cookies()` in `next/headers`
4. **Client components** don't need the secret at all — browser sends cookies automatically on same-origin fetch

## Key Implementation Details
- Use `createHmac("sha256", secret).update(payload).digest("hex")` — never store the raw secret in the cookie
- Use `timingSafeEqual(Buffer.from(a), Buffer.from(b))` — prevents timing attacks
- Cookie flags: `httpOnly: true`, `secure: true` (in production), `sameSite: "strict"`, reasonable `maxAge`
- Fallback: also accept `Authorization: Bearer <secret>` header for programmatic access

## Anti-pattern
```typescript
// BAD: leaks in URLs
const url = `/api/data?secret=${process.env.SECRET}`;

// GOOD: cookie sent automatically
const res = await fetch("/api/data"); // cookie included by browser
```
