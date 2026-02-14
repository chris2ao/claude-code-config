# Vercel.json WAF Deny Rule Syntax

**Extracted:** 2026-02-10
**Context:** Configuring WAF firewall rules in vercel.json for Vercel-hosted sites

## Problem
Vercel documentation shows WAF rules using a `"rules"` top-level key with `"route"` property inside each entry. This fails schema validation on deploy with: `should NOT have additional property 'rules'`.

## Solution
Use `"routes"` (not `"rules"`) as the top-level key, and `"src"` (not `"route"`) for path matching. The `"mitigate"` property stays the same.

Correct syntax:
```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "routes": [
    {
      "src": "/api/(.*)",
      "has": [{ "type": "header", "key": "x-forwarded-host" }],
      "mitigate": { "action": "deny" }
    }
  ]
}
```

Only `deny` and `challenge` actions are supported in vercel.json. `log`, `bypass`, and `redirect` require the dashboard UI.

Vercel implements deny rules as JavaScript challenges. The `X-Vercel-Mitigated: challenge` response header confirms WAF interception. Browsers auto-pass the challenge; bots and curl get 403.

## When to Use
Any time you're adding WAF firewall rules to a Vercel-hosted project via vercel.json.
