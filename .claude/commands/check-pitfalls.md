---
allowed-tools: Bash(git diff:*), Bash(git status:*), Bash(git log:*), Read, Glob, Grep
description: Check current changes against known review pitfalls from pydantic-ai
---

# Check PR Pitfalls

Analyze current changes against known review patterns to catch issues before pushing.

## Steps

### 1. Load Pitfall Patterns

Read the pitfalls file. Check these locations in order:
1. `./learnings/pitfalls.md` (symlinked in worktree)
2. `~/projects/pydantic-ai-claude-tools/learnings/pitfalls.md` (fallback)

### 2. Get Current Changes

Run `git diff HEAD` to see all uncommitted changes (staged + unstaged).

If there are no uncommitted changes, run `git diff HEAD~1` to check the last commit.

### 3. Analyze Against Pitfalls

For each pitfall category, scan the diff for violations:

**Imports:**
- Search for `^+.*import ` inside function bodies (inline imports)
- Verify inline imports are for circular deps or optional packages

**Comments:**
- Check for added comments that just restate code
- Check for comments after `# pragma:`

**Types:**
- Search for `# type: ignore` without specific codes
- Search for `: Any` or `-> Any` type annotations

**Documentation:**
- Search for 'may want to', 'might want to' in docstrings
- Check for hardcoded lists in documentation

**Tests:**
- Check for multiple `assert` statements that could be a snapshot
- Check for fixtures defined far from their tests

### 4. Report Findings

Output format:

```
## Pitfall Check Results

### [Category] - N issues

- **file.py:123** - [Pitfall description]
  Suggestion: [How to fix]

### Summary
- Total issues: N
- Categories affected: [list]
- Recommendation: [pass/review before pushing]
```

### 5. Suggest Fixes

For each issue found, provide:
1. The file:line reference
2. The specific pitfall violated
3. A concrete fix suggestion

## Arguments

- No args: Check uncommitted changes
- `$ARGUMENTS` = 'last': Check last commit
- `$ARGUMENTS` = 'branch': Check all commits since main
