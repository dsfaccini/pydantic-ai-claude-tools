#!/bin/bash
# Tests for Claude Code hooks
set -euo pipefail

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

echo ""
echo "=== Results ==="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
