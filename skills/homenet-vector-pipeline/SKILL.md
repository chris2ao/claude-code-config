---
platform: portable
description: "Safe Vector VRL patterns for parsing UDM-Pro syslog firewall events into ClickHouse"
evolved_from: ["udmpro-doubled-hostname"]
evolved_date: 2026-06-14
avg_confidence: 0.85
status: draft
component_type: skill
---

# /homenet-vector-pipeline - UDM-Pro Vector Syslog Pipeline Patterns

Activate when writing or debugging Vector VRL transforms that parse UDM-Pro BSD syslog frames, or when diagnosing zero rows in ClickHouse firewall_events materialized views. These patterns prevent silent data loss from firmware-specific syslog quirks.

## Steps

### 1. Doubled Hostname Strips Bracket Tags from .message

Current UDM-Pro firmware emits BSD syslog frames with a doubled hostname:

```
<13>May 26 23:11:18 UDM-Pro UDM-Pro [PREROUTING-DNAT-4] DESCR="PortForward DNAT" ...
```

Vector's BSD syslog parser consumes the second `UDM-Pro` token as the process name and treats `[PREROUTING-DNAT-4]` as the `procid`. The bracket tag is stripped from `.message`, which begins at `DESCR="..."` instead of `[TAG] DESCR="..."`.

Diagnostic: if `firewall_events` in ClickHouse returns zero rows after a VRL change, check whether `.message` starts with `DESCR=` instead of `[TAG] DESCR=`. That confirms the doubled-hostname strip.

### 2. Derive Action from .descr, Not the Bracket Tag

Do not pattern-match on `[TAG]` in `.message` to classify the firewall action. Instead, derive action from the `.descr` field, which Vector preserves even when the bracket tag is stripped:

```coffee
# Wrong: breaks when doubled hostname strips the bracket tag
if match(string!(.message), r'\[WAN_LOCAL\]') {
  .action = "block"
}

# Correct: .descr survives the doubled-hostname parse
if contains(string!(.descr), "Block All Traffic") {
  .action = "block"
} else if contains(string!(.descr), "PortForward DNAT") {
  .action = "forward"
}
```

The DESCR values (`PortForward DNAT`, `Block All Traffic`, `WAN_LOCAL`, etc.) are present in `.descr` and are sufficient for classify-action logic.

### 3. Use .time_received for Timestamps

Do not use `.timestamp` for UDM-Pro syslog events. The UDM sends BSD syslog timestamps without a timezone indicator; Vector assumes UTC, but the UDM sends local time. The result is a consistent 4-hour skew (or whatever the local UTC offset is).

Use `.time_received` instead:

```coffee
# Wrong: 4-hour skew because Vector assumes UTC for BSD syslog
.event_time = .timestamp

# Correct: use Vector's receive time, which is always UTC
.event_time = .time_received
```

### 4. Make the Bracket Tag Optional in parse_udmpro

The optional-tag regex in any `parse_udmpro` VRL function must treat the bracket tag as optional to remain backward-compatible with older firmware that did not double the hostname:

```coffee
# Wrong: requires [TAG] to be present in .message
parsed, err = parse_regex(.message, r'^\[(?P<tag>[^\]]+)\] DESCR=(?P<descr>.*)')

# Correct: make the [TAG] group optional
parsed, err = parse_regex(.message, r'^(?:\[(?P<tag>[^\]]+)\] )?DESCR=(?P<descr>.*)')
```

This handles both old firmware (tag present in `.message`) and current firmware (tag stripped to `.procid`).

### 5. Diagnosing Empty firewall_events

When `firewall_events` count is zero after a schema or VRL change:

1. Check `.message` directly in Vector logs: does it start with `DESCR=` or `[TAG] DESCR=`?
2. If `DESCR=`, doubled-hostname stripping is active. Switch to `.descr`-based classification.
3. Confirm `.procid` contains the bracket tag value (e.g., `PREROUTING-DNAT-4`) to verify the parser absorbed it there.
4. Check `.time_received` vs `.timestamp` for a UTC-offset skew.
5. Verify the materialized view gate condition uses the correct `event_type` value produced by the updated VRL.

## Source Instincts

- `udmpro-doubled-hostname`: "when writing Vector VRL to parse UDM-Pro syslog firewall events, or diagnosing empty firewall_events in ClickHouse"
