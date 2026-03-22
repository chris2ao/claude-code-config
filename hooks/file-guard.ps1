# file-guard.ps1 — PreToolUse hook to block edits to sensitive files
# Reads JSON from stdin, checks if the target file matches a protected pattern.
# Exit code 2 + stderr message = block the operation with a reason shown to user.

$ErrorActionPreference = "SilentlyContinue"

try {
    $jsonInput = [Console]::In.ReadToEnd()
    $data = $jsonInput | ConvertFrom-Json

    # Extract the file path from the tool input
    $filePath = $null
    if ($data.tool_input.file_path) {
        $filePath = $data.tool_input.file_path
    } elseif ($data.tool_input.path) {
        $filePath = $data.tool_input.path
    }

    if (-not $filePath) { exit 0 }

    $fileName = [System.IO.Path]::GetFileName($filePath)
    $extension = [System.IO.Path]::GetExtension($filePath)

    # Protected file patterns
    $blockedNames = @(".env", ".env.local", ".env.production", ".env.development", "credentials.json")
    $blockedExtensions = @(".pem", ".key", ".secret")

    if ($blockedNames -contains $fileName) {
        [Console]::Error.WriteLine("BLOCKED: Cannot modify sensitive file '$fileName'. Edit environment files manually.")
        exit 2
    }

    if ($blockedExtensions -contains $extension) {
        [Console]::Error.WriteLine("BLOCKED: Cannot modify certificate/key file '$fileName'. Handle credentials manually.")
        exit 2
    }

    # Block .env.* pattern (catches .env.staging, .env.test, etc.)
    if ($fileName -match '^\.env\.') {
        [Console]::Error.WriteLine("BLOCKED: Cannot modify environment file '$fileName'. Edit environment files manually.")
        exit 2
    }

    exit 0
} catch {
    # Never crash Claude Code — allow the operation on error
    exit 0
}
