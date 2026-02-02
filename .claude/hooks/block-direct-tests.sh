#!/bin/bash
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Match test commands
if echo "$command" | grep -qE '(^|\s)(pytest|make test|uv run pytest)'; then
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
