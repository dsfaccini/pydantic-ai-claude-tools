#!/bin/bash
#
# moves the claude files to their corresponding locations in a new box
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.claude

if [ -f ~/.claude/CLAUDE.md ] && [ ! -L ~/.claude/CLAUDE.md ]; then
    echo "Backing up existing ~/.claude/CLAUDE.md to ~/.claude/CLAUDE.md.bak"
    mv ~/.claude/CLAUDE.md ~/x.claude/CLAUDE.md.bak
fi

ln -sf "$SCRIPT_DIR/CLAUDE.global.template.md" ~/.claude/CLAUDE.md
echo "Linked ~/.claude/CLAUDE.md -> $SCRIPT_DIR/CLAUDE.global.template.md"
