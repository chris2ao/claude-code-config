#!/usr/bin/env bash
# platform: macos

# blog-writer-validate.sh - PostToolUse hook for the blog-writer agent.
#
# Runs validate-mdx.sh after every Write/Edit to a blog or backlog MDX file.
# On a FAIL it prints the errors to stderr and exits 2, which feeds them back
# to the writer so it fixes them before returning. Warnings never block
# (several are heuristics the writer cannot resolve, so blocking would loop).
#
# Wired from the frontmatter of ~/.claude/agents/blog-writer.md:
#   hooks: PostToolUse (matcher Write|Edit) -> bash ~/.claude/scripts/blog-writer-validate.sh
#
# Advisory only: a PostToolUse hook cannot stop the agent from returning. The
# deterministic gate is blog-voice's validate_errors, routed to must-fix by
# ~/.claude/workflows/blog-pipeline.js.

set -uo pipefail

input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input" 2>/dev/null)

# Brace globs do not expand in case patterns, so list both locations.
case "$file" in
    */src/content/blog/*.mdx | */src/content/backlog/*.mdx) ;;
    *) exit 0 ;;
esac

[[ -f "$file" ]] || exit 0

# validate-mdx.sh exits 0 even on FAIL; a non-zero exit means a usage error.
out=$(bash "$HOME/.claude/scripts/validate-mdx.sh" "$file" 2>/dev/null) || exit 0
overall=$(jq -r '.summary.overall // empty' <<<"$out" 2>/dev/null)

if [[ "$overall" == "FAIL" ]]; then
    {
        echo "validate-mdx FAIL on $file. Fix these before returning:"
        jq -r '.errors[]? | "- " + .' <<<"$out"
    } >&2
    exit 2
fi

# Confirm the pass to the writer (and leave a trace in the transcript)
warnings=$(jq -r '.summary.warning_count // 0' <<<"$out" 2>/dev/null)
jq -n --arg ctx "validate-mdx: ${overall} (${warnings} warnings) on $(basename "$file")" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
exit 0
