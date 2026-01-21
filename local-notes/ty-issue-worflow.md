# Ty issue workflow

- Run ty: `uvx ty check <path>`; if sandbox blocks uv cache, re-run with `--require-escalated` justification.
- Minimal repro first, no deps: inline TypedDicts/classes; keep ~10–30 LOC; omit `if __name__ == '__main__':`.
- Only add external deps if the behavior truly requires generated/vendor types and can’t be reproduced inline.
- Verify: rerun `uvx ty check <repro>.py`; ensure only the target diagnostic remains (trim extra warnings like `reveal_type`).
- Check existing ty issues first: use `gh search issues "<key diagnostic phrase>" --repo astral-sh/ty` with broad/technical wording (e.g., the rule name + main message fragment). If an existing issue matches, reply to the issue with a concise comment plus the minimal repro; do not open a new issue.
- Issue template (body):
  - Summary (1–2 lines).
  - `Playground link: PENDING`
  - Repro code block.
  - Run command block: `uvx ty check <repro>.py`
  - Actual result: diagnostic snippet.
  - Expected result: one line.
  - Notes: ty version (e.g., `0.0.4 via uvx ty check`), env if relevant.
- One issue per distinct symptom; prefer dep-free repros to reduce noise.

## Examples

See https://github.com/astral-sh/ty/issues/2178 and https://github.com/astral-sh/ty/issues/2140 as guides on wording and structure.
