# SSRF Prevention: IP Input Validation

## Problem
API endpoints that accept IP addresses and make external lookups (geo, WHOIS, OSINT) can be abused to probe internal networks if private/loopback IPs are not blocked.

## Solution
Validate IP addresses against private ranges before making any external API call:

```typescript
function isPrivateIp(ip: string): boolean {
  return (
    ip.startsWith("127.") ||
    ip.startsWith("10.") ||
    ip.startsWith("192.168.") ||
    ip.startsWith("0.") ||
    ip.startsWith("169.254.") ||
    ip === "::1" ||
    ip.startsWith("fe80:") ||
    /^172\.(1[6-9]|2\d|3[01])\./.test(ip)
  );
}
```

Return 400 immediately for private IPs — don't forward them to external lookup services.

## When to Apply
Any endpoint that:
- Takes a user-supplied IP/hostname as input
- Makes HTTP requests to external services using that input
- Performs DNS lookups, WHOIS queries, or geo-IP resolution
