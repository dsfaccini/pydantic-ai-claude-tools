#!/bin/bash
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Replace python3 -c with uv run python -c
if echo "$command" | grep -qE '(^|&&|\|\||;|\|)\s*python3 -c'; then
  new_command=$(echo "$command" | sed 's/python3 -c/uv run python -c/g')
  echo "$input" | jq --arg cmd "$new_command" '.tool_input.command = $cmd'
  exit 0
fi

# Pass through unchanged
echo "$input"
exit 0
