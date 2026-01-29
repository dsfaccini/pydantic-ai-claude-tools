# CLAUDE.md

## Quick Reference

```bash
uv run pytest tests/path.py::test_name -v   # Run specific test
pre-commit run --all-files                   # All checks (lint, type, format)
make test                                    # Full test suite
make docs-serve                              # Local docs at localhost:8000
```

## Bug Fix Workflow

**Always create an MRE before implementing fixes.**

### 1. Create MRE scripts

Create `local-notes/mre/` folder with two scripts:

**`mre_release.py`** - tests against PyPI release:
```python
# /// script
# dependencies = ['pydantic-ai']
# ///
"""MRE for issue #XXXX - [brief description]
Expected: [what should happen]
Actual: [what happens instead]
"""
# Minimal reproduction code here
```

**`mre_branch.py`** - tests against local branch:
```python
# /// script
# dependencies = ['pydantic-ai @ file:///PATH/TO/WORKTREE']
# ///
"""MRE for issue #XXXX - tests fix"""
# Same code as mre_release.py
```

### 2. Verify bug exists

```bash
uv run local-notes/mre/mre_release.py
```

**STOP if bug doesn't reproduce** - investigate or ask for clarification.

### 3. Implement fix

### 4. Verify fix works

```bash
uv run local-notes/mre/mre_release.py  # Still shows bug (PyPI)
uv run local-notes/mre/mre_branch.py   # Shows fix (local)
```

## Feature Workflow

1. Check for existing similar functionality (grep codebase)
2. Follow existing patterns in the same area
3. Write tests alongside implementation
4. Update docs in `docs/` if user-facing

## Code Navigation

| Problem area | Start here |
|-------------|-----------|
| Agent behavior | `pydantic_ai_slim/pydantic_ai/agent.py`, `_agent_graph.py` |
| Tool execution | `tools.py`, `toolsets/` |
| Model/provider bugs | `models/<provider>.py` |
| Streaming | `models/<provider>.py` → `stream_*` methods |
| Output validation | `output.py`, `result.py` |
| Message format | `messages.py` |

### Execution flow

```
User code → Agent.run() → _agent_graph.py → models/<provider>.py
                ↓
    UserPromptNode → ModelRequestNode → CallToolsNode
```

## Testing

### Writing tests

- Use `TestModel` for deterministic tests (no API calls)
- Use VCR cassettes for integration tests with real APIs
- Fixtures live in `tests/conftest.py`

### VCR cassette recording

**Record new cassette:**
```bash
source .env && uv run pytest tests/path.py::test_name --record-mode=new_episodes
```

**Re-record existing cassette:**
```bash
source .env && uv run pytest tests/path.py::test_name --record-mode=rewrite
```

**Verify playback:**
```bash
uv run pytest tests/path.py::test_name -v
```

Notes:
- Don't use `-v` during recording, only during verification
- `.env` must contain required API keys
- Write `snapshot()` empty, run tests to fill them

### Coverage

100% coverage required. Check with `make test`.

## Code Conventions

### Rules to follow

1. **Use `assert_never()`** - not `# pragma: no branch`
2. **No `stacklevel`** in `warnings.warn()` calls
3. **Backticks in docstrings** - wrap code refs: `` `my_function` ``
4. **Use `any()` for type checks**:
   ```python
   # Bad
   for item in result:
       if isinstance(item, SomeType):
           raise Error(...)

   # Good
   if any(isinstance(i, SomeType) for i in result):
       raise Error(...)
   ```
5. **Empty snapshots** - write `snapshot()`, let pytest fill it

### Renaming classes

Add deprecation warning, keep old name as alias:

```python
from typing_extensions import deprecated

class NewClass: ...

@deprecated("Use `NewClass` instead.")
class OldClass(NewClass): ...
```

Add deprecation test:
```python
def test_old_class_is_deprecated():
    with pytest.warns(DeprecationWarning, match="Use `NewClass` instead."):
        OldClass()
```

Update docs to reference only `NewClass`.

## Common Pitfalls

- **Don't modify message format** without checking all providers
- **Async/sync parity** - changes to async must be mirrored in sync
- **Generic types** - `Agent[DepsT, OutputT]` must stay compatible
- **Don't add deps to slim** - `pydantic_ai_slim` has minimal dependencies
- **No pragma trailing comments** - pragma statements stand alone

## PR Checklist

- [ ] Tests pass: `uv run pytest tests/ -v`
- [ ] Types pass: `pre-commit run --all-files`
- [ ] 100% coverage on changed code
- [ ] Docs updated if user-facing
- [ ] MRE scripts verify fix (for bug fixes)
- [ ] No convention violations (review against Code Conventions above)

## Project Structure

```
pydantic_ai_slim/     # Core framework (minimal deps)
├── pydantic_ai/
│   ├── agent.py      # Main Agent class
│   ├── _agent_graph.py
│   ├── models/       # Provider implementations
│   ├── tools.py
│   └── messages.py
pydantic_evals/       # Evaluation system
pydantic_graph/       # Graph execution engine
tests/
├── conftest.py       # Shared fixtures
├── cassettes/        # VCR recordings
docs/                 # MkDocs source
```

## Key Patterns

### Dependency injection

```python
@dataclass
class MyDeps:
    database: DatabaseConn

agent = Agent('openai:gpt-4o', deps_type=MyDeps)

@agent.tool
async def get_data(ctx: RunContext[MyDeps]) -> str:
    return await ctx.deps.database.fetch_data()
```

### Type-safe agents

```python
class OutputModel(BaseModel):
    result: str

agent: Agent[MyDeps, OutputModel] = Agent(
    'openai:gpt-4o',
    deps_type=MyDeps,
    output_type=OutputModel
)
```

## Docs Development

```bash
export DYLD_FALLBACK_LIBRARY_PATH="/opt/homebrew/lib"  # macOS only
make docs-serve
```

Link to API refs in markdown:
```markdown
The [`Agent`][pydantic_ai.agent.Agent] class is the main entry point.
```
