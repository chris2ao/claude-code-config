#!/bin/bash
# file-guard.sh — PreToolUse hook to block edits to sensitive files
# Reads JSON from stdin, checks if the target file matches a protected pattern.
# Exit code 2 + stderr message = block the operation with a reason shown to user.

# Read JSON from stdin
input=$(cat)

# Extract file_path or path from tool_input
file_path=$(echo "$input" | grep -o '"file_path":"[^"]*"' | head -n1 | cut -d'"' -f4)
if [ -z "$file_path" ]; then
    file_path=$(echo "$input" | grep -o '"path":"[^"]*"' | head -n1 | cut -d'"' -f4)
fi

# Exit if no file path found
if [ -z "$file_path" ]; then
    exit 0
fi

# Extract filename and extension
filename=$(basename "$file_path")
extension="${filename##*.}"

# Protected file patterns
blocked_names=(".env" ".env.local" ".env.production" ".env.development" "credentials.json")
blocked_extensions=("pem" "key" "secret")

# Check blocked names
for name in "${blocked_names[@]}"; do
    if [ "$filename" = "$name" ]; then
        echo "BLOCKED: Cannot modify sensitive file '$filename'. Edit environment files manually." >&2
        exit 2
    fi
done

# Check blocked extensions
for ext in "${blocked_extensions[@]}"; do
    if [ "$extension" = "$ext" ]; then
        echo "BLOCKED: Cannot modify certificate/key file '$filename'. Handle credentials manually." >&2
        exit 2
    fi
done

# Block .env.* pattern (catches .env.staging, .env.test, etc.)
if [[ "$filename" =~ ^\.env\. ]]; then
    echo "BLOCKED: Cannot modify environment file '$filename'. Edit environment files manually." >&2
    exit 2
fi

exit 0
