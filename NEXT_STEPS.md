# Next Steps: Session Init Workflow

## Goal

Auto-trigger a structured onboarding flow when starting a new Claude Code session for Pydantic AI work.

## Proposed Flow

1. **User starts session** (via shell alias or wrapper)
2. **Prompt for issue link** - required input, e.g. `https://github.com/pydantic/pydantic-ai/issues/123`
3. **Auto-research phase**:
   - Subagent 1: Research the GitHub issue (description, comments, linked PRs, maintainer discussion)
   - Subagent 2: Research relevant codebase areas (find related files, understand current implementation)
   - Subagent 3: Research external resources if needed (docs, related issues, external APIs)
4. **Fill out CLAUDE.local.md** with gathered context:
   - BRANCH, RELATED_ISSUE, RELATED_PR
   - Issue Summary
   - Key Files
   - Current State / Research notes
5. **Generate implementation plan** with:
   - Proposed approach
   - Clarifying questions for maintainers
   - Potential blockers or decisions needed

## Implementation Options

### Option A: Shell Alias + Init Skill

```bash
# In ~/.zshrc or ~/.bashrc
pydantic-claude() {
    cd "$1"  # worktree path
    read -p "Issue link: " issue_link
    claude --init-prompt "/init $issue_link"
}
```

Then create `.claude/skills/init/` skill that:
- Parses the issue link
- Spawns research subagents
- Fills CLAUDE.local.md
- Enters plan mode

### Option B: Wrapper Script

```bash
#!/bin/bash
# scripts/start-session.sh
read -p "Issue link (required): " ISSUE_LINK
if [[ -z "$ISSUE_LINK" ]]; then
    echo "Issue link required"
    exit 1
fi

claude -p "Research issue $ISSUE_LINK using subagents (1 for GitHub issue, 1 for codebase, 1 for external resources). Fill out CLAUDE.local.md with findings. Then create implementation plan with clarifying questions for maintainers."
```

### Option C: MCP Server Hook (future)

If Claude Code adds `SessionStart` hook type, register it in `.claude/settings.local.json`.

## Tasks

- [ ] Create `/init` skill in `.claude/skills/init/`
- [ ] Skill should accept issue URL as argument
- [ ] Implement parallel subagent research pattern
- [ ] Auto-populate CLAUDE.local.md template fields
- [ ] Generate plan with maintainer questions
- [ ] Create shell wrapper/alias for easy invocation
- [ ] Document usage in CLAUDE.md

## Open Questions

1. Should the init flow be blocking (wait for all research) or stream results?
2. How to handle PRs vs issues (different research needs)?
3. Should we validate the issue link format before starting?
4. Store session history somewhere for handoff continuity?
