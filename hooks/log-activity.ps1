# log-activity.ps1 — Runs on PostToolUse hook (async)
# Logs every file edit, bash command, and write operation to activity_log.txt
# so you have a running record of everything Claude Code does in this project.
#
# Hook input (JSON on stdin) includes:
#   tool_name  — name of the tool that was used (Bash, Edit, Write, etc.)
#   tool_input — the input/arguments passed to the tool
#   session_id — current session identifier

$ErrorActionPreference = "SilentlyContinue"

# Read JSON from stdin. When invoked via -Command with dot-sourcing,
# [Console]::In.ReadToEnd() reads piped stdin reliably.
# Falls back to $input for pipeline context.
try {
    $inputJson = [Console]::In.ReadToEnd()
} catch {
    $inputJson = $input | Out-String
}
if (-not $inputJson -or $inputJson.Trim() -eq "") { exit 0 }

try {
    $data = $inputJson | ConvertFrom-Json
} catch {
    exit 0
}

$toolName  = $data.tool_name
$toolInput = $data.tool_input
$sessionId = $data.session_id

if (-not $toolName) { exit 0 }

# Resolve project root from the working directory.
# Claude Code spawns hook processes with cwd set to the project directory,
# so this works for both global (~/.claude/hooks) and project-level hooks,
# and across machines regardless of where repos are cloned.
$projectRoot = (Get-Location).Path
$logPath     = Join-Path $projectRoot "activity_log.txt"

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Build a concise log line depending on tool type
$detail = ""
switch ($toolName) {
    "Edit" {
        $file = $toolInput.file_path
        $detail = "Edited: $file"
    }
    "Write" {
        $file = $toolInput.file_path
        $detail = "Wrote: $file"
    }
    "Bash" {
        $cmd = $toolInput.command
        # Truncate long commands to keep the log readable
        if ($cmd.Length -gt 200) { $cmd = $cmd.Substring(0, 200) + "..." }
        $detail = "Ran: $cmd"
    }
    "NotebookEdit" {
        $nb = $toolInput.notebook_path
        $detail = "Edited notebook: $nb"
    }
    default {
        $detail = "Used tool: $toolName"
    }
}

$logLine = "[$timestamp] ($sessionId) $toolName | $detail"
$logLine | Out-File -Append -FilePath $logPath -Encoding utf8

# --- Log rotation: archive when file exceeds 1000 lines ---
$maxLines = 1000
if (Test-Path $logPath) {
    $lineCount = @(Get-Content $logPath).Count
    if ($lineCount -ge $maxLines) {
        # Extract first and last timestamps from log for the archive filename
        $firstLine = (Get-Content $logPath -TotalCount 1)
        $lastLine  = (Get-Content $logPath | Select-Object -Last 1)

        # Parse dates from "[YYYY-MM-DD HH:mm:ss]" format
        $startDate = ""
        $endDate   = ""
        if ($firstLine -match '^\[(\d{4}-\d{2}-\d{2})') { $startDate = $Matches[1] }
        if ($lastLine  -match '^\[(\d{4}-\d{2}-\d{2})') { $endDate   = $Matches[1] }

        # Fallback if parsing fails
        if (-not $startDate) { $startDate = "unknown" }
        if (-not $endDate)   { $endDate   = Get-Date -Format "yyyy-MM-dd" }

        # Move rotated logs into activity_log_archive/ subdirectory
        $archiveDir = Join-Path $projectRoot "activity_log_archive"
        if (-not (Test-Path $archiveDir)) {
            New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
        }

        $archiveName = "activity_log_${startDate}_to_${endDate}.txt"
        $archivePath = Join-Path $archiveDir $archiveName

        # Avoid overwriting: append a counter if archive already exists
        $counter = 1
        while (Test-Path $archivePath) {
            $archiveName = "activity_log_${startDate}_to_${endDate}_${counter}.txt"
            $archivePath = Join-Path $archiveDir $archiveName
            $counter++
        }

        # Move current log to archive, start fresh
        Move-Item -Path $logPath -Destination $archivePath -Force
    }
}
