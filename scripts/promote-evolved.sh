#!/usr/bin/env bash
# promote-evolved.sh - Promote a draft evolved component to an active directory
# Usage: bash ~/.claude/scripts/promote-evolved.sh <component-path>

set -uo pipefail

EVOLVED_BASE="$HOME/.claude/homunculus/evolved"
COMPONENT_PATH="${1:-}"

# --- Validation ---

if [ -z "$COMPONENT_PATH" ]; then
    echo "Usage: bash ~/.claude/scripts/promote-evolved.sh <component-path>"
    echo "Example: bash ~/.claude/scripts/promote-evolved.sh ~/.claude/homunculus/evolved/agents/debug-specialist.md"
    exit 1
fi

# Resolve to absolute path
COMPONENT_PATH="$(cd "$(dirname "$COMPONENT_PATH")" 2>/dev/null && pwd)/$(basename "$COMPONENT_PATH")"

if [ ! -f "$COMPONENT_PATH" ]; then
    echo "Error: File not found: $COMPONENT_PATH"
    exit 1
fi

# Verify path is inside evolved/
case "$COMPONENT_PATH" in
    "$EVOLVED_BASE"/*)
        ;;
    *)
        echo "Error: Source must be inside $EVOLVED_BASE/"
        exit 1
        ;;
esac

# --- Detect component type from directory ---

REL_PATH="${COMPONENT_PATH#"$EVOLVED_BASE"/}"
COMPONENT_TYPE=""
TARGET_DIR=""
COMPONENT_NAME=""

case "$REL_PATH" in
    agents/*)
        COMPONENT_TYPE="agent"
        COMPONENT_NAME="$(basename "$REL_PATH")"
        TARGET_DIR="$HOME/.claude/agents"
        ;;
    skills/*)
        COMPONENT_TYPE="skill"
        # Skills use directory structure: skills/{name}/SKILL.md
        SKILL_DIR="$(echo "$REL_PATH" | cut -d'/' -f2)"
        COMPONENT_NAME="$SKILL_DIR/SKILL.md"
        TARGET_DIR="$HOME/.claude/skills"
        ;;
    commands/*)
        COMPONENT_TYPE="command"
        COMPONENT_NAME="$(basename "$REL_PATH")"
        TARGET_DIR="$HOME/.claude/commands"
        ;;
    *)
        echo "Error: Cannot determine component type from path: $REL_PATH"
        echo "Expected: agents/*.md, skills/*/SKILL.md, or commands/*.md"
        exit 1
        ;;
esac

TARGET_PATH="$TARGET_DIR/$COMPONENT_NAME"

# --- Check for conflicts ---

if [ -f "$TARGET_PATH" ]; then
    echo "Error: Target file already exists: $TARGET_PATH"
    echo "Use a different name or remove the existing file."
    exit 1
fi

# --- Strip evolution metadata from frontmatter ---

# Create a temp file with cleaned frontmatter
TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT

awk '
BEGIN { in_frontmatter = 0; frontmatter_count = 0 }
/^---$/ {
    frontmatter_count++
    if (frontmatter_count == 1) { in_frontmatter = 1; print; next }
    if (frontmatter_count == 2) { in_frontmatter = 0; print; next }
}
in_frontmatter == 1 {
    # Skip evolution metadata fields
    if ($0 ~ /^evolved_from:/) next
    if ($0 ~ /^evolved_date:/) next
    if ($0 ~ /^avg_confidence:/) next
    if ($0 ~ /^status:/) next
    if ($0 ~ /^component_type:/) next
    print
    next
}
{ print }
' "$COMPONENT_PATH" > "$TEMP_FILE"

# --- Copy to active directory ---

if [ "$COMPONENT_TYPE" = "skill" ]; then
    mkdir -p "$TARGET_DIR/$SKILL_DIR"
fi

cp "$TEMP_FILE" "$TARGET_PATH"

# --- Update status in source file ---

if grep -q "^status: draft" "$COMPONENT_PATH" 2>/dev/null; then
    sed -i '' 's/^status: draft/status: promoted/' "$COMPONENT_PATH"
elif grep -q "^status:" "$COMPONENT_PATH" 2>/dev/null; then
    sed -i '' 's/^status: .*/status: promoted/' "$COMPONENT_PATH"
fi

# --- Confirmation ---

echo "Promoted $COMPONENT_TYPE: $(basename "$COMPONENT_NAME" .md)"
echo "  Source: $COMPONENT_PATH (status: promoted)"
echo "  Target: $TARGET_PATH"
echo ""
echo "Next steps:"
echo "  - Run /skill-catalog to verify the component is listed"
echo "  - Run /Knowledge-Graph-Sync to register in the knowledge graph"
