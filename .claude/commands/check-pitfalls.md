---
allowed-tools: Bash(git diff:*), Bash(git status:*), Bash(git log:*), Read, Glob, Grep
description: Scan diff for mechanical code issues (comments, imports, types, tests). Run after coding is done to fix minutiae before committing.
---

# Check Mechanical Pitfalls

Scan the current diff for concrete, pattern-matchable code issues. This is a post-coding lint pass — design/architecture issues are handled by `/pydantic-review`.

## Steps

### 1. Get Current Changes

Run `git diff HEAD` to see all uncommitted changes (staged + unstaged).

If there are no uncommitted changes, run `git diff HEAD~1` to check the last commit.

### 2. Scan Diff for Violations

For each category below, check **only added/modified lines** in the diff:

**Comments:**
- Redundant comments that restate what the code does (e.g. `# Increment i by 1` on `i += 1`)
- Comments after `# pragma:` directives (pragma should stand alone)
- Line number references in comments (e.g. "line 42", "L123", "lines 10-20")
- Comments referencing past state ("now supports...", "Original logic for...", "Previously this was...")

**Imports:**
- Inline imports inside function bodies — only acceptable for circular deps or optional packages
- Verify any inline import has a justifying comment or is under `TYPE_CHECKING`

**Types:**
- Unspecific `# type: ignore` — should be `# pyright: ignore[specific-code]`
- `Any` type annotations (`: Any`, `-> Any`, `list[Any]`)
- Unannotated dict/list literals passed directly to methods (should have explicit types)

**Tests:**
- Multiple `assert` statements on similar data that could use `snapshot()`
- Fixtures defined far from their tests (should be close or in conftest)
- Empty `snapshot()` calls that need `pytest --inline-snapshot=create` to populate

**Documentation:**
- Vague hedging language in docs/comments ("may want to", "might want to", "you could consider")
- Hardcoded lists in documentation that will go stale
- Early docstrings on functions whose logic isn't finalized yet

**Misc:**
- Missing `stacklevel` in `warnings.warn()` calls
- For-loop just to check `isinstance` on list items — use `any(isinstance(i, T) for i in items)`
- Double quotes for strings (pydantic-ai uses single quotes)

### 3. Report Findings

Output format:

```
## Pitfall Check Results

### [Category] - N issues

- **file.py** - [Pitfall description]
  Suggestion: [How to fix]

### Summary
- Total issues: N
- Categories affected: [list]
- Recommendation: [pass/review before pushing]
```

### 4. Suggest Fixes

For each issue found, provide:
1. The file path
2. The specific pitfall violated
3. A concrete fix suggestion

## Arguments

- No args: Check uncommitted changes
- `$ARGUMENTS` = 'last': Check last commit
- `$ARGUMENTS` = 'branch': Check all commits since main
