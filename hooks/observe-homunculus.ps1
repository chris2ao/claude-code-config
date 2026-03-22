# observe-homunculus.ps1 — Runs on PostToolUse hook (async)
# Captures tool usage observations for the Homunculus v2 continuous learning system.
# Writes JSONL to ~/.claude/homunculus/observations.jsonl for later analysis
# by the skill-extractor agent or /learn command.
#
# Hook input (JSON on stdin) includes:
#   tool_name   — name of the tool (Bash, Edit, Write, Read, Grep, Glob, etc.)
#   tool_input  — the input/arguments passed to the tool
#   tool_output — the output/result from the tool (PostToolUse only)
#   session_id  — current session identifier

$ErrorActionPreference = "SilentlyContinue"

# --- Config ---
$homunculusDir = Join-Path $env:USERPROFILE ".claude\homunculus"
$observationsFile = Join-Path $homunculusDir "observations.jsonl"
$archiveDir = Join-Path $homunculusDir "observations.archive"
$disabledSentinel = Join-Path $homunculusDir "disabled"
$maxInputChars = 5000
$maxOutputChars = 5000
$maxFileSizeMB = 10
$allowedTools = @("Edit", "Write", "Bash", "Read", "Grep", "Glob")

# --- Early exits ---

# Disabled sentinel check
if (Test-Path $disabledSentinel) { exit 0 }

# Ensure homunculus directory exists
if (-not (Test-Path $homunculusDir)) { exit 0 }

# --- Read stdin ---
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

$toolName = $data.tool_name
if (-not $toolName) { exit 0 }

# --- Filter: only capture allowed tools ---
if ($toolName -notin $allowedTools) { exit 0 }

# --- Extract fields ---
$sessionId = $data.session_id
$toolInput = $data.tool_input
$toolOutput = $data.tool_output

# Serialize and truncate input
$inputStr = ""
if ($toolInput) {
    try {
        $inputStr = $toolInput | ConvertTo-Json -Compress -Depth 3
    } catch {
        $inputStr = "$toolInput"
    }
    if ($inputStr.Length -gt $maxInputChars) {
        $inputStr = $inputStr.Substring(0, $maxInputChars) + "...[truncated]"
    }
}

# Serialize and truncate output
$outputStr = ""
if ($toolOutput) {
    try {
        $outputStr = $toolOutput | ConvertTo-Json -Compress -Depth 3
    } catch {
        $outputStr = "$toolOutput"
    }
    if ($outputStr.Length -gt $maxOutputChars) {
        $outputStr = $outputStr.Substring(0, $maxOutputChars) + "...[truncated]"
    }
}

# --- Build observation object ---
$observation = [ordered]@{
    timestamp  = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
    session_id = $sessionId
    tool       = $toolName
    input      = $inputStr
    output     = $outputStr
}

# Convert to single-line JSON
try {
    $jsonLine = $observation | ConvertTo-Json -Compress -Depth 3
} catch {
    exit 0
}

# --- Append to observations file ---
$jsonLine | Out-File -Append -FilePath $observationsFile -Encoding utf8 -NoNewline
"`n" | Out-File -Append -FilePath $observationsFile -Encoding utf8 -NoNewline

# --- Archive if file exceeds size limit ---
if (Test-Path $observationsFile) {
    $fileSize = (Get-Item $observationsFile).Length
    if ($fileSize -gt ($maxFileSizeMB * 1MB)) {
        # Ensure archive directory exists
        if (-not (Test-Path $archiveDir)) {
            New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
        }

        $datestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
        $archiveName = "observations_${datestamp}.jsonl"
        $archivePath = Join-Path $archiveDir $archiveName

        Move-Item -Path $observationsFile -Destination $archivePath -Force
        # Fresh file will be created on next append
    }
}
