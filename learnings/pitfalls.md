# Pydantic-AI Review Pitfalls

Known patterns that commonly get flagged in code reviews. Check your changes against these before pushing.

## Code Style

### Imports
- **Inline imports**: Only use imports inside functions for:
  1. Circular import resolution
  2. Optional packages (e.g., `if TYPE_CHECKING:`)
  - Everything else should be at module level

### Comments
- **No redundant comments**: Don't add comments that just restate what the code does
  - Bad: `# Increment counter by 1`
  - Bad: `# Define function that fetches data`
  - Good: Comments that explain *why*, not *what*
- **No comments after pragmas**: `# pragma: no cover` should not have trailing comments

### Branching
- **Exhaustive branches**: Use `assert_never` in the final `else`/`case _:` instead of `# pragma: no branch`
  ```python
  # Good
  if x == 'a':
      ...
  elif x == 'b':
      ...
  else:
      assert_never(x)

  # Bad
  if x == 'a':  # pragma: no branch
      ...
  elif x == 'b':
      ...
  ```

### Module Design
- **No private methods in private modules**: If the module is private (`_module.py`), methods don't need underscore prefix
- **No exposing private methods in public modules**: Don't re-export `_private_func` via `__all__` or aliases
- **No single-use utilities**: Don't create helper functions used only once - inline the logic

## Types

### Type Annotations
- **No `any` types**: Use specific types or `object`/`Unknown` with validation
- **Specific type ignores**: Use `# pyright: ignore[specificCode]` not `# type: ignore`
  ```python
  # Bad
  foo()  # type: ignore

  # Good
  foo()  # pyright: ignore[reportUnknownMemberType]
  ```
- **Annotate dicts/lists**: Pyright can't infer types from literals
  ```python
  # Bad - pyright infers dict[str, str]
  model.method({'tool_choice': 'auto'})

  # Good
  settings: ModelSettings = {'tool_choice': 'auto'}
  model.method(settings)
  ```

## Documentation

### Language
- **No vague language**: Be definitive
  - Bad: 'you may want to'
  - Good: 'you should'
- **Link to sources**: Don't hardcode lists that will get outdated
  - Bad: 'Supported models: gpt-4, gpt-5, ...'
  - Good: 'See [model catalog](link) for supported models'

### Timing
- **No early docstrings**: Don't write docstrings until logic is finalized
  - PRs require at least one review round
  - Logic may change after reviews
  - Write docs/docstrings after 'CHANGES_REQUESTED' are addressed

## Testing

### Test Design
- **Prefer VCR over unit tests**: Provider APIs are the ultimate judges
  - Remove unit tests when logic is covered by integration tests
  - Translate unit tests to VCR when appropriate
- **Use snapshots**: Prefer `assert result == snapshot({...})` over multiple line-by-line asserts
- **Fixtures placement**: Put fixtures/helpers immediately before the test that uses them

### Test Centralization
- **Centralized parametrized tests**: For new features, prefer creating feature-central test files
  - Use a `Case` class with sensible defaults
  - Test many providers in one file
  - Parametrize snapshots in the case, not the test function

## PR Workflow

### Review Flow
1. Focus on logic correctness first
2. Leave docstring/docs placeholders
3. Address 'CHANGES_REQUESTED' reviews
4. Only then finalize documentation

### Commit Guidelines
- Use single quotes in code, docs, and markdown
- Follow codebase conventions - don't introduce new patterns unless necessary
