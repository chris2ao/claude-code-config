#!/bin/bash
# Environment variables for CJClaudin_home scripts
# Platform-aware: detects macOS vs Windows (Git Bash)

# ===== BASE DIRECTORIES =====
export CLAUDE_HOME="$HOME/.claude"

if [[ "$OSTYPE" == msys* ]] || [[ "$OSTYPE" == mingw* ]] || [[ "$OSTYPE" == cygwin* ]]; then
    export PROJECTS_DIR="/c/ClaudeProjects"
else
    export PROJECTS_DIR="$HOME/GitProjects"
fi

# ===== REPOSITORY PATHS =====
export REPO_CJCLAUDE="$PROJECTS_DIR/CJClaude_1"
export REPO_CJCLAUDIN_MAC="$PROJECTS_DIR/CJClaudin_Mac"
export REPO_CJCLAUDIN_HOME="$PROJECTS_DIR/CJClaudin_home"
export REPO_CRYPTOFLEX="$PROJECTS_DIR/cryptoflexllc"
export REPO_OPS="$PROJECTS_DIR/cryptoflex-ops"
export REPO_CONFIG="$PROJECTS_DIR/claude-code-config"
export REPO_MISSION_CONTROL="$PROJECTS_DIR/Openclaw_MissionControl"
export REPO_JCLAW_CONFIG="$PROJECTS_DIR/JClaw_Config"
export REPO_THIRD_CONFLICT="$PROJECTS_DIR/Third-Conflict"
export REPO_CANN_CANN="$PROJECTS_DIR/Cann-Cann"

# ===== TOOL PATHS (platform-conditional) =====
if [[ "$OSTYPE" == darwin* ]]; then
    export GH_PATH="/opt/homebrew/bin"
    export NODE_PATH="/opt/homebrew/bin"
    export PATH="$GH_PATH:$NODE_PATH:$PATH"
elif [[ "$OSTYPE" == msys* ]] || [[ "$OSTYPE" == mingw* ]]; then
    export PATH="/c/Program Files/GitHub CLI:/c/Program Files/nodejs:$PATH"
fi
