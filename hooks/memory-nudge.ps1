# memory-nudge.ps1 — PostToolUse hook (Windows)
# Tracks significant work per session. After 5+ units of work without a
# vector-memory store call, outputs a reminder that gets injected
# into Claude's context as user feedback.
#
# Opt-out: set CLAUDE_MEMORY_NUDGE=false in your environment to disable

if ($env:CLAUDE_MEMORY_NUDGE -eq "false") {
    exit 0
}

$input = [Console]::In.ReadToEnd()

$toolMatch = [regex]::Match($input, '"tool_name":"([^"]*)"')
$sessionMatch = [regex]::Match($input, '"session_id":"([^"]*)"')

if (-not $toolMatch.Success -or -not $sessionMatch.Success) {
    exit 0
}

$toolName = $toolMatch.Groups[1].Value
$sessionId = $sessionMatch.Groups[1].Value

$stateDir = Join-Path $env:TEMP "claude-memory-nudge"
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}
$stateFile = Join-Path $stateDir "$sessionId.state"

# Initialize state file if missing
if (-not (Test-Path $stateFile)) {
    @{ edits = 0; reminded = 0 } | ConvertTo-Json | Set-Content $stateFile
}

$state = Get-Content $stateFile | ConvertFrom-Json

# If memory_store was just called, reset counters
if ($toolName -eq "mcp__vector-memory__memory_store") {
    @{ edits = 0; reminded = 0 } | ConvertTo-Json | Set-Content $stateFile
    exit 0
}

# Determine how much work this tool call represents
$workUnits = 0

# Agent completions count as significant work
if ($toolName -eq "Agent") {
    $workUnits = 3
}

# Edit and Write count if they target source-like files
if ($toolName -eq "Edit" -or $toolName -eq "Write") {
    $fileMatch = [regex]::Match($input, '"file_path":"([^"]*)"')
    if ($fileMatch.Success) {
        $filePath = $fileMatch.Groups[1].Value
        $baseName = Split-Path $filePath -Leaf
        $ext = if ($baseName -match '\.([^.]+)$') { $matches[1] } else { "" }

        # Skip pure documentation and data files
        if ($ext -in @("mdx", "txt", "csv", "log")) {
            exit 0
        }

        # Skip dotfiles
        if ($baseName.StartsWith(".")) {
            exit 0
        }

        # Count code files
        $codeExts = @("py", "js", "ts", "tsx", "jsx", "rs", "go", "java", "rb", "sh", "css", "scss", "html", "vue", "svelte", "sql", "c", "cpp", "h", "ps1")
        if ($ext -in $codeExts) {
            $workUnits = 1
        }

        # Config files count at half weight
        $configExts = @("json", "yaml", "yml", "toml", "ini", "cfg")
        if ($ext -in $configExts) {
            $configHalf = Join-Path $stateDir "$sessionId.config_half"
            if (Test-Path $configHalf) {
                Remove-Item $configHalf
                $workUnits = 1
            } else {
                New-Item -ItemType File -Path $configHalf -Force | Out-Null
                exit 0
            }
        }

        # Unknown extensions in source-like paths still count
        if ($workUnits -eq 0) {
            $sourcePaths = @("src", "lib", "app", "components", "hooks", "pages", "server", "api", "services", "utils", "helpers", "models", "controllers", "routes", "middleware", "tools", "auth", "prompts")
            foreach ($sp in $sourcePaths) {
                if ($filePath -match "[\\/]$sp[\\/]") {
                    $workUnits = 1
                    break
                }
            }
        }
    }
}

# Bash commands that create/modify files also count
if ($toolName -eq "Bash") {
    $cmdMatch = [regex]::Match($input, '"command":"([^"]*)"')
    if ($cmdMatch.Success) {
        $cmd = $cmdMatch.Groups[1].Value
        if ($cmd -match "pip install|npm install|brew install|mkdir|mv ") {
            $workUnits = 1
        }
    }
}

# Nothing significant happened
if ($workUnits -eq 0) {
    exit 0
}

# Update state
$edits = [int]$state.edits + $workUnits
$reminded = [int]$state.reminded

@{ edits = $edits; reminded = $reminded } | ConvertTo-Json | Set-Content $stateFile

# Nudge at 5 work units, then every 10 after that
$threshold = 5
if ($reminded -gt 0) {
    $threshold = 5 + $reminded * 10
}

if ($edits -ge $threshold) {
    $reminded = $reminded + 1
    @{ edits = $edits; reminded = $reminded } | ConvertTo-Json | Set-Content $stateFile
    Write-Output "MEMORY REMINDER: You have accumulated $edits units of significant work this session without storing a vector memory. If you have completed any significant tasks, bug fixes, or architectural decisions, store them now using mcp__vector-memory__memory_store before continuing."
}

exit 0
