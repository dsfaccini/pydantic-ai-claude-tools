# HuggingFace VCR Cassette Cache Issue

## Problem

When running tests with xdist (`-n auto`), HuggingFace tests fail because the VCR cassettes are missing the GET request for `inferenceProviderMapping`.

### Root Cause

1. The `huggingface_hub` library makes a GET request to `https://huggingface.co/api/models/{model}?expand=inferenceProviderMapping` before each API call
2. This function uses `functools.lru_cache`, so when cassettes are recorded sequentially, only the first test records the GET request
3. With xdist, each worker is a separate process without shared cache, so every test needs its own GET request in its cassette

### Affected Tests

`tests/models/huggingface/test_tool_choice.py` - all tests need the GET request in their cassettes

## Solution

Add a fixture to clear the cache before each test. Create `tests/models/huggingface/conftest.py`:

```python
import pytest

@pytest.fixture(autouse=True)
def clear_huggingface_provider_cache():
    """Clear the huggingface_hub provider mapping cache before each test.

    This ensures each test records/plays back its own GET request for
    inferenceProviderMapping, which is required when running with xdist
    since each worker is a separate process without shared cache.
    """
    from huggingface_hub.inference._providers._common import _fetch_inference_provider_mapping
    _fetch_inference_provider_mapping.cache_clear()
    yield
```

## Temporary Fix Applied

The GET request was manually added to 16 cassettes that were missing it. This works but is a band-aid - the conftest fixture above is the proper fix to prevent this from recurring when cassettes are re-recorded.

## Note

This should be implemented in a separate PR from the tool_choice work.
