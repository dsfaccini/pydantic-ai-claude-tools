---
allowed-tools: Bash(gh pr view:*), Bash(gh api:*), Bash(gh pr list:*), Bash(mkdir:*), Bash(mv:*), Bash(ls:*), Bash(git branch:*), Bash(source .venv/bin/activate && python:*), Read, Write, Glob, AskUserQuestion
description: Fetch CHANGES_REQUESTED reviews from PR, save to local-notes, clean up verbosity, organize chronologically
---

# Fetch and Organize PR Reviews

Fetch the latest CHANGES_REQUESTED review from a GitHub PR and save it to local-notes.

## Determine the PR

1. If `$ARGUMENTS` is provided, use that as the PR number
2. Otherwise, get the current branch with `git branch --show-current`
3. Find the PR for that branch using `gh pr list --head <branch> --json number`
4. If no PR is found, ask the user for the PR number

## Fetch Reviews (Two-Step Process)

### Step 1: Get all reviews to find the latest CHANGES_REQUESTED one

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/reviews
```

This returns review metadata including:
- `id` (numeric review ID like `3573339455`)
- `submitted_at` (timestamp)
- `state` (CHANGES_REQUESTED, APPROVED, etc.)
- `user.login` (reviewer name)

Find the most recent review with `state: 'CHANGES_REQUESTED'` by sorting by `submitted_at`.

### Step 2: Get comments for that specific review

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments --paginate
```

Filter comments by `pull_request_review_id` matching the review ID from Step 1.

**IMPORTANT:** Use `--paginate` to get all comments. Filter in Python to avoid jq escaping issues:

```bash
source .venv/bin/activate && gh api repos/{owner}/{repo}/pulls/{pr}/comments --paginate | python -c "
import json, sys
data = json.load(sys.stdin)
REVIEW_ID = <review_id_from_step_1>
comments = [c for c in data if c.get('pull_request_review_id') == REVIEW_ID]
# Process comments...
"
```

## Save with Review Date Timestamp

1. Create `local-notes/` if it doesn't exist
2. Extract the review date from `submitted_at` (format: YYYYMMDD)
3. Save to `local-notes/pr-<number>-reviews-<YYYYMMDD>.md`
4. If file already exists for that date, append time: `pr-<number>-reviews-<YYYYMMDD>-<HHMMSS>.md`

## Markdown Output Format

Save as a readable markdown file with:

1. **Header** with review metadata (ID, reviewer, date, state, comment count)
2. **Comments grouped by file** - each file gets a section
3. **Key themes summary** at the end - synthesize the main feedback points

Example structure:
```markdown
# PR #3611 Review Comments - 2025-12-12

**Review ID:** 3573339455
**Reviewer:** DouweM
**Date:** 2025-12-12T20:21:53Z
**State:** CHANGES_REQUESTED
**Total Comments:** 34

---

## Comments by File

### path/to/file.py (N comments)

#### Comment 1
**Line:** 123
**Created:** 2025-12-12T19:36:19Z

Comment body here...

---

## Key Themes from Review

1. **Theme 1** - Brief summary
2. **Theme 2** - Brief summary
```

## Cleanup Rules

- Keep: comment body, file path, line number, timestamp
- Remove: GitHub API metadata, user avatars, reaction counts, URLs (except html_url)
- Sort comments by `created_at` within each file

## Final Output

Report:
1. File saved: `local-notes/pr-<number>-reviews-<YYYYMMDD>.md`
2. Review summary: reviewer, date, comment count
3. Files with most comments (top 3)
