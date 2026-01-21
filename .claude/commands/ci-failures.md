---
description: Fetch and summarize CI test failures from GitHub Actions
---

Fetch CI failure logs:

!`.claude/skills/gh-cli-best-practices/get-latest-ci-failure.sh`

Based on the output above:
1. Summarize which test(s) failed and the error type
2. Determine if it's likely a flaky test (network timeout, connection error) or a real failure related to code changes
3. If it seems related to our changes, suggest what to investigate
