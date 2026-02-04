#!/bin/bash
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Allow if command sets CLAUDE_TEST_RUNNER=1 (used by test-runner subagent)
if echo "$command" | grep -qE '(^|\s)CLAUDE_TEST_RUNNER=1(\s|$)'; then
  exit 0
fi

# Match test commands as actual commands (not arguments)
# Matches: pytest, uv run pytest, make test
# At: start of command, or after && || ; |
if echo "$command" | grep -qE '(^|&&|\|\||;|\|)\s*(pytest|uv run pytest|make test)(\s|$)'; then
  cat >&2 << 'EOF'
BLOCKED: Don't run tests directly - use the test-runner agent instead.

Use the Task tool with:
- subagent_type: "test-runner"
- prompt: "Run: <your test command here>"

The test-runner agent will:
- Run the tests
- Diagnose failures (VCR, auth, code bugs)
- Return a concise summary
EOF
  exit 2
fi

exit 0
