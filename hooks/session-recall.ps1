# session-recall.ps1 — SessionStart hook (Windows counterpart of session-recall.sh)
# Emits a one-time directive to query vector memory before starting work.
# Fires on: startup, clear, compact. Skips resume (context already present).
#
# Opt-out: set CLAUDE_SESSION_RECALL=false in your environment

if ($env:CLAUDE_SESSION_RECALL -eq 'false') { exit 0 }

$input_raw = [Console]::In.ReadToEnd()

$sourceType = ''
if ($input_raw -match '"source":"([^"]*)"') { $sourceType = $matches[1] }

$cwd = ''
if ($input_raw -match '"cwd":"([^"]*)"') { $cwd = $matches[1] }

# Resume restores prior context; a recall directive there is pure noise.
if ($sourceType -eq 'resume') { exit 0 }

$project = ''
if ($cwd) { $project = Split-Path -Leaf ($cwd -replace '\\\\', '\') }

if ($project) {
    $scope = "Include `"$project`" as a search term or tag filter."
} else {
    $scope = "Include the project name as a search term or tag filter."
}

@"
MEMORY RECALL: Before acting on the user's first substantive request this session, run mcp__vector-memory__memory_search on the keywords of that request. $scope Pass quality_boost: 0.25 so scored memories outrank unscored noise.

Skip only if the request is trivial (a one-line question, a status check) or clearly unrelated to any prior work. If the search returns nothing relevant, proceed without comment rather than reporting the empty result.

Prior context beats re-derivation: gotchas, decisions, and failed approaches are already stored and cost real time to rediscover.
"@

exit 0
