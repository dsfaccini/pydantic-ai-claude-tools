#!/usr/bin/env bash
# Replace ThinkingPart signature string literals with IsStr() using ast-grep.

set -euo pipefail

AST_GREP_BIN="${AST_GREP_BIN:-}"
DRY_RUN=0
PATHS=()

usage() {
  cat <<'USAGE'
Usage: replace_thinking_signatures.sh [--dry-run] [--ast-grep-bin PATH] [PATH ...]

Options:
  --dry-run           Show how many replacements would be made and net character change.
  --ast-grep-bin PATH Explicit ast-grep binary (otherwise tries ast-grep then sg).
  PATH                Files or directories to scan (defaults to .).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --ast-grep-bin)
      AST_GREP_BIN="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      PATHS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#PATHS[@]} -eq 0 ]]; then
  PATHS=(.)
fi

if [[ -z "$AST_GREP_BIN" ]]; then
  if command -v ast-grep >/dev/null 2>&1; then
    AST_GREP_BIN="ast-grep"
  elif command -v sg >/dev/null 2>&1; then
    AST_GREP_BIN="sg"
  else
    echo "error: ast-grep not found (set AST_GREP_BIN or install ast-grep/sg)" >&2
    exit 1
  fi
fi

RULE=$'id: replace-thinking-signature\nlanguage: Python\nrule:\n  pattern: "ThinkingPart($$$BEFORE, signature=$SIG, $$$AFTER)"\nfix: "ThinkingPart($$$BEFORE, signature=IsStr(), $$$AFTER)"'

TMP="$(mktemp)"
"$AST_GREP_BIN" scan --inline-rules "$RULE" --json=stream "${PATHS[@]}" >"$TMP" || true

python3 - <<'PY' "$TMP" "$DRY_RUN"
import json, sys
from collections import defaultdict
from pathlib import Path

tmp_path = Path(sys.argv[1])
dry_run = sys.argv[2] == "1"

if not tmp_path.exists() or tmp_path.stat().st_size == 0:
    print("No signature string literals found.")
    sys.exit(0)

matches = []
for line in tmp_path.read_text().splitlines():
    try:
        data = json.loads(line)
    except json.JSONDecodeError:
        continue
    sig = data.get("metaVariables", {}).get("single", {}).get("SIG", {}).get("text", "")
    if not sig or sig in ("None", "null") or sig[0] not in ("'", '"'):
        continue
    offs = data.get("replacementOffsets")
    repl = data.get("replacement")
    if not offs or repl is None:
        continue
    matches.append(
        (
            Path(data.get("file", "")),
            int(offs["start"]),
            int(offs["end"]),
            repl,
            sig,
        )
    )

if not matches:
    print("No signature string literals found.")
    sys.exit(0)

per_file = defaultdict(list)
for m in matches:
    per_file[m[0]].append(m)

total = sum(len(v) for v in per_file.values())
delta = sum(len(sig) - len("IsStr()") for _, _, _, _, sig in matches)

if dry_run:
    print(f"Replacements found: {total}")
else:
    # Apply replacements per file in reverse order to keep offsets valid.
    for file, items in per_file.items():
        data = file.read_bytes()
        for _, start, end, repl, _ in sorted(items, key=lambda t: t[1], reverse=True):
            data = data[:start] + repl.encode() + data[end:]
        file.write_bytes(data)
    print(f"Replacements applied: {total}")

for file, items in sorted(per_file.items()):
    print(f"- {file}: {len(items)}")

if delta > 0:
    print(f"Net characters reduced: {delta}")
elif delta < 0:
    print(f"Net characters added: {abs(delta)}")
else:
    print("Net character change: 0")

PY

rm -f "$TMP"
