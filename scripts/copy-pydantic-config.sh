#!/bin/bash
# Copies pydantic worktree config to target directory
# Usage: copy-pydantic-config.sh [target_dir]  (default: cwd)

set -e

TOOLS_REPO="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${1:-$(pwd)}"

echo "Copying config from $TOOLS_REPO to $TARGET_DIR"

# Copy from tools repo (overwrite)
[ -f "$TOOLS_REPO/.env" ] && cp "$TOOLS_REPO/.env" "$TARGET_DIR/"

# Copy .mcp.json and substitute LOGFIRE_TOKEN if set
if [ -f "$TOOLS_REPO/.mcp.json" ]; then
    if [ -n "$LOGFIRE_TOKEN" ]; then
        sed "s/pylf_YOUR_TOKEN/$LOGFIRE_TOKEN/g" "$TOOLS_REPO/.mcp.json" > "$TARGET_DIR/.mcp.json"
    else
        cp "$TOOLS_REPO/.mcp.json" "$TARGET_DIR/.mcp.json"
    fi
fi
# Copy CLAUDE.local.md with confirmation if exists
if [ -f "$TARGET_DIR/CLAUDE.local.md" ]; then
    read -p "CLAUDE.local.md already exists in $TARGET_DIR. Overwrite? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cp "$TOOLS_REPO/CLAUDE.local.template.md" "$TARGET_DIR/CLAUDE.local.md"
    else
        echo "Skipping CLAUDE.local.md"
    fi
else
    cp "$TOOLS_REPO/CLAUDE.local.template.md" "$TARGET_DIR/CLAUDE.local.md"
fi

# Copy .claude directory (overwrite)
mkdir -p "$TARGET_DIR/.claude"
[ -f "$TOOLS_REPO/.claude/settings.local.json" ] && cp "$TOOLS_REPO/.claude/settings.local.json" "$TARGET_DIR/.claude/"
[ -d "$TOOLS_REPO/.claude/agents" ] && cp -r "$TOOLS_REPO/.claude/agents" "$TARGET_DIR/.claude/"
[ -d "$TOOLS_REPO/.claude/commands" ] && cp -r "$TOOLS_REPO/.claude/commands" "$TARGET_DIR/.claude/"
[ -d "$TOOLS_REPO/.claude/skills" ] && cp -r "$TOOLS_REPO/.claude/skills" "$TARGET_DIR/.claude/"
[ -d "$TOOLS_REPO/.claude/hooks" ] && cp -r "$TOOLS_REPO/.claude/hooks" "$TARGET_DIR/.claude/"

# Copy tests/CLAUDE.md (skip silently if exists)
if [ -f "$TOOLS_REPO/tests.CLAUDE.md" ] && [ ! -f "$TARGET_DIR/tests/CLAUDE.md" ]; then
    mkdir -p "$TARGET_DIR/tests"
    cp "$TOOLS_REPO/tests.CLAUDE.md" "$TARGET_DIR/tests/CLAUDE.md"
fi

# Copy local-notes structure (excluding memory.sqlite), empty report.md
if [ -d "$TOOLS_REPO/local-notes" ]; then
    mkdir -p "$TARGET_DIR/local-notes"
    find "$TOOLS_REPO/local-notes" -type f ! -name "memory.sqlite" | while read file; do
        rel_path="${file#$TOOLS_REPO/local-notes/}"
        target_file="$TARGET_DIR/local-notes/$rel_path"
        mkdir -p "$(dirname "$target_file")"
        cp "$file" "$target_file"
    done
    [ -f "$TARGET_DIR/local-notes/report.md" ] && > "$TARGET_DIR/local-notes/report.md"
fi

echo "Config copied successfully"
