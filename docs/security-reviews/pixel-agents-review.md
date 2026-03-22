# Security Review: pixel-agents VS Code Extension

**Extension:** [pixel-agents](https://github.com/pablodelucca/pixel-agents)
**Publisher:** pablodelucca
**Version Reviewed:** Latest on `main` branch (commit date: 2026-03-07)
**Review Date:** 2026-03-08
**Reviewers:** 4-person security team (Senior AppSec Engineer, Senior Security Engineer, Senior Application Pentester, Cyber IAM Engineer)

---

## Executive Summary

**Recommendation: GO**

The pixel-agents VS Code extension is **approved for installation** with compensating controls for Medium-severity findings. No Critical or High severity vulnerabilities were identified across supply chain, application security, and IAM/permissions domains.

The extension has an exceptionally clean security profile for a VS Code extension: zero runtime dependencies, zero network calls, zero telemetry, no `eval()`/`exec()`/`spawn()`, no `innerHTML`/`dangerouslySetInnerHTML`, and no dynamic code execution. Its attack surface is limited to local JSONL file parsing and webview rendering. The few Medium findings relate to defense-in-depth gaps (missing explicit CSP, unsanitized display strings, partial bash command exposure) rather than exploitable vulnerabilities.

**Risk Summary:**
| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 0 |
| Medium | 6 |
| Low | 9 |
| Informational | 8 |

---

## Extension Overview

pixel-agents visualizes Claude Code AI agents as animated pixel-art characters in a virtual office environment within VS Code. It:

- **Reads** JSONL transcript files from `~/.claude/projects/` (read-only)
- **Writes** layout state to `~/.pixel-agents/layout.json` (single file)
- **Creates** VS Code terminals to launch Claude Code sessions
- **Renders** a React-based webview with pixel art animations
- Makes **zero network requests** (fully offline)

### Architecture

```
JSONL Files (~/.claude/projects/)
  → fileWatcher.ts (fs.watch + polling)
  → transcriptParser.ts (JSON.parse, field extraction)
  → agentManager.ts (agent lifecycle)
  → PixelAgentsViewProvider.ts (postMessage to webview)
  → App.tsx (React rendering)
```

---

## Consolidated Findings Table

| ID | Severity | Title | Domain | Compensating Control |
|----|----------|-------|--------|---------------------|
| AT-001 / IAM-005 | Medium | No explicit Content Security Policy on webview | AppSec / IAM | VS Code applies default restrictive CSP; add explicit CSP for defense-in-depth |
| AT-002 / IAM-010 | Medium | Unsanitized JSONL content in webview display strings | AppSec / IAM | React JSX escaping provides primary XSS defense; sanitize at source for defense-in-depth |
| AT-003 | Medium | No schema validation on parsed JSONL records | AppSec | Silent catch prevents crashes; add runtime validation for robustness |
| IAM-001 | Medium | Terminal command execution scope | IAM | Session IDs use crypto.randomUUID() (safe); command is hardcoded, not user-controlled |
| IAM-003 | Medium | Transcript data read access scope | IAM | Only metadata fields extracted (tool names, truncated commands); no raw content forwarded |
| IAM-006 | Medium | File system write to user home directory | IAM | Write scoped to single path (~/.pixel-agents/layout.json); atomic write pattern used |
| AT-004 | Low | Terminal command injection via session ID | AppSec | Mitigated: crypto.randomUUID() output cannot contain shell metacharacters |
| AT-005 | Low | Path traversal in asset loading | AppSec | Mitigated: catalog is bundled with extension, not user-supplied |
| AT-006 | Low | Layout file deserialization without full schema validation | AppSec | Import validates version and tiles array; no code execution sinks |
| AT-007 | Low | TOCTOU window in file watcher | AppSec | Requires same-user filesystem access; offset tracking serializes reads |
| SC-002 | Low | Anthropic SDK as devDependency | Supply Chain | Not shipped in production bundle; .env is gitignored |
| SC-005 | Low | Husky prepare script runs on install | Supply Chain | Standard pattern; monitor .husky/ directory for changes |
| SC-008 | Low | No CI/CD pipeline for automated security scanning | Supply Chain | Manual publishing; recommend adding npm audit to workflow |
| IAM-002 | Low | Activation scoped to panel view | IAM | Correct behavior; no onStartupFinished or wildcard activation |
| IAM-004 | Low | postMessage handler design | IAM | Each message type maps to bounded operation; no unexpected privilege paths |
| IAM-007 | Low | Workspace state stores file paths | IAM | workspaceState is extension-scoped; not accessible to other extensions |
| IAM-009 | Low | Project directory path derivation is deterministic | IAM | Mirrors Claude Code's own scheme; not a vulnerability |
| IAM-012 | Low | retainContextWhenHidden not set (secure default) | IAM | Positive finding: webview state cleared when hidden |
| SC-001 | Info | Zero runtime dependencies | Supply Chain | Positive finding |
| SC-003 | Info | Version constraints properly scoped (caret ranges) | Supply Chain | Positive finding |
| SC-004 | Info | Build pipeline is clean and standard | Supply Chain | Positive finding |
| SC-006 | Info | .vscodeignore is comprehensive | Supply Chain | Positive finding |
| SC-007 | Info | Publisher identity and commit history consistent | Supply Chain | Positive finding |
| AT-008 | Info | Webview message origin not validated | AppSec | VS Code webview isolation handles this |
| AT-009 | Info | No localResourceRoots restriction | AppSec | VS Code defaults restrict to extension + workspace |
| AT-010 | Info | Project directory path sanitization is effective | AppSec | Positive finding |
| IAM-008 | Info | Global state for sound preference only | IAM | Single boolean; no security implications |
| IAM-011 | Info | No extension dependencies | IAM | Positive finding |

---

## Detailed Findings

### Medium Severity

#### AT-001 / IAM-005: No Explicit Content Security Policy on Webview

**Components:** `src/PixelAgentsViewProvider.ts` (resolveWebviewView, getWebviewContent)

The webview is created with `enableScripts: true` but no explicit CSP meta tag. The `getWebviewContent()` function rewrites asset paths to webview URIs but does not inject a CSP header. VS Code applies a default restrictive CSP, but this is not guaranteed across all VS Code forks (Cursor, VSCodium, code-server).

**Exploitability:** Low. Requires a VS Code fork with relaxed CSP defaults AND a separate injection vector (e.g., AT-002).

**Compensating Control:** VS Code's built-in CSP provides the primary defense. For defense-in-depth, the extension should add an explicit CSP restricting `script-src` to nonces and `style-src` to extension resources. Set `localResourceRoots` to `[extensionUri/dist]`.

---

#### AT-002 / IAM-010: Unsanitized JSONL Content in Webview Display Strings

**Components:** `src/transcriptParser.ts` (formatToolStatus), `webview-ui/src/hooks/useExtensionMessages.ts`

JSONL-derived strings (bash commands truncated to 30 chars, tool names, task descriptions) are sent to the webview via postMessage without HTML encoding. React's JSX rendering provides implicit XSS protection by escaping interpolated values, but this relies on no rendering path using `innerHTML`.

**Attack Vector:** A crafted JSONL transcript with HTML/script payloads in tool status fields. The 30-character truncation limits but does not eliminate short payloads (e.g., `<img/onerror=alert(1)>` is 27 chars). Requires the attacker to place a malicious JSONL file in `~/.claude/projects/`.

**Exploitability:** Low. React's JSX escaping is the primary defense. No `innerHTML` or `dangerouslySetInnerHTML` usage was found in the codebase. Partial bash command exposure (first 30 chars) could leak credential prefixes.

**Compensating Control:** React JSX escaping handles the XSS vector. For the credential leakage concern, consider displaying only the command name (first word) in status strings. HTML-encode special characters in `formatToolStatus()` as defense-in-depth.

---

#### AT-003: No Schema Validation on Parsed JSONL Records

**Components:** `src/transcriptParser.ts` (processTranscriptLine)

JSONL lines are parsed with `JSON.parse()` and accessed via property chains without runtime type validation. The `catch {}` block silently swallows parse errors, preventing crashes but hiding malformed input.

**Exploitability:** Very low. Type confusion from malformed JSONL would cause undefined property access (returning `undefined`), not code execution. Silent error swallowing means malformed inputs are ignored rather than exploited.

**Compensating Control:** The existing try/catch prevents crashes. Adding a lightweight schema check (e.g., validating `record.type` is a known string) would improve robustness but is not security-critical.

---

#### IAM-001: Terminal Command Execution Scope

**Components:** `src/agentManager.ts` (launchNewTerminal)

The extension creates terminals and sends `claude --session-id <UUID>` via `terminal.sendText()`. The session ID is generated by `crypto.randomUUID()` (hexadecimal + hyphens only), making shell injection impossible through this vector. The command template is hardcoded, not constructed from user input.

**Exploitability:** None with current implementation. The risk is architectural: the extension has the capability to execute arbitrary terminal commands, though it only uses this for a single, safe command.

**Compensating Control:** The hardcoded command template and `crypto.randomUUID()` input make this safe. As defense-in-depth, quote the session ID: `claude --session-id '${sessionId}'`.

---

#### IAM-003: Transcript Data Read Access Scope

**Components:** `src/fileWatcher.ts`, `src/transcriptParser.ts`

The extension reads raw JSONL transcripts which may contain sensitive data (API keys, credentials, file contents from Claude Code sessions). However, `transcriptParser.ts` extracts only metadata fields: tool names, tool IDs, status indicators, and truncated command strings (30 chars max).

**Exploitability:** Low. Sensitive data passes through the extension's memory during parsing but is not forwarded to the webview in full. The 30-character bash command prefix is the only content-derived data exposed.

**Compensating Control:** The field extraction pattern limits data exposure. Combined with AT-002/IAM-010's recommendation to display only command names, this reduces the exposure further.

---

#### IAM-006: File System Write to User Home Directory

**Components:** `src/layoutPersistence.ts`, `src/PixelAgentsViewProvider.ts`

The extension writes to `~/.pixel-agents/layout.json` using an atomic write pattern (write to `.tmp`, then rename). The import handler validates `version === 1` and `Array.isArray(imported.tiles)` before accepting imported layouts.

**Exploitability:** Very low. Write access is scoped to a single, predictable path. The atomic write pattern prevents corruption. Import is user-initiated via file dialog.

**Compensating Control:** Current scoping and validation are adequate. No additional controls needed.

---

### Supply Chain Assessment

**Overall Supply Chain Risk: LOW**

| Factor | Assessment |
|--------|-----------|
| Runtime dependencies | 0 (extension host), 2 (webview: react, react-dom, bundled) |
| DevDependencies | 26 total, all well-known packages, caret-scoped versions |
| Typosquatting risk | None detected |
| Post-install scripts | `prepare: husky` only (standard) |
| Build pipeline | esbuild + Vite, standard configs, no custom injection points |
| Source maps in production | Excluded (.vscodeignore + esbuild config) |
| Publisher trust | Consistent commit history, PR-based contributions |
| CI/CD | None (manual publishing); recommend adding |
| Secrets in repo | None found; .env is gitignored |

---

### Permissions and Access Control Assessment

**Overall Permissions Risk: LOW-MEDIUM**

| Permission | Scope | Assessment |
|-----------|-------|-----------|
| File read | `~/.claude/projects/<workspace>/` | Appropriate for stated purpose |
| File write | `~/.pixel-agents/layout.json` | Minimal, single file |
| Terminal creation | `vscode.window.createTerminal` | Used for Claude Code launch only |
| Webview | Panel view with enableScripts | Standard for interactive extensions |
| Activation | Panel view open | Correctly scoped, no startup activation |
| Storage | workspaceState + globalState | Extension-scoped, not cross-accessible |
| Network | None | No outbound connections |
| Extension dependencies | None | Self-contained |

---

### Attack Surface Assessment

**Overall Attack Surface: LOW-MEDIUM**

| Surface | Risk | Mitigations |
|---------|------|-------------|
| JSONL parsing pipeline | Medium | try/catch prevents crashes; only metadata extracted |
| Webview rendering | Medium | React JSX escaping; no innerHTML usage found |
| Terminal commands | Low | crypto.randomUUID(); hardcoded command template |
| Asset loading | Low | Bundled catalog; not user-supplied |
| Layout file I/O | Low | Atomic writes; schema validation on import |
| File watcher | Low | Offset tracking serializes reads |
| postMessage channel | Low | VS Code webview isolation; bounded message handlers |

---

## Compensating Controls Summary

The following controls are recommended before installation. All preserve full extension functionality.

### Required (for Medium findings)

1. **Monitor transcript content awareness** (AT-002/IAM-010): Be aware that the first 30 characters of bash commands from Claude Code sessions are displayed in the pixel-agents UI. Avoid running commands that start with secrets (e.g., `export API_KEY=sk-...`). Use environment files or secret managers instead of inline credentials.

2. **Restrict `~/.claude/projects/` permissions** (IAM-003): Ensure `~/.claude/projects/` has `0700` permissions so only your user account can read transcripts. Run: `chmod 700 ~/.claude/projects/`

### Recommended (defense-in-depth)

3. **Install from source with verification**: Clone the repo, review the diff against the latest marketplace version, and build locally with `npm run package` to verify the VSIX contents match expectations.

4. **File system monitoring** (optional): If running in a shared or multi-user environment, monitor `~/.claude/projects/` for symlink creation or unexpected file modifications.

---

## Positive Security Findings

The extension demonstrates several security-positive patterns:

- **Zero runtime dependencies** in the extension host, minimizing supply chain risk
- **No network access** of any kind (no fetch, XMLHttpRequest, or Node.js http/https)
- **No dynamic code execution** (no eval, Function constructor, child_process, or exec)
- **No innerHTML or dangerouslySetInnerHTML** in the React webview
- **Atomic file writes** for layout persistence (tmp + rename pattern)
- **crypto.randomUUID()** for session ID generation (cryptographically safe)
- **Aggressive path sanitization** matching Claude Code's own scheme
- **Comprehensive .vscodeignore** excluding source, configs, and sensitive files
- **Consistent publisher identity** with PR-based external contribution workflow
- **No telemetry or data collection** of any kind

---

## Recommendation

**GO: Approved for installation.**

The pixel-agents extension has a clean security profile with no Critical or High severity findings. The 6 Medium findings are all defense-in-depth gaps rather than exploitable vulnerabilities, and the primary attack vectors (JSONL injection, webview XSS) are mitigated by existing controls (React JSX escaping, try/catch error handling, hardcoded command templates).

The two required compensating controls (bash command awareness and directory permissions) are operational practices that do not require code changes and preserve full extension functionality.

**Risk acceptance rationale:** The extension operates in a local-only, single-user context with no network access, no dynamic code execution, and a minimal file system footprint. The most realistic attack scenario (crafted JSONL transcript) requires an attacker who already has write access to `~/.claude/projects/`, at which point they already have code execution capability through Claude Code itself.
