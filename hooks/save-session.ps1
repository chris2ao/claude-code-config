# save-session.ps1 — Runs on SessionEnd hook
# Copies the conversation transcript into .claude/session_archive/
# and appends an entry to the session index file.
#
# Hook input (JSON on stdin) includes:
#   session_id      — unique session identifier
#   transcript_path — path to the JSONL transcript file

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

$transcriptPath = $data.transcript_path
$sessionId      = $data.session_id

if (-not $transcriptPath -or -not (Test-Path $transcriptPath)) { exit 0 }

# Resolve project root from the working directory.
# Claude Code spawns hook processes with cwd set to the project directory,
# so this works for both global (~/.claude/hooks) and project-level hooks,
# and across machines regardless of where repos are cloned.
$projectRoot = (Get-Location).Path
$archiveDir  = Join-Path $projectRoot ".claude\session_archive"

if (-not (Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
}

# Create timestamped filename
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$archiveName = "${timestamp}_${sessionId}"

# Copy raw transcript
$destPath = Join-Path $archiveDir "${archiveName}.jsonl"
Copy-Item -Path $transcriptPath -Destination $destPath -Force

# Create a lightweight summary by extracting assistant/user message roles
$summaryPath = Join-Path $archiveDir "${archiveName}_summary.txt"
$summaryLines = @("Session: $sessionId", "Date: $timestamp", "Transcript: $transcriptPath", "---")

Get-Content $transcriptPath | ForEach-Object {
    try {
        $line = $_ | ConvertFrom-Json
        $role = $line.type
        if ($role) {
            $summaryLines += "[$role] $(($line.message.content | Select-Object -First 1).text | Select-Object -First 1)"
        }
    } catch { }
}
$summaryLines | Out-File -FilePath $summaryPath -Encoding utf8

# Append to session index
$indexPath = Join-Path $archiveDir "index.txt"
"$timestamp | $sessionId | $destPath" | Out-File -Append -FilePath $indexPath -Encoding utf8
