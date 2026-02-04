#!/bin/bash
# Tests for Claude Code hooks
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$ROOT_DIR/.claude/hooks"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Test helper: expect command to be blocked (exit 2)
expect_blocked() {
  local hook="$1"
  local command="$2"
  local description="$3"

  local input="{\"tool_input\":{\"command\":\"$command\"}}"
  if echo "$input" | "$HOOKS_DIR/$hook" >/dev/null 2>&1; then
    echo -e "${RED}FAIL${NC}: $description"
    echo "  Expected: blocked (exit 2)"
    echo "  Got: allowed (exit 0)"
    ((FAILED++))
  else
    local exit_code=$?
    if [ "$exit_code" -eq 2 ]; then
      echo -e "${GREEN}PASS${NC}: $description"
      ((PASSED++))
    else
      echo -e "${RED}FAIL${NC}: $description"
      echo "  Expected: exit 2"
      echo "  Got: exit $exit_code"
      ((FAILED++))
    fi
  fi
}

# Test helper: expect command to be allowed (exit 0)
expect_allowed() {
  local hook="$1"
  local command="$2"
  local description="$3"

  local input="{\"tool_input\":{\"command\":\"$command\"}}"
  if echo "$input" | "$HOOKS_DIR/$hook" >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}: $description"
    ((PASSED++))
  else
    local exit_code=$?
    echo -e "${RED}FAIL${NC}: $description"
    echo "  Expected: allowed (exit 0)"
    echo "  Got: blocked (exit $exit_code)"
    ((FAILED++))
  fi
}

echo "=== Testing block-direct-tests.sh ==="
echo ""

# Commands with CLAUDE_TEST_RUNNER=1 should be ALLOWED (subagent bypass)
expect_allowed "block-direct-tests.sh" "CLAUDE_TEST_RUNNER=1 pytest tests/" "allows: pytest with CLAUDE_TEST_RUNNER=1"
expect_allowed "block-direct-tests.sh" "CLAUDE_TEST_RUNNER=1 uv run pytest tests/" "allows: uv run pytest with bypass"
expect_allowed "block-direct-tests.sh" "CLAUDE_TEST_RUNNER=1 make test" "allows: make test with bypass"
expect_allowed "block-direct-tests.sh" "CLAUDE_TEST_RUNNER=1 source .env && uv run pytest tests/" "allows: full VCR command with bypass"

# Commands that should be BLOCKED
expect_blocked "block-direct-tests.sh" "pytest tests/" "blocks: pytest tests/"
expect_blocked "block-direct-tests.sh" "pytest" "blocks: pytest (bare)"
expect_blocked "block-direct-tests.sh" "pytest -v tests/test_foo.py" "blocks: pytest with flags"
expect_blocked "block-direct-tests.sh" "uv run pytest tests/" "blocks: uv run pytest"
expect_blocked "block-direct-tests.sh" "uv run pytest -v --tb=short" "blocks: uv run pytest with flags"
expect_blocked "block-direct-tests.sh" "make test" "blocks: make test"
expect_blocked "block-direct-tests.sh" "source .env && pytest tests/" "blocks: pytest after source"
expect_blocked "block-direct-tests.sh" "cd foo && pytest" "blocks: pytest after cd"

# Commands that should be ALLOWED
expect_allowed "block-direct-tests.sh" "ls -la" "allows: ls"
expect_allowed "block-direct-tests.sh" "git status" "allows: git status"
expect_allowed "block-direct-tests.sh" "make build" "allows: make build (not test)"
expect_allowed "block-direct-tests.sh" "echo pytest" "allows: echo pytest (not actual pytest)"
expect_allowed "block-direct-tests.sh" "cat pytest.ini" "allows: cat pytest.ini"
expect_allowed "block-direct-tests.sh" "grep pytest pyproject.toml" "allows: grep pytest"
expect_allowed "block-direct-tests.sh" "vim tests/test_foo.py" "allows: editing test files"
expect_allowed "block-direct-tests.sh" "uv pip show pytest" "allows: uv pip show pytest"
expect_allowed "block-direct-tests.sh" "which pytest" "allows: which pytest"

echo ""
echo ""
echo "=== Testing enforce-uvrun.sh ==="
echo ""

# Test helper: expect command to be transformed
expect_transform() {
  local hook="$1"
  local input_cmd="$2"
  local expected_cmd="$3"
  local description="$4"

  local input="{\"tool_input\":{\"command\":\"$input_cmd\"}}"
  local output=$(echo "$input" | "$HOOKS_DIR/$hook" 2>/dev/null)
  local actual_cmd=$(echo "$output" | jq -r '.tool_input.command // ""')

  if [ "$actual_cmd" = "$expected_cmd" ]; then
    echo -e "${GREEN}PASS${NC}: $description"
    ((PASSED++))
  else
    echo -e "${RED}FAIL${NC}: $description"
    echo "  Expected: $expected_cmd"
    echo "  Got: $actual_cmd"
    ((FAILED++))
  fi
}

# Commands that should be TRANSFORMED
expect_transform "enforce-uvrun.sh" "python3 -c 'print(1)'" "uv run python -c 'print(1)'" "transforms: python3 -c to uv run python -c"
expect_transform "enforce-uvrun.sh" "cd foo && python3 -c 'x'" "cd foo && uv run python -c 'x'" "transforms: python3 -c after &&"

# Commands that should NOT be transformed (pass through)
expect_transform "enforce-uvrun.sh" "python3 script.py" "python3 script.py" "no transform: python3 without -c"
expect_transform "enforce-uvrun.sh" "ls -la" "ls -la" "no transform: unrelated command"
expect_transform "enforce-uvrun.sh" "echo python3 -c" "echo python3 -c" "no transform: python3 -c as argument"

echo ""
echo "=== Results ==="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
