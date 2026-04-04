---
platform: portable
description: "Validate content integrity beyond HTTP status codes: media, API responses, and data contracts"
---

# /content-validation - Content and Data Contract Validation

Activate when validating embedded media in blog posts or web content, consuming structured data from external APIs, or integrating with the Gmail API for header-dependent operations.

## Steps

### 1. Media Validation Beyond HTTP Status

Do not rely on HTTP status codes alone for embedded media (images, GIFs, videos). Some CDNs return HTTP 200 with placeholder content instead of proper 404 errors.

Validation checklist for embedded media:

1. HTTP status check (necessary but not sufficient)
2. File size check: compare against expected range for the content type
3. Image dimensions: unusually small dimensions indicate placeholder content
4. Binary content signature: known placeholder files have recognizable byte patterns
5. Manual spot-check for critical content before publish

Known CDN behavior: Giphy returns HTTP 200 with a "content not available" placeholder image for removed GIFs.

### 2. Verify Actual API Field Names

Before wiring up any data consumer, log a sample response and verify actual field names:

```ts
// Always inspect before assuming field names from docs
const sample = await api.getSomething()
console.log('Sample response:', JSON.stringify(sample, null, 2))
```

Common mismatches to watch for:

| Documentation says | Actual response has |
|--------------------|--------------------|
| `message` | `title` + `detail` |
| `data` (flat array) | `{ data: [...] }` envelope |
| `id` | `_id` or `uuid` |

Add TypeScript types that match the actual response, not the documentation.

### 3. Gmail API: Use format: full for Headers

The Gmail API's `format: metadata` response excludes `To` and `Cc` headers by default. Any operation that needs recipient information must use `format: full`:

```ts
// Wrong: metadata mode excludes To/Cc
const msg = await gmail.users.messages.get({ id, format: 'metadata' })

// Correct: full format includes all headers
const msg = await gmail.users.messages.get({ id, format: 'full' })
```

Operations that require `format: full`: VIP detection via reply history, routing rules based on recipients, Cc-based classification.

## Source Instincts

- `media-content-validation`: "when validating embedded media in content"
- `verify-data-contracts`: "when consuming structured data from external systems"
- `gmail-api-full-format`: "when using Gmail API to classify or route emails based on recipients"
