#!/usr/bin/env zsh
# Normalize snapshots in-place for one or more files after re-recording cassette tests.
# Usage:
#   ./normalize-snapshots.zsh tests/models/openai/test_tool_choice.py
#   ./normalize-snapshots.zsh tests/models/openai/*.py
set -euo pipefail

python3 - "$@" <<'PY'
import re, sys
from pathlib import Path

if len(sys.argv) < 2:
    print("usage: normalize-snapshots.zsh <file> [file...]", file=sys.stderr)
    raise SystemExit(2)

# Pattern to replace run_id='uuid' with run_id=IsStr()
RUN_ID = re.compile(r"run_id='[^']+'")

# Pattern to replace tool_call_id='pyd_ai_...' with tool_call_id=IsStr()
# Note: Google generates these client-side, so they differ between runs
TOOL_CALL_ID = re.compile(r"tool_call_id='pyd_ai_[^']+'")

# Pattern to replace tool_call_id='tooluse_...' with tool_call_id=IsStr()
# Note: Bedrock/Anthropic generates these server-side
TOOL_CALL_ID_BEDROCK = re.compile(r"tool_call_id='tooluse_[^']+'")

# Pattern to replace provider_response_id='...' with provider_response_id=IsStr()
PROVIDER_RESPONSE_ID = re.compile(r"provider_response_id='[^']+'")

# Pattern to replace datetime.datetime(...) with datetime(...)
# Supports one-level nested parens inside args (enough for tzinfo=TzInfo(UTC))
DTDT = re.compile(
    r"datetime\.datetime\("
    r"(?P<args>(?:[^()]|\([^()]*\))*)"
    r"\)"
)

# Pattern to replace TzInfo(UTC) with timezone.utc
TZINFO = re.compile(r"TzInfo\(UTC\)")

# Pattern to replace datetime.timezone.utc with timezone.utc
DT_TZ_UTC = re.compile(r"datetime\.timezone\.utc")

# Pattern to match timestamps in UserPromptPart to replace with IsNow
# Match: UserPromptPart(...timestamp=datetime(...)...) or timestamp=IsNow(...)
USER_PROMPT_TS = re.compile(
    r"(UserPromptPart\([^)]*?)"                      # Start of UserPromptPart(
    r"timestamp=datetime\([^)]+\)"                  # timestamp=datetime(...)
    r"([^)]*\))"                                    # Rest of the part
)

# Pattern to match timestamps in ToolReturnPart to replace with IsNow
TOOL_RETURN_TS = re.compile(
    r"(ToolReturnPart\([^)]*?)"                     # Start of ToolReturnPart(
    r"timestamp=datetime\([^)]+\)"                  # timestamp=datetime(...)
    r"([^)]*\))"                                    # Rest of the part
)

# Pattern to match ModelResponse timestamps for IsDatetime() replacement
# Matches: timestamp=datetime(2025, 12, ..., tzinfo=timezone.utc)
# Note: This pattern is applied AFTER UserPromptPart and ToolReturnPart patterns,
# so any remaining timestamp=datetime(...) should be in ModelResponse
MODEL_RESPONSE_TS = re.compile(
    r"timestamp=datetime\(\d{4},\s*\d+,\s*\d+,\s*\d+,\s*\d+,\s*\d+,\s*\d+,\s*tzinfo=timezone\.utc\)"
)

for fp in map(Path, sys.argv[1:]):
    if not fp.is_file():
        print(f"skip: not a file: {fp}", file=sys.stderr)
        continue

    s0 = fp.read_text(encoding="utf-8")
    s = s0

    # Order matters! Do broader replacements first.

    # 1. Replace datetime.datetime -> datetime
    n_dtdt = len(DTDT.findall(s))
    s = DTDT.sub(r"datetime(\g<args>)", s)

    # 2. Replace TzInfo(UTC) -> timezone.utc
    n_tzinfo = len(TZINFO.findall(s))
    s = TZINFO.sub("timezone.utc", s)

    # 3. Replace datetime.timezone.utc -> timezone.utc
    n_dt_tz = len(DT_TZ_UTC.findall(s))
    s = DT_TZ_UTC.sub("timezone.utc", s)

    # 4. Replace run_id='...' -> run_id=IsStr()
    n_runid = len(RUN_ID.findall(s))
    s = RUN_ID.sub("run_id=IsStr()", s)

    # 5. Replace tool_call_id='pyd_ai_...' -> tool_call_id=IsStr()
    n_tcid = len(TOOL_CALL_ID.findall(s))
    s = TOOL_CALL_ID.sub("tool_call_id=IsStr()", s)

    # 5b. Replace tool_call_id='tooluse_...' -> tool_call_id=IsStr() (Bedrock)
    n_tcid_bedrock = len(TOOL_CALL_ID_BEDROCK.findall(s))
    s = TOOL_CALL_ID_BEDROCK.sub("tool_call_id=IsStr()", s)
    n_tcid += n_tcid_bedrock

    # 6. Replace UserPromptPart timestamps with IsNow
    n_user_ts = len(USER_PROMPT_TS.findall(s))
    s = USER_PROMPT_TS.sub(r"\1timestamp=IsNow(tz=timezone.utc)\2", s)

    # 7. Replace ToolReturnPart timestamps with IsNow
    n_tool_ts = len(TOOL_RETURN_TS.findall(s))
    s = TOOL_RETURN_TS.sub(r"\1timestamp=IsNow(tz=timezone.utc)\2", s)

    # 8. Replace remaining timestamps (ModelResponse) with IsDatetime()
    n_model_ts = len(MODEL_RESPONSE_TS.findall(s))
    s = MODEL_RESPONSE_TS.sub("timestamp=IsDatetime()", s)

    # 9. Replace provider_response_id='...' -> provider_response_id=IsStr()
    n_prid = len(PROVIDER_RESPONSE_ID.findall(s))
    s = PROVIDER_RESPONSE_ID.sub("provider_response_id=IsStr()", s)

    if s != s0:
        fp.write_text(s, encoding="utf-8")
        print(f"{fp}: modified")
    else:
        print(f"{fp}: no changes")

    print(f"  datetime.datetime→datetime: {n_dtdt}")
    print(f"  TzInfo(UTC)→timezone.utc: {n_tzinfo}")
    print(f"  datetime.timezone.utc→timezone.utc: {n_dt_tz}")
    print(f"  run_id→IsStr(): {n_runid}")
    print(f"  tool_call_id→IsStr(): {n_tcid}")
    print(f"  UserPromptPart ts→IsNow: {n_user_ts}")
    print(f"  ToolReturnPart ts→IsNow: {n_tool_ts}")
    print(f"  ModelResponse ts→IsDatetime(): {n_model_ts}")
    print(f"  provider_response_id→IsStr(): {n_prid}")
PY
