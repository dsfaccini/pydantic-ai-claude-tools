---
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git status:*), Bash(git diff:*), Bash(git log:*), mcp__openmemory__openmemory_query, mcp__openmemory__openmemory_store, mcp__openmemory__openmemory_list
description: Prepare a handoff summary for the next agent/session
---

# Handoff Process

Prepare a comprehensive handoff for the next agent or coding session.

## Gather Context

1. Read `CLAUDE.local.md` to understand the current PR/issue context
2. Read the main report at the path specified in `MAIN_REPORT`
3. Check recent git activity: `git status`, `git log --oneline -10`
4. Query openmemory for relevant memories about this work

## Prepare Handoff Summary

Write a handoff summary to `local-notes/handoff.md` with these sections:

### What Has Been Done
- Summarize completed work
- Reference specific commits if relevant

### What Remains To Be Done
- List pending tasks
- Note any blockers or dependencies

### Key Files and Resources
- Link to relevant files (use relative paths)
- Link to PR, issue, and any external resources

### Questions and Uncertainties
- List any open questions that need user input
- Note any technical uncertainties

### Memory and Report Status
- Confirm memories are up to date (update if needed)
- Confirm main report reflects current state (update if needed)

## Update Memories

Store a brief handoff memory in openmemory with:
- Current state summary
- Next steps
- Any critical context the next session needs

## Output

Show the user the handoff summary and confirm memories/reports are updated.