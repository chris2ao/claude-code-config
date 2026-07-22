---
id: unifi-verify-after-write
trigger: after any UniFi REST write (firewall policy, port forward, PPSK, network or SSID config)
action: re-fetch the live record and diff it against intent; treat HTTP 200 with an empty data array or a silently substituted field as a rejected write, not success
confidence: 0.8
source: session-archive-ingestion
created: 2026-07-21
---

# UniFi REST Writes Require Post-Write Verification

The UniFi controller (UDM Pro, Network 10.2.x) accepts many writes with `rc=ok` / HTTP 200 while silently doing something other than what was asked. Never trust the POST/PUT response body; always GET the live record afterward and verify the fields you set.

Observed failure modes (4+ sessions):
1. **Silent no-op with empty data array**: `/rest/portforward/{id}` accepts a partial PUT body with 200 and ignores it entirely (2026-06-14). Same pattern as PPSK `networkconf_id` rejection.
2. **Silent field substitution**: v2 ZBF firewall-policies POST replaces `source.zone_id` with the network's actual zone when they mismatch, no error returned (2026-05-01).
3. **No writable backing resource**: `simple_app_block` rules return 404 or no-op for every REST verb; only GUI mutation works (2026-04-19).
4. **Full-object replacement semantics**: partial updates clobber or get ignored; fetch the full object, merge changes, and PUT the complete object (same lesson as RemoteTrigger API).

Standard write pattern:
1. GET the full current object.
2. Merge changes into it; PUT the complete object.
3. GET the live record again and diff against intent.
4. On mismatch, report the substitution or rejection to the user instead of claiming success.
