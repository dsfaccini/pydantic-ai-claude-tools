# Prefect Test Hang Investigation

## Problem Statement

The prefect tests hang and timeout in CI when run with:
```bash
uv run --all-extras --resolution lowest-direct coverage run -m pytest --durations=100 -n auto --dist=loadgroup
```

The tests were previously skipped with a TODO comment indicating they hang with the latest versions of all packages.

## Environment Tested

| Resolution | Prefect | VCRpy | httpcore | httpx | pytest | pytest-xdist |
|------------|---------|-------|----------|-------|--------|--------------|
| highest    | 3.6.9   | 8.1.1 | 1.0.9    | 0.28.1| 9.0.2  | 3.8.0        |
| lowest-direct | 3.4.21 | 8.1.1 | 1.0.9 | 0.28.1| 9.0.0 | 3.6.1       |

Python: 3.12.10

---

## DEFINITE FINDINGS (Verified by Testing)

### Finding 1: `test_multiple_agents` Hangs on BOTH Prefect Versions

**Verified**: The hang is NOT specific to Prefect version.

```bash
# With highest resolution (Prefect 3.6.9) - HANGS
timeout 60 uv run coverage run -m pytest tests/test_prefect.py::test_multiple_agents -v
# Result: Timed out

# With lowest-direct (Prefect 3.4.21) - ALSO HANGS
timeout 90 uv run --all-extras --resolution lowest-direct coverage run -m pytest tests/test_prefect.py::test_multiple_agents -v
# Result: Timed out
```

### Finding 2: Simple Tests Pass on Both Resolutions

```bash
# highest resolution
timeout 30 uv run coverage run -m pytest tests/test_prefect.py::test_simple_agent_run_in_flow -v
# Result: PASSED in ~16 seconds

# lowest-direct
timeout 60 uv run --all-extras --resolution lowest-direct coverage run -m pytest tests/test_prefect.py::test_simple_agent_run_in_flow -v
# Result: PASSED in ~23 seconds
```

### Finding 3: Two Sequential Tests Pass (Without the Problematic One)

```bash
timeout 60 uv run coverage run -m pytest tests/test_prefect.py::test_simple_agent_run_in_flow tests/test_prefect.py::test_complex_agent_run_in_flow -v
# Result: 2 PASSED in ~16 seconds
```

### Finding 4: The Same Two Tests Pass With xdist

```bash
timeout 90 uv run coverage run -m pytest tests/test_prefect.py::test_simple_agent_run_in_flow tests/test_prefect.py::test_complex_agent_run_in_flow -v -n 2 --dist=loadgroup
# Result: 2 PASSED in ~24 seconds (both on gw0 due to loadgroup)
```

### Finding 5: `test_complex_agent_run_in_flow` Alone ALSO Times Out

```bash
timeout 30 uv run coverage run -m pytest tests/test_prefect.py::test_complex_agent_run_in_flow -v
# Result: FAILED with TerminationSignal after timeout
```

**Key observation from stack trace**:
- All tasks COMPLETE successfully (logs show "Finished in state Completed()")
- The hang occurs AFTER work is done, during `handle_success` → `set_state` → `propose_state`
- The Prefect temporary server gets killed by timeout before flow reports final state
- Error: `ConnectError: All connection attempts failed`

### Finding 6: But Two Tests Together Pass (Including complex_agent)

This is CRITICAL: `test_simple_agent_run_in_flow` + `test_complex_agent_run_in_flow` together PASS, but individually `test_complex_agent_run_in_flow` times out.

**Implication**: The session-scoped `prefect_test_harness` fixture's startup time is being amortized across tests when run together, but times out when run alone.

### Finding 7: VCR Appears in Stack Trace Despite `ignore_localhost: True`

From the error trace when running with xdist:
```
File ".venv/.../vcr/stubs/httpcore_stubs.py", line 133, in _vcr_handle_async_request
    real_response = await real_handle_async_request(self, real_request)
...
asyncio.exceptions.CancelledError
```

VCR config has `'ignore_localhost': True` but VCR still intercepts the request pipeline.

### Finding 8: The CancelledError Occurs in httpcore Connection Pool

Error location:
```python
# httpcore/_async/connection_pool.py:35
await self._connection_acquired.wait(timeout=timeout)
# → asyncio.exceptions.CancelledError
```

