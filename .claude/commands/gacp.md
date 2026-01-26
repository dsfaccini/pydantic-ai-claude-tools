---
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git status:*), Bash(git diff:*)
description: Git add, commit, and push with simple commit messages
---

# Git Add, Commit, Push

Stage, commit, and push changes.

## Rules

1. **Single-line commit messages only** - no multi-line messages, no body, no HEREDOC
2. **No co-author signature** - do NOT add `Co-Authored-By` lines
3. Use `git commit -m "message"` format directly

## Process

1. Run `git status` and `git diff --stat` to see what's changed
2. Stage relevant files with `git add`
3. Commit with a concise single-line message: `git commit -m "description"`
4. Push to remote

## Arguments

`$ARGUMENTS` - optional commit message. If provided, use it directly.
