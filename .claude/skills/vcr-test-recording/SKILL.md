---
name: vcr-test-recording
description: Workflow for recording and re-recording VCR cassettes for tests. Use when tests need HTTP recordings created or updated.
---

# VCR Test Recording Workflow

Use this skill when recording or re-recording VCR cassettes for tests.

## Prerequisites

- Ensure `.env` file exists with required API keys
- Tests must be using VCR for HTTP recording

## Workflow

### Step 1: Record cassettes

**For NEW cassettes** (tests that don't have recordings yet):
```bash
source .env && uv run pytest path/to/test.py::test_function_name --record-mode=new_episodes
```

**To REWRITE cassettes** (tests with updated expectations):
```bash
source .env && uv run pytest path/to/test.py::test_function_name --record-mode=rewrite
```

Multiple tests can be specified:
```bash
source .env && uv run pytest path/to/test.py::test_one path/to/test.py::test_two --record-mode=new_episodes
```

Do NOT use `-v` flag during recording.

### Step 2: Verify recordings

Run the same tests WITHOUT `--record-mode` to verify cassettes play back correctly:
```bash
source .env && uv run pytest path/to/test.py::test_function_name -v
```

Use `-v` here to see detailed output.

### Step 3: Review snapshots

If tests use `snapshot()` assertions:
- The test run in Step 2 auto-fills snapshot content
- Review the generated snapshot files to ensure they match expected output
- You only review - don't manually write snapshot contents
- Snapshots capture what the test actually produced, additional to explicit assertions

## Example: Full workflow

```bash
# 1. Record new cassette
source .env && uv run pytest tests/models/test_openai.py::test_chat_completion --record-mode=new_episodes

# 2. Verify playback and fill snapshots
source .env && uv run pytest tests/models/test_openai.py::test_chat_completion -v

# 3. Review any snapshot changes in the diff
git diff tests/
```

## Common flags

| Flag | When to use |
|------|-------------|
| `--record-mode=new_episodes` | New tests without cassettes |
| `--record-mode=rewrite` | Updated tests needing fresh recordings |
| `-v` | Only during verification (Step 2), never during recording |