This is a known issue with httpcore - see [httpcore Issue #149](https://github.com/encode/httpcore/issues/149).

### Finding 9: Running with `--record-mode=none` Still Hangs

```bash
timeout 60 uv run coverage run -m pytest tests/test_prefect.py::test_multiple_agents -v --record-mode=none
# Result: Still times out
```

VCR's record mode doesn't affect the hang.

---

## What Makes `test_multiple_agents` Special

Looking at the test code:
```python
async def test_multiple_agents(allow_model_requests: None) -> None:
    @flow(name='test_multiple_agents')
    async def run_multiple_agents() -> tuple[str, Response]:
        result1 = await simple_prefect_agent.run(...)  # Creates subflow "simple_agent Run"
        result2 = await complex_prefect_agent.run(...) # Creates subflow "complex_agent Run"
        return result1.output, result2.output
```

This creates **nested subflows** - each `PrefectAgent.run()` call wraps execution in a `@flow` decorator. So we have:
1. Outer flow: `test_multiple_agents`
2. First subflow: `simple_agent Run`
3. Second subflow: `complex_agent Run` (which also uses MCPServerStdio subprocess)

---

## THEORIES (Unverified)

### Theory A: Subflow Nesting + httpcore Connection Pool Exhaustion
**Likelihood: HIGH**

When creating nested subflows, Prefect's client makes HTTP requests to the test harness server. The httpcore connection pool may be getting exhausted or hitting contention, especially when:
1. Multiple subflows are created in sequence
2. The first subflow's connections aren't properly released before the second starts
3. VCR's httpcore stubs are in the request path (even if they pass-through for localhost)

Evidence:
- Error is specifically `CancelledError` in `wait_for_connection`
- The issue manifests with nested flows but not flat flows
- Related to known httpcore Issue #149 about connection leaks on CancelledError

### Theory B: VCR httpcore Stubs Interfere with Async Event Loop
**Likelihood: MEDIUM**

Even though `ignore_localhost: True`, VCR still installs httpcore stubs that wrap all requests. These stubs may be interfering with asyncio event handling, particularly in the connection pool's async waiting logic.

Evidence:
- VCR appears in stack trace despite localhost ignore
- `--record-mode=none` doesn't help
- CancelledError occurs in async wait

### Theory C: MCP Server Subprocess Interaction
**Likelihood: LOW-MEDIUM**

The `complex_agent` uses `MCPServerStdio('python', ['-m', 'tests.mcp_server'], timeout=20)` which spawns a subprocess. This may be interfering with:
- The asyncio event loop
- Signal handling (the timeout uses SIGTERM)
- Resource cleanup

Evidence:
- Only complex_agent tests hang (uses MCP)
- Simple agent tests pass

### Theory D: Test Harness Startup Time
**Likelihood: MEDIUM**

The `prefect_test_harness(server_startup_timeout=60)` may be taking significant time to start. When tests are run together, this time is amortized. When run alone with a 30-second external timeout, there's not enough time.

Evidence:
- Simple test takes ~16s, complex takes longer
- Running two tests together works
- Running one alone times out

---

## Known Related Issues

1. **httpcore Issue #149**: [AsyncConnectionPool leaks connection on CancelledError](https://github.com/encode/httpcore/issues/149)
   - CancelledError is BaseException not Exception
   - Connections aren't properly returned to pool when cancelled

2. **Prefect Issue #12877**: [Dask task scheduling hangs with PoolTimeout](https://github.com/PrefectHQ/prefect/issues/12877)
   - Similar symptoms: hang then CancelledError
   - Related to connection pool exhaustion

3. **httpx Discussion #2138**: [Connection pool closed while requests in-flight](https://github.com/encode/httpx/discussions/2138)
   - When tasks are cancelled, connection pool can get into bad state

---

## Next Steps to Investigate

1. [ ] Create a minimal reproduction without VCR to isolate if VCR is a factor
2. [ ] Test with httpcore connection pool limits increased
3. [ ] Add instrumentation to see exactly where the hang occurs
4. [ ] Check if there's a Prefect client connection pooling configuration
5. [ ] Try running MCP tests without the subprocess (mock the MCP server)
6. [ ] File issue with Prefect if this is reproducible in their test harness

---

## File References

- Test file: `tests/test_prefect.py`
- VCR config: `tests/conftest.py:300` (vcr_config function)
- Prefect agent: `pydantic_ai_slim/pydantic_ai/durable_exec/prefect/_agent.py`
- Cache policies: `pydantic_ai_slim/pydantic_ai/durable_exec/prefect/_cache_policies.py`
- Test harness fixture: `tests/test_prefect.py:101-105`
