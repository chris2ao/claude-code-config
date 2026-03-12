---
platform: portable
description: "Google Workspace CLI: Drive, Gmail, Calendar, Docs, Sheets, Slides, Tasks, and more"
---

# /gws - Google Workspace CLI

Interact with Google Workspace services via the `gws` CLI (v0.11.1). This skill teaches patterns for on-demand discovery, not hardcoded commands. Use `gws schema` to learn any API surface at runtime.

## Safety Rules (READ FIRST)

### Operation Tiers

| Tier | Operations | Requirement |
|------|-----------|-------------|
| 1 (Safe) | list, get, search, schema, auth status | Auto-execute |
| 2 (Create) | create, insert, draft, copy | Confirm with user first |
| 3 (Modify) | update, patch, move, share, send | `--dry-run` first, then confirm |
| 4 (Destroy) | delete, trash, revoke, cancel, remove | Only on explicit user request, `--dry-run` first |

### Hard Rules

- **NEVER** output OAuth tokens, refresh tokens, or credential file contents
- **NEVER** auto-send email. Always create a draft first, show it, then ask if the user wants to send
- **NEVER** use `--page-all` without explicit user request (quota risk)
- **ALWAYS** use small page sizes (10-25 items) for list operations
- **ALWAYS** run `--dry-run` before Tier 3 and Tier 4 operations
- For batch operations, process in groups of 10-20 with natural pauses

## Prerequisites

Before running any gws command, verify:

```bash
gws --version   # Should return 0.11.1
gws auth status  # Should show auth_method != "none"
```

If auth is not configured, guide the user through setup:
1. Place OAuth client_secret.json at `~/.config/gws/client_secret.json`
2. Run `gws auth login` (opens browser for consent)
3. Verify with `gws auth status`

## Command Pattern

```
gws <service> <resource> [sub-resource] <method> [flags]
```

**Key flags:**
- `--params '<JSON>'` : URL/query parameters
- `--json '<JSON>'` : Request body (POST/PATCH/PUT)
- `--format <json|table|yaml|csv>` : Output format (default: json)
- `--dry-run` : Validate locally without sending to API
- `--page-all` : Auto-paginate (use `--page-limit N` to cap pages)
- `--upload <PATH>` : Upload a local file (multipart)
- `--output <PATH>` : Save binary response to file

## Schema Discovery (Primary Learning Method)

When you need to learn an API method's parameters, use `gws schema`:

```bash
# Full method schema (parameters, request body, response)
gws schema drive.files.list
gws schema gmail.users.messages.send

# With resolved $ref types
gws schema calendar.events.insert --resolve-refs
```

**Always use schema discovery** instead of guessing parameters. The schema output includes parameter names, types, required fields, and descriptions.

## Service Reference

| Service | Command | Status | Key Resources |
|---------|---------|--------|---------------|
| Drive | `gws drive` | **Verified** | files, permissions, comments, replies |
| Gmail | `gws gmail` | **Verified** | users.messages, users.labels, users.drafts, users.threads |
| Calendar | `gws calendar` | **Verified** | events, calendarList, acl |
| Docs | `gws docs` | **Verified** | documents |
| Sheets | `gws sheets` | **Verified** | spreadsheets, spreadsheets.values |
| Slides | `gws slides` | **Verified** | presentations, presentations.pages |
| Tasks | `gws tasks` | **Verified** | tasklists, tasks |
| People | `gws people` | **Verified** | people, contactGroups |
| Forms | `gws forms` | **Verified** | forms, forms.responses |
| Meet | `gws meet` | Untested | conferenceRecords, spaces |
| Admin | `gws admin-reports` | Workspace admin only | activities, userUsageReport |
| Chat | `gws chat` | Needs scope (Workspace) | spaces, spaces.messages |
| Keep | `gws keep` | Needs scope (Workspace) | notes |
| Classroom | `gws classroom` | Workspace (Edu) only | courses, courseWork |

## Common Patterns

### Drive: List recent files
```bash
gws drive files list --params '{"pageSize": 10, "orderBy": "modifiedTime desc", "fields": "files(id,name,mimeType,modifiedTime)"}'
```

### Drive: Search files by name
```bash
gws drive files list --params '{"q": "name contains '\''report'\''", "pageSize": 10, "fields": "files(id,name,mimeType)"}'
```

### Gmail: List recent messages
```bash
gws gmail users messages list --params '{"userId": "me", "maxResults": 10}'
```

### Gmail: Read a message
```bash
gws gmail users messages get --params '{"userId": "me", "id": "<messageId>", "format": "full"}'
```

### Gmail: Create draft (never auto-send)
```bash
gws gmail users drafts create --params '{"userId": "me"}' --json '{"message": {"raw": "<base64-encoded-RFC2822>"}}'
```

### Calendar: List upcoming events
```bash
gws calendar events list --params '{"calendarId": "primary", "maxResults": 10, "timeMin": "<ISO8601-now>", "singleEvents": true, "orderBy": "startTime"}'
```

### Calendar: Create event (Tier 2, confirm first)
```bash
gws calendar events insert --params '{"calendarId": "primary"}' --json '{"summary": "Meeting", "start": {"dateTime": "..."}, "end": {"dateTime": "..."}}'
```

### Sheets: Read cell values
```bash
gws sheets spreadsheets values get --params '{"spreadsheetId": "<id>", "range": "Sheet1!A1:D10"}'
```

### Tasks: List task lists
```bash
gws tasks tasklists list --params '{"maxResults": 10}'
```

### Docs: Get document content
```bash
gws docs documents get --params '{"documentId": "<id>"}'
```

### Slides: Get presentation
```bash
gws slides presentations get --params '{"presentationId": "<id>"}'
```

### Workflow: Built-in helpers
```bash
gws workflow +standup-report   # Today's meetings + open tasks
gws workflow +meeting-prep     # Prepare for next meeting
gws workflow +email-to-task    # Convert email to task
gws workflow +weekly-digest    # Weekly summary
gws workflow +file-announce    # Announce Drive file in Chat
```

## Error Handling

| Error Code | Meaning | Fix |
|-----------|---------|-----|
| 401 | Token expired or revoked | Run `gws auth login` to re-authenticate |
| 403 | Insufficient scope or API not enabled | Check GCP console for API enablement; re-run `gws auth login` with needed scopes |
| 404 | Resource not found | Verify ID parameter; check if resource was deleted |
| 429 | Rate limit exceeded | Wait and retry; reduce page sizes and batch sizes |
| 400 | Bad request | Use `gws schema <method>` to verify parameter names and types |

## Troubleshooting

### Auth fails or token expired
```bash
gws auth login   # Re-authenticate (30 seconds)
```

### API returns 403 "Access Not Configured"
Enable the API in GCP Console: APIs & Services > Library > search for the service > Enable.

### Scope missing for a service
```bash
gws auth login -s drive,gmail,calendar,docs,sheets,slides,tasks,people
```

### Check which services are authenticated
```bash
gws auth status
```

### Version mismatch
```bash
gws --version           # Check current
npm update -g @googleworkspace/cli   # Update if needed
```
