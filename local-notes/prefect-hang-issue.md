# Prefect Tests Hang with Nested Subflows

## Summary

Prefect tests hang when running tests that create nested subflows (multiple `PrefectAgent.run()` calls within a single `@flow`). The first subflow **completes successfully**, but the second subflow hangs waiting for a connection from httpcore's pool, eventually hitting `PoolTimeout`.

## Environment

- Python 3.12.10
- Prefect 3.4.21 (lowest-direct) and 3.6.9 (highest) - **both affected**
- httpcore 1.0.9, httpx 0.28.1
- VCRpy 8.1.1, pytest-xdist 3.6.1/3.8.0

## Reproduction

```bash
# This hangs (nested subflows):
uv run pytest tests/test_prefect.py::test_multiple_agents -v

# This also hangs:
uv run --all-extras --resolution lowest-direct pytest tests/test_prefect.py::test_multiple_agents -v
```

The problematic test pattern:
```python
@flow(name='test_multiple_agents')
async def run_multiple_agents():
    result1 = await simple_prefect_agent.run(...)   # subflow 1 - COMPLETES OK
    result2 = await complex_prefect_agent.run(...)  # subflow 2 - HANGS HERE
    return result1.output, result2.output
```

## Key Finding: First Subflow Succeeds, Second Hangs

From the debug log (see `prefect-hang-log.txt`):

```
17:00:16.903 | Flow run 'blue-clam' - Beginning flow run for 'test_multiple_agents'
17:00:16.962 | Flow run 'sociable-numbat' - Beginning subflow run for 'simple_agent Run'
17:00:16.971 | Task run 'Model Request: gpt-4o-f9a' - Created task run
17:00:17.651 | Task run 'Model Request: gpt-4o-f9a' - Finished in state Completed()
17:00:17.665 | Flow run 'sociable-numbat' - Finished in state Completed()
                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                           FIRST SUBFLOW COMPLETES SUCCESSFULLY

[60 second hang here - no logs]

17:01:17.682 | Encountered retryable exception: httpcore.PoolTimeout
             | httpcore/_async/connection_pool.py:35 in wait_for_connection
             |   await self._connection_acquired.wait(timeout=timeout)
```

The connection pool becomes exhausted after the first subflow, preventing the second from acquiring a connection.

## What We Tested

| Test | Result |
|------|--------|
| `test_simple_agent_run_in_flow` alone | ✅ PASS |
| `test_complex_agent_run_in_flow` alone | ✅ PASS (recent run) |
| `test_simple` + `test_complex` together | ✅ PASS |
| `test_multiple_agents` (nested subflows) | ❌ HANG → PoolTimeout |
| With `--record-mode=none` (VCR disabled) | ❌ Still hangs |
| With xdist `-n auto --dist=loadgroup` | ❌ Still hangs |
| Prefect 3.4.21 vs 3.6.9 | ❌ Both hang |

## What We Ruled Out

- **Prefect version**: Hangs on both 3.4.21 and 3.6.9
- **VCR recording mode**: `--record-mode=none` doesn't help
- **xdist**: Happens with and without parallel execution
- **Resolution strategy**: Both `highest` and `lowest-direct` affected
- **Individual subflows**: Each works fine in isolation

## What We Haven't Tried

- Running without VCR entirely (can't easily disable due to test structure)
- Increasing httpcore connection pool limits
- Mocking the MCP server (complex_agent uses MCPServerStdio subprocess)
- Custom Prefect client with different httpx settings
- Checking if connections are being properly released after first subflow

## Error Details

Stack trace shows VCR in the path despite `ignore_localhost: True`:
```
vcr/stubs/httpcore_stubs.py:159 in _vcr_handle_async_request
  real_response = await real_handle_async_request(self, real_request)
httpcore/_async/connection_pool.py:35 in wait_for_connection
  await self._connection_acquired.wait(timeout=timeout)
httpcore.PoolTimeout
```

## Likely Root Cause

The httpcore connection pool is not releasing connections after the first subflow completes. This could be:

1. **VCR httpcore stubs interfering** - VCR wraps httpcore even for localhost (despite `ignore_localhost`), and may not properly release connections
2. **Connection leak on async completion** - Related to [httpcore#149](https://github.com/encode/httpcore/issues/149) where connections leak on CancelledError/BaseException
3. **Prefect client not closing connections** - The Prefect client may hold connections open between subflows

## Related Issues

- [httpcore#149](https://github.com/encode/httpcore/issues/149) - Connection leak on CancelledError
- [prefect#12877](https://github.com/PrefectHQ/prefect/issues/12877) - Dask task scheduling hangs with PoolTimeout
- [httpx#2138](https://github.com/encode/httpx/discussions/2138) - Connection pool closed while requests in-flight
