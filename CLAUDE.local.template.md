# Local instructions

Welcome, if you're reading this we have started a new conversation or coding session, the following sections provide important context for you to get started.
Any TODOs and FILLOUT you find in this file should be completed after doing the relevant research.

## things you should know starting a new conversation

- this is a worktree of the [Pydantic AI repository](https://github.com/pydantic/pydantic-ai/) ("upstream") Pydantic's AI Agents framework to create and orchestrate agents.
- I am dsfaccini, a contributor, and you're my coding agent.
- the `main` branch is checked out at `/Users/david/projects/forks/pydantic-ai-main` (check what folder you're in)
    - you can use it to compare against it or create new branches
    - Note 1: double check the `main` branch is actually checked out 
    - Note 2: sync it with upstream before using it for comparisons or creating branches
- what day is it?
- which branch are you on?
- if there's no `.venv` run `make install`

## command preferences

- to solve merge conflicts run `git fetch upstream main && git merge upstream/main`
- use `uv run` or `source .venv/bin/activate python ...` to run python commands or scripts
- prefer the `gh` cli utility instead of `WebFetch`ing github.com URLs. Use `gh api|issue|pr` commands to read information from relevant issues and pull requests, including comments and reviews (note that comments and reviews are different commands! so comments won't include reviews).
- use `make format && make lint` at the end of all your changes to format the codebase
- prefer `git mv` to `mv` wherever possible to simplify PR review and conflict resolution

## repo rules

- avoid private methods in private modules
- avoid exposing private methods (i.e. methods from private modules) in public modules (by either aliasing them or using `__all__`)
- prefer exhaustive `elif` branches or `cases` with `assert_never` in the last branch instead of `pragma: no branch`
- never leave redundant - single-line comments that describe self-explanatory code like "increment i by 1" or "define function that does x"
- modifying the base `TextPart` and `ThinkingPart` classes in `messages.py` is forbidden
- don't add comments after `pragma`'s, this is not done anywhere in the codebase
- use single quotes always, even in code snippets in docs and `.md` files
- moreover, just don't use patterns that break with the codebase's conventions unless they're completely new patterns that have no equivalents
- imports inside methods or inside `if TYPE_CHECKING:` are exclusively for fixing circular import issues, and files that depend on optional packages, everything else is imported normally
- to reference docs in docstrings and `docs/**/*.md` files link to docs using MkDocs cross-reference `[link text](url)` format. Don't live `ai.pydantic.dev/...` URLs.
- **don't create single-use utilities**: avoid creating helper functions/methods that are only used in one place
- **type ignores**: don't simply use `# type: ignore` - first investigate the cause. if suppression is truly needed, use `# pyright: ignore[specificErrorCode]` with the specific error code (e.g., `reportPrivateUsage`, `reportUnknownMemberType`)
- **test assertions**: prefer `assert result == snapshot({...})` over multiple line-by-line asserts - snapshots show the full structure and are easier to read
- **annotations**: always annotate dicts/lists - pyright can't infer from literals:
    ```python
    # BAD - pyright infers dict[str, str]
    model.method({'tool_choice': 'auto'})

    # GOOD - explicit annotation
    settings: SomeModelSettings = {'tool_choice': 'auto'}
    model.method(settings)
    ```

## PR flow

- any PR that introduces new features or changes behavior requires at least one round of reviews
- because of this, we leave placeholders for docstrings and leave docs untouched until after we've addressed "requested changes" and we're sure the logic is correct
	- don't write docs/trings too early because the logic may change after reviews and we may not notice a mismatch between what's documented and what the code actually does

## project data

- BRANCH: TODO
- RELATED_ISSUE: TODO
- RELATED_PR: TODO
- LOCAL_INFO_FOLDER: `local-notes` (also called "info folder")
- MAIN_REPORT: `local-notes/report.md`

## specific notes about this issue/pr

### Issue Summary

TODO

### Current State

TODO

#### Research

TODO

### Key Files

- TODO
- ...

## handoff process

Use `/handoff` to prepare a handoff summary for the next agent/session.

## local reports

This is the worktree for the `BRANCH` branch, to fix `RELATED ISSUE` we opened pr `RELATED_PR`. We use `CLAUDE.local.md` for PR-specific info because `CLAUDE.md` is committed to the repo and we use git worktrees (each worktree has its own local file). Keep entries brief - only add key decisions/info not documented elsewhere.

We're storing all our interim reports, logs et al in the `LOCAL_INFO_FOLDER` folder. These reports are meant to stay local, they should never be added, they should never be committed, and they should not be referenced in any way.

We keep memories and relevant information in `LOCAL_INFO_FOLDER/MAIN_REPORT`. We don't extensively document each single decision or the state in the past unless it provides necessary/valuable information that lead to the curent state, for example, warnings about things we tried but didn't work, or simpler solutions we didn't implement because of a team decision.

## tools available 

you're encouraged to use the tools at your disposal to research and work more effectively

### Renaming variables with ast-grep cli

Always prefer `ast-grep` to rename symbols or move definitions (e.g. single tests or test groups) like this:

`sg -p 'validate_tool_choice' -r '_validate_tool_choice' -l py pydantic_ai_slim/ tests/`

run `ast-grep` to get a list of supported commands.

## about testing

### general testing guidelines

- unit tests are important, add them for minuciae that can be easily tested by them
- deeper changes that could have implications upstream, for instance: 
	- in the way the public API behaves
	- or how we send requests to the providers 
	- should be covered by integration tests
- if there are existing -- cassette based -- integration tests that cover the functionality, run them live against the API to verify they still pass
- otherwise create new ones.

#### dealing with long test files

- some test files are very long, this makes them difficult for you to parse
- spin up a research subagent to read large test files to answer any question you have about them, for example:
    - "is there already a test for X?"
    - "what it the codebase's convention for testing Y?"
    - "where do we add a test for Z?"

### test design

In general tests should resemble the way a user would use pydantic-ai's public API.

We have a two term goals that we try to forward in each PR:
1. getting rid of unit tests (by removing or translating them into VCR tests)
2. moving similar tests from different providers into centralized, parametrized test files

We take advantage of PRs to forward these two goals.

**Getting rid of unit tests** (VCR preference and design)

- remove unit tests when the logic they test is covered somewhere else
	- or translate them into VCR tests, taking advantage of the current topic of the PR
- the reason we prefer VCR tests is because provider APIs are the ultimate judges of whether a logic is right or wrong
- that doesn't mean we don't (unit) test internals
- we develop creative ways of tapping into internals to assert the specific logic we're introducing in a PR
- to summarize: our VCR test design both asserts the logic and showcases the interaction with the API by snapshotting the (trimmed) request/response structures

**Moving similar tests**

- currently we have very large files located at `tests/models/test_<provider>.py` that test all aspects for this provider
- these tests have unit tests from when we started, before we made the decision to become VCR maximalists
- so when adding new features we prefer creating feature-central test files (e.g. `test_multimodal_tool_retruns_vcr.py` for adding multimodal support in tool returns)
- in this test files we create a generalized `Case` class that includes sensible defaults for all cases but allows for specific params
- we run all these cases through one minimal but comprehensive test that asserts all the relevant aspects about the new feature + each cases specific logic
- things like exceptions, warnings, request hooks, internals and snapshots can be parametrized (snapshots by including the snapshot in the given case, not the central test function!)
- this is a great way of testing many providers in one file without being verbose and making it easy for code review (since a reviewer can just read case by case and easily spot whether expectations are realistic)

a long term goal would be to spot single tests in multiple providers that can be centralized in one of this case-based centralized VCR test files.

**Other rules**:
- fixtures or helpers for a specific test should be placed immediately before that test

### commands

For VCR cassette recording workflow, see `.claude/skills/vcr-test-recording.md`

### Experimentation/Debugging

Create one-time scripts that you can use to debug internal logic and use debuggers like PDB to understand what's happening when you run a certain piece of code. Don't delete the scripts after you're done, they may be useful in the future.

When "one-time" scripts prove useful to iterate and verify code changes or testing behaviors consider storing them as a claude code command or skill and even set up a hook for it in .claude/settings.local.md

### env vars

- for running experiments or tests we hit the APIs directly
- for this you can run `source .env && uv run python/pytest` followed by your command
- to run live API calls to vertex and bedrock please verify beforehand that they're properly set up
	- bedrock: appropriate home credentials may be set in `~/.aws/credentials/`, boto3 should pick those up automatically
		- otherwise ask for a fresh `AWS_BEARER_TOKEN_BEDROCK` and try an LLM call using curl
	- vertex: by checking `gcloud auth application-default print-access-token` is set up
		- additionally cheking `gcloud config get-value project` outputs `gen-lang-client-0498264908`
