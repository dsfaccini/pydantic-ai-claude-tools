#!/bin/bash
# Copies pydantic worktree config to target directory
# Usage: copy-pydantic-config.sh [target_dir]  (default: cwd)

set -e

TOOLS_REPO="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${1:-$(pwd)}"

echo "Copying config from $TOOLS_REPO to $TARGET_DIR"

# Copy from tools repo (overwrite)
[ -f "$TOOLS_REPO/.env" ] && cp "$TOOLS_REPO/.env" "$TARGET_DIR/"
[ -f "$TOOLS_REPO/.mcp.json" ] && cp "$TOOLS_REPO/.mcp.json" "$TARGET_DIR/"
cp "$TOOLS_REPO/CLAUDE.local.template.md" "$TARGET_DIR/CLAUDE.local.md"

# Copy .claude directory (overwrite)
mkdir -p "$TARGET_DIR/.claude"
[ -f "$TOOLS_REPO/.claude/settings.local.json" ] && cp "$TOOLS_REPO/.claude/settings.local.json" "$TARGET_DIR/.claude/"
[ -d "$TOOLS_REPO/.claude/agents" ] && cp -r "$TOOLS_REPO/.claude/agents" "$TARGET_DIR/.claude/"
[ -d "$TOOLS_REPO/.claude/commands" ] && cp -r "$TOOLS_REPO/.claude/commands" "$TARGET_DIR/.claude/"
[ -d "$TOOLS_REPO/.claude/skills" ] && cp -r "$TOOLS_REPO/.claude/skills" "$TARGET_DIR/.claude/"

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

# Symlink learnings (force overwrite)
[ -d "$TOOLS_REPO/learnings" ] && ln -sf "$TOOLS_REPO/learnings" "$TARGET_DIR/learnings"

echo "Config copied successfully"
